defmodule FlopRest.SortingTest do
  use ExUnit.Case, async: true

  alias FlopRest.Sorting

  doctest Sorting

  describe "parse/1" do
    test "returns empty map for nil" do
      assert %{} = Sorting.parse(nil)
    end

    test "returns empty map for empty string" do
      assert %{} = Sorting.parse("")
    end

    test "parses single ascending field (default)" do
      result = Sorting.parse("name")
      assert result["order_by"] == ["name"]
      assert result["order_directions"] == ["asc"]
    end

    test "parses single descending field with minus prefix" do
      result = Sorting.parse("-created_at")
      assert result["order_by"] == ["created_at"]
      assert result["order_directions"] == ["desc"]
    end

    test "parses single ascending field with plus prefix" do
      result = Sorting.parse("+name")
      assert result["order_by"] == ["name"]
      assert result["order_directions"] == ["asc"]
    end

    test "parses multiple fields" do
      result = Sorting.parse("-starts_at,name")
      assert result["order_by"] == ["starts_at", "name"]
      assert result["order_directions"] == ["desc", "asc"]
    end

    test "parses multiple fields with mixed directions" do
      result = Sorting.parse("-created_at,+priority,-name")
      assert result["order_by"] == ["created_at", "priority", "name"]
      assert result["order_directions"] == ["desc", "asc", "desc"]
    end

    test "handles whitespace around fields" do
      result = Sorting.parse(" -name , created_at ")
      assert result["order_by"] == ["name", "created_at"]
      assert result["order_directions"] == ["desc", "asc"]
    end

    test "ignores empty fields from consecutive commas" do
      result = Sorting.parse("name,,created_at")
      assert result["order_by"] == ["name", "created_at"]
      assert result["order_directions"] == ["asc", "asc"]
    end
  end

  describe "reserved_keys/0" do
    test "returns sort key" do
      assert "sort" in Sorting.reserved_keys()
    end
  end
end
