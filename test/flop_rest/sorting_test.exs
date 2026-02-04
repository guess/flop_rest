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

  describe "to_rest/1" do
    test "returns empty map for nil order_by" do
      assert %{} = Sorting.to_rest(%Flop{order_by: nil})
    end

    test "returns empty map for empty order_by" do
      assert %{} = Sorting.to_rest(%Flop{order_by: []})
    end

    test "converts single ascending field" do
      flop = %Flop{order_by: [:name], order_directions: [:asc]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "name"}
    end

    test "converts single descending field" do
      flop = %Flop{order_by: [:name], order_directions: [:desc]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "-name"}
    end

    test "converts multiple fields with mixed directions" do
      flop = %Flop{order_by: [:name, :age, :created_at], order_directions: [:asc, :desc, :asc]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "name,-age,created_at"}
    end

    test "defaults to ascending when direction is missing" do
      flop = %Flop{order_by: [:name, :age], order_directions: [:desc]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "-name,age"}
    end

    test "defaults to ascending when directions is nil" do
      flop = %Flop{order_by: [:name], order_directions: nil}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "name"}
    end

    test "handles desc_nulls_first as descending" do
      flop = %Flop{order_by: [:name], order_directions: [:desc_nulls_first]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "-name"}
    end

    test "handles desc_nulls_last as descending" do
      flop = %Flop{order_by: [:name], order_directions: [:desc_nulls_last]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "-name"}
    end

    test "handles asc_nulls_first as ascending" do
      flop = %Flop{order_by: [:name], order_directions: [:asc_nulls_first]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "name"}
    end

    test "handles asc_nulls_last as ascending" do
      flop = %Flop{order_by: [:name], order_directions: [:asc_nulls_last]}

      result = Sorting.to_rest(flop)

      assert result == %{"sort" => "name"}
    end
  end
end
