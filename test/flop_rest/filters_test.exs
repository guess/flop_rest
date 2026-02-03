defmodule FlopRest.FiltersTest do
  use ExUnit.Case, async: true

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
  end
end
