defmodule FlopRest.FiltersTest do
  use ExUnit.Case, async: true

  alias Flop.Filter
  alias FlopRest.Filters

  describe "extract/1" do
    test "extracts bare value as equality filter" do
      params = %{"status" => "published"}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "status", "op" => "==", "value" => "published"}
    end

    test "extracts filter with operator" do
      params = %{"amount" => %{"gte" => "100"}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "amount", "op" => ">=", "value" => "100"}
    end

    test "extracts multiple filters on same field" do
      params = %{"amount" => %{"gte" => "10", "lte" => "100"}}

      filters = Filters.extract(params)

      assert length(filters) == 2
      assert %{"field" => "amount", "op" => ">=", "value" => "10"} in filters
      assert %{"field" => "amount", "op" => "<=", "value" => "100"} in filters
    end

    test "extracts filters on multiple fields" do
      params = %{"status" => "active", "priority" => %{"gt" => "5"}}

      filters = Filters.extract(params)

      assert length(filters) == 2
      assert %{"field" => "status", "op" => "==", "value" => "active"} in filters
      assert %{"field" => "priority", "op" => ">", "value" => "5"} in filters
    end

    test "handles list values for in operator" do
      params = %{"status" => %{"in" => ["draft", "published"]}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "status", "op" => "in", "value" => ["draft", "published"]}
    end

    test "handles Plug-style nested map for list values" do
      # Plug parses status[in][]=draft&status[in][]=published as:
      # %{"status" => %{"in" => %{"" => ["draft", "published"]}}}
      params = %{"status" => %{"in" => %{"" => ["draft", "published"]}}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "status", "op" => "in", "value" => ["draft", "published"]}
    end

    test "excludes pagination keys" do
      params = %{
        "status" => "active",
        "limit" => "10",
        "starting_after" => "abc",
        "ending_before" => "xyz",
        "page" => "2",
        "page_size" => "25",
        "offset" => "50"
      }

      assert [filter] = Filters.extract(params)

      assert filter["field"] == "status"
    end

    test "excludes sort key" do
      params = %{"status" => "active", "sort" => "-created_at"}

      assert [filter] = Filters.extract(params)

      assert filter["field"] == "status"
    end

    test "passes through unknown operators verbatim" do
      params = %{"amount" => %{"bad_op" => "100"}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "amount", "op" => "bad_op", "value" => "100"}
    end

    test "extracts empty operator" do
      params = %{"deleted_at" => %{"empty" => "true"}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "deleted_at", "op" => "empty", "value" => "true"}
    end

    test "extracts search operator" do
      params = %{"name" => %{"search" => "john"}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "name", "op" => "=~", "value" => "john"}
    end

    test "extracts ilike operator" do
      params = %{"email" => %{"ilike" => "%@example.com"}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "email", "op" => "ilike", "value" => "%@example.com"}
    end

    test "handles nested map with multiple keys (passthrough)" do
      # Edge case: nested map that doesn't match the Plug [] pattern
      params = %{"meta" => %{"in" => %{"foo" => "bar", "baz" => "qux"}}}

      assert [filter] = Filters.extract(params)

      assert filter == %{"field" => "meta", "op" => "in", "value" => %{"foo" => "bar", "baz" => "qux"}}
    end
  end

  describe "extract/2" do
    test "returns {filters, extra_params} tuple" do
      filterable = MapSet.new(["name"])
      params = %{"name" => "Fido", "custom" => "value"}

      {filters, extra_params} = Filters.extract(params, filterable)

      assert [%{"field" => "name", "op" => "==", "value" => "Fido"}] = filters
      assert %{"custom" => "value"} = extra_params
    end

    test "with nil filterable returns all as filters and empty extra_params" do
      params = %{"name" => "Fido", "age" => "5"}

      {filters, extra_params} = Filters.extract(params, nil)

      assert length(filters) == 2
      assert %{} = extra_params
    end

    test "handles operators on filterable fields" do
      filterable = MapSet.new(["amount"])
      params = %{"amount" => %{"gte" => "100"}, "custom" => "value"}

      {filters, extra_params} = Filters.extract(params, filterable)

      assert [%{"field" => "amount", "op" => ">=", "value" => "100"}] = filters
      assert %{"custom" => "value"} = extra_params
    end

    test "handles multiple operators on same filterable field" do
      filterable = MapSet.new(["amount"])
      params = %{"amount" => %{"gte" => "10", "lte" => "100"}}

      {filters, extra_params} = Filters.extract(params, filterable)

      assert length(filters) == 2
      assert %{"field" => "amount", "op" => ">=", "value" => "10"} in filters
      assert %{"field" => "amount", "op" => "<=", "value" => "100"} in filters
      assert extra_params == %{}
    end

    test "non-filterable fields go to extra_params" do
      filterable = MapSet.new(["name"])
      params = %{"name" => "Fido", "internal_code" => "ABC123", "unknown" => "field"}

      {filters, extra_params} = Filters.extract(params, filterable)

      assert [%{"field" => "name", "op" => "==", "value" => "Fido"}] = filters
      assert extra_params == %{"internal_code" => "ABC123", "unknown" => "field"}
    end

    test "reserved keys excluded from both filters and extra_params" do
      filterable = MapSet.new(["name"])
      params = %{"name" => "Fido", "sort" => "-created_at", "limit" => "10", "page" => "2"}

      {filters, extra_params} = Filters.extract(params, filterable)

      assert [%{"field" => "name", "op" => "==", "value" => "Fido"}] = filters
      assert extra_params == %{}
    end

    test "empty filterable set returns all non-reserved params as extra" do
      filterable = MapSet.new([])
      params = %{"name" => "Fido", "age" => "5"}

      {filters, extra_params} = Filters.extract(params, filterable)

      assert filters == []
      assert extra_params == %{"name" => "Fido", "age" => "5"}
    end
  end

  describe "to_rest/1" do
    test "returns empty map for nil" do
      assert %{} = Filters.to_rest(nil)
    end

    test "returns empty map for empty list" do
      assert %{} = Filters.to_rest([])
    end

    test "converts equality filter to bare param" do
      filters = [%Filter{field: :status, op: :==, value: "active"}]

      result = Filters.to_rest(filters)

      assert result == %{"status" => "active"}
    end

    test "converts operator filter to nested param" do
      filters = [%Filter{field: :amount, op: :>=, value: 100}]

      result = Filters.to_rest(filters)

      assert result == %{"amount[gte]" => 100}
    end

    test "converts multiple filters" do
      filters = [
        %Filter{field: :status, op: :==, value: "active"},
        %Filter{field: :amount, op: :>=, value: 100}
      ]

      result = Filters.to_rest(filters)

      assert result == %{"status" => "active", "amount[gte]" => 100}
    end

    test "converts in operator with list value" do
      filters = [%Filter{field: :status, op: :in, value: ["draft", "published"]}]

      result = Filters.to_rest(filters)

      assert result == %{"status[in]" => ["draft", "published"]}
    end

    test "converts search operator" do
      filters = [%Filter{field: :name, op: :=~, value: "john"}]

      result = Filters.to_rest(filters)

      assert result == %{"name[search]" => "john"}
    end

    test "converts empty operator" do
      filters = [%Filter{field: :deleted_at, op: :empty, value: true}]

      result = Filters.to_rest(filters)

      assert result == %{"deleted_at[empty]" => true}
    end

    test "converts ilike operator" do
      filters = [%Filter{field: :email, op: :ilike, value: "%@example.com"}]

      result = Filters.to_rest(filters)

      assert result == %{"email[ilike]" => "%@example.com"}
    end

    test "handles string field names" do
      filters = [%Filter{field: "status", op: :==, value: "active"}]

      result = Filters.to_rest(filters)

      assert result == %{"status" => "active"}
    end
  end
end
