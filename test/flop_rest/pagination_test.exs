defmodule FlopRest.PaginationTest do
  use ExUnit.Case, async: true

  alias FlopRest.Pagination

  doctest Pagination

  describe "transform/1 with no pagination" do
    test "returns empty map for no pagination params" do
      assert %{} = Pagination.transform(%{})
    end
  end

  describe "transform/1 with cursor-based pagination" do
    test "transforms starting_after to after" do
      assert %{"after" => "cursor123"} = Pagination.transform(%{"starting_after" => "cursor123"})
    end

    test "transforms limit with starting_after to first and after" do
      params = %{"limit" => "10", "starting_after" => "abc"}

      result = Pagination.transform(params)

      assert result == %{"first" => 10, "after" => "abc"}
    end

    test "transforms ending_before to before" do
      assert %{"before" => "cursor456"} = Pagination.transform(%{"ending_before" => "cursor456"})
    end

    test "transforms limit with ending_before to last and before" do
      params = %{"limit" => "15", "ending_before" => "xyz"}

      result = Pagination.transform(params)

      assert result == %{"last" => 15, "before" => "xyz"}
    end
  end

  describe "transform/1 with page-based pagination" do
    test "transforms page only" do
      assert %{"page" => 3} = Pagination.transform(%{"page" => "3"})
    end

    test "transforms page_size only" do
      assert %{"page_size" => 25} = Pagination.transform(%{"page_size" => "25"})
    end

    test "transforms page and page_size" do
      params = %{"page" => "2", "page_size" => "25"}

      result = Pagination.transform(params)

      assert result == %{"page" => 2, "page_size" => 25}
    end

    test "handles integer values" do
      params = %{"page" => 2, "page_size" => 25}

      result = Pagination.transform(params)

      assert result == %{"page" => 2, "page_size" => 25}
    end
  end

  describe "transform/1 with offset-based pagination" do
    test "transforms offset only" do
      assert %{"offset" => 50} = Pagination.transform(%{"offset" => "50"})
    end

    test "transforms limit only as offset-based" do
      assert %{"limit" => 20} = Pagination.transform(%{"limit" => "20"})
    end

    test "transforms offset and limit" do
      params = %{"offset" => "50", "limit" => "25"}

      result = Pagination.transform(params)

      assert result == %{"offset" => 50, "limit" => 25}
    end

    test "handles integer values" do
      params = %{"offset" => 50, "limit" => 25}

      result = Pagination.transform(params)

      assert result == %{"offset" => 50, "limit" => 25}
    end
  end

  describe "reserved_keys/0" do
    test "returns all pagination-related keys" do
      keys = Pagination.reserved_keys()
      assert "limit" in keys
      assert "starting_after" in keys
      assert "ending_before" in keys
      assert "page" in keys
      assert "page_size" in keys
      assert "offset" in keys
    end
  end
end
