defmodule FlopRestTest do
  use ExUnit.Case, async: true

  doctest FlopRest

  describe "normalize/1" do
    test "transforms complete example from spec" do
      params = %{
        "status" => "published",
        "starts_at" => %{"gte" => "2024-01-01"},
        "sort" => "-starts_at",
        "limit" => "20",
        "starting_after" => "abc123"
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
      params = %{"limit" => "10", "starting_after" => "cursor123"}

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
end
