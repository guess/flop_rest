defmodule FlopRestTest do
  use ExUnit.Case, async: true

  alias Flop.Filter

  doctest FlopRest

  describe "normalize/1" do
    test "transforms complete example from spec" do
      params = %{
        "status" => "published",
        "starts_at" => %{"gte" => "2024-01-01"},
        "sort" => "-starts_at",
        "limit" => "20",
        "after" => "abc123"
      }

      result = FlopRest.normalize(params)

      assert %{"field" => "status", "op" => "==", "value" => "published"} in result["filters"]
      assert %{"field" => "starts_at", "op" => ">=", "value" => "2024-01-01"} in result["filters"]
      assert length(result["filters"]) == 2

      assert result["order_by"] == ["starts_at"]
      assert result["order_directions"] == ["desc"]
      assert result["first"] == 20
      assert result["after"] == "abc123"
    end

    test "handles empty params" do
      assert %{} = FlopRest.normalize(%{})
    end

    test "handles only filters" do
      params = %{"status" => "active", "amount" => %{"gte" => "100"}}

      result = FlopRest.normalize(params)

      assert %{"field" => "amount", "op" => ">=", "value" => "100"} in result["filters"]
      assert %{"field" => "status", "op" => "==", "value" => "active"} in result["filters"]
      assert length(result["filters"]) == 2

      refute Map.has_key?(result, "order_by")
      refute Map.has_key?(result, "first")
    end

    test "handles cursor-based pagination" do
      params = %{"limit" => "10", "after" => "cursor123"}

      result = FlopRest.normalize(params)

      assert result["first"] == 10
      assert result["after"] == "cursor123"
      refute Map.has_key?(result, "filters")
    end

    test "handles page-based pagination" do
      params = %{"page" => "2", "page_size" => "25"}

      result = FlopRest.normalize(params)

      assert result["page"] == 2
      assert result["page_size"] == 25
      refute Map.has_key?(result, "filters")
    end

    test "handles offset-based pagination" do
      params = %{"offset" => "50", "limit" => "25"}

      result = FlopRest.normalize(params)

      assert result["offset"] == 50
      assert result["limit"] == 25
      refute Map.has_key?(result, "filters")
    end

    test "handles only sorting" do
      params = %{"sort" => "-created_at,name"}

      result = FlopRest.normalize(params)

      assert result["order_by"] == ["created_at", "name"]
      assert result["order_directions"] == ["desc", "asc"]
      refute Map.has_key?(result, "filters")
    end

    test "passes through unknown operators for Flop to validate" do
      params = %{"amount" => %{"unknown_op" => "100"}}

      result = FlopRest.normalize(params)

      assert [%{"field" => "amount", "op" => "unknown_op", "value" => "100"}] = result["filters"]
    end
  end

  describe "normalize/2 with :for option" do
    alias FlopRest.TestSchema.Pet

    test "only filterable fields become filters" do
      params = %{"name" => "Fido", "species" => "dog", "internal_code" => "ABC123"}

      result = FlopRest.normalize(params, for: Pet)

      # name and species are filterable
      assert length(result["filters"]) == 2
      assert %{"field" => "name", "op" => "==", "value" => "Fido"} in result["filters"]
      assert %{"field" => "species", "op" => "==", "value" => "dog"} in result["filters"]
    end

    test "non-filterable fields are kept in result at root level" do
      params = %{"name" => "Fido", "internal_code" => "ABC123", "custom_field" => "value"}

      result = FlopRest.normalize(params, for: Pet)

      assert [%{"field" => "name", "op" => "==", "value" => "Fido"}] = result["filters"]
      assert result["internal_code"] == "ABC123"
      assert result["custom_field"] == "value"
    end

    test "operators work on filterable fields" do
      params = %{"age" => %{"gte" => "5", "lte" => "10"}, "internal_code" => "ABC123"}

      result = FlopRest.normalize(params, for: Pet)

      assert length(result["filters"]) == 2
      assert %{"field" => "age", "op" => ">=", "value" => "5"} in result["filters"]
      assert %{"field" => "age", "op" => "<=", "value" => "10"} in result["filters"]
      assert result["internal_code"] == "ABC123"
    end

    test "pagination unaffected by schema" do
      params = %{"name" => "Fido", "page" => "2", "page_size" => "25"}

      result = FlopRest.normalize(params, for: Pet)

      assert result["page"] == 2
      assert result["page_size"] == 25
      assert [%{"field" => "name"}] = result["filters"]
    end

    test "sorting unaffected by schema" do
      params = %{"name" => "Fido", "sort" => "-name,age"}

      result = FlopRest.normalize(params, for: Pet)

      assert result["order_by"] == ["name", "age"]
      assert result["order_directions"] == ["desc", "asc"]
      assert [%{"field" => "name"}] = result["filters"]
    end

    test "for: nil behaves same as normalize/1" do
      params = %{"name" => "Fido", "custom" => "value"}

      result_with_nil = FlopRest.normalize(params, for: nil)
      result_without = FlopRest.normalize(params)

      # With nil schema, all params become filters, no extra params
      assert result_with_nil == result_without
      assert length(result_with_nil["filters"]) == 2
      refute Map.has_key?(result_with_nil, "custom")
    end

    test "extra params don't conflict with Flop keys" do
      params = %{
        "name" => "Fido",
        "internal_code" => "ABC123",
        "sort" => "-name",
        "page" => "1"
      }

      result = FlopRest.normalize(params, for: Pet)

      # Flop keys from transforms
      assert result["order_by"] == ["name"]
      assert result["page"] == 1
      assert [%{"field" => "name"}] = result["filters"]

      # Extra param
      assert result["internal_code"] == "ABC123"
    end

    test "empty params with schema returns empty map" do
      result = FlopRest.normalize(%{}, for: Pet)

      assert result == %{}
    end

    test "all non-filterable params returns only extra params" do
      params = %{"internal_code" => "ABC123", "unknown" => "field"}

      result = FlopRest.normalize(params, for: Pet)

      refute Map.has_key?(result, "filters")
      assert result["internal_code"] == "ABC123"
      assert result["unknown"] == "field"
    end
  end

  describe "to_query/1" do
    test "returns empty map for empty flop" do
      assert %{} = FlopRest.to_query(%Flop{})
    end

    test "converts full flop with filters, sorting, and pagination" do
      flop = %Flop{
        filters: [
          %Filter{field: :status, op: :==, value: "active"},
          %Filter{field: :amount, op: :>=, value: 100}
        ],
        order_by: [:created_at],
        order_directions: [:desc],
        first: 20,
        after: "abc123"
      }

      result = FlopRest.to_query(flop)

      assert result == %{
               "status" => "active",
               "amount[gte]" => 100,
               "sort" => "-created_at",
               "limit" => 20,
               "after" => "abc123"
             }
    end

    test "converts flop with only filters" do
      flop = %Flop{filters: [%Filter{field: :status, op: :==, value: "active"}]}

      result = FlopRest.to_query(flop)

      assert result == %{"status" => "active"}
    end

    test "converts flop with only sorting" do
      flop = %Flop{order_by: [:name], order_directions: [:asc]}

      result = FlopRest.to_query(flop)

      assert result == %{"sort" => "name"}
    end

    test "converts flop with only pagination" do
      flop = %Flop{page: 2, page_size: 25}

      result = FlopRest.to_query(flop)

      assert result == %{"page" => 2, "page_size" => 25}
    end

    test "accepts Flop.Meta struct" do
      flop = %Flop{page: 2, page_size: 25}
      meta = %Flop.Meta{flop: flop}

      result = FlopRest.to_query(meta)

      assert result == %{"page" => 2, "page_size" => 25}
    end
  end

  describe "to_query/2" do
    test "accepts options" do
      flop = %Flop{page: 2, page_size: 25}

      result = FlopRest.to_query(flop, [])

      assert result == %{"page" => 2, "page_size" => 25}
    end
  end

  describe "build_path/2" do
    test "returns path only for empty flop" do
      assert "/events" = FlopRest.build_path("/events", %Flop{})
    end

    test "builds path with page-based pagination" do
      flop = %Flop{page: 2, page_size: 25}

      result = FlopRest.build_path("/events", flop)

      assert result == "/events?page=2&page_size=25"
    end

    test "builds path with cursor-based pagination" do
      flop = %Flop{first: 20, after: "abc123"}

      result = FlopRest.build_path("/events", flop)

      assert result == "/events?after=abc123&limit=20"
    end

    test "builds path with sorting" do
      flop = %Flop{order_by: [:created_at], order_directions: [:desc]}

      result = FlopRest.build_path("/events", flop)

      assert result == "/events?sort=-created_at"
    end

    test "builds path with filters" do
      flop = %Flop{filters: [%Filter{field: :status, op: :==, value: "active"}]}

      result = FlopRest.build_path("/events", flop)

      assert result == "/events?status=active"
    end

    test "builds path with operator filter (URL encoded)" do
      flop = %Flop{filters: [%Filter{field: :amount, op: :>=, value: 100}]}

      result = FlopRest.build_path("/events", flop)

      # amount[gte] gets URL encoded
      assert result == "/events?amount%5Bgte%5D=100"
    end

    test "accepts Flop.Meta struct" do
      flop = %Flop{page: 2, page_size: 25}
      meta = %Flop.Meta{flop: flop}

      result = FlopRest.build_path("/events", meta)

      assert result == "/events?page=2&page_size=25"
    end
  end

  describe "build_path/3" do
    test "accepts options" do
      flop = %Flop{page: 2, page_size: 25}

      result = FlopRest.build_path("/events", flop, [])

      assert result == "/events?page=2&page_size=25"
    end
  end

  describe "build_path with existing query params" do
    test "merges with existing query params" do
      flop = %Flop{page: 2, page_size: 25}

      result = FlopRest.build_path("/events?species=dog", flop)

      # Parse and verify all params are present
      %URI{path: path, query: query} = URI.parse(result)
      params = URI.decode_query(query)

      assert path == "/events"
      assert params["species"] == "dog"
      assert params["page"] == "2"
      assert params["page_size"] == "25"
    end

    test "flop params take precedence over existing params" do
      flop = %Flop{page: 3, page_size: 25}

      result = FlopRest.build_path("/events?page=1&species=dog", flop)

      %URI{query: query} = URI.parse(result)
      params = URI.decode_query(query)

      assert params["page"] == "3"
      assert params["species"] == "dog"
    end

    test "preserves path when merging" do
      flop = %Flop{page: 2, page_size: 25}

      result = FlopRest.build_path("/api/v1/events?species=dog", flop)

      %URI{path: path} = URI.parse(result)
      assert path == "/api/v1/events"
    end

    test "handles empty flop with existing params" do
      flop = %Flop{}

      result = FlopRest.build_path("/events?species=dog", flop)

      assert result == "/events?species=dog"
    end
  end
end
