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
    test "transforms limit only to first (enables cursor metadata)" do
      assert %{"first" => 20} = Pagination.transform(%{"limit" => "20"})
    end

    test "transforms after to after" do
      assert %{"after" => "cursor123"} = Pagination.transform(%{"after" => "cursor123"})
    end

    test "transforms limit with after to first and after" do
      params = %{"limit" => "10", "after" => "abc"}

      result = Pagination.transform(params)

      assert result == %{"first" => 10, "after" => "abc"}
    end

    test "transforms before to before" do
      assert %{"before" => "cursor456"} = Pagination.transform(%{"before" => "cursor456"})
    end

    test "transforms limit with before to last and before" do
      params = %{"limit" => "15", "before" => "xyz"}

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
      assert "after" in keys
      assert "before" in keys
      assert "page" in keys
      assert "page_size" in keys
      assert "offset" in keys
    end
  end

  describe "to_rest/1" do
    test "returns empty map for empty flop" do
      assert %{} = Pagination.to_rest(%Flop{})
    end

    test "converts cursor forward pagination" do
      flop = %Flop{first: 20, after: "abc"}

      result = Pagination.to_rest(flop)

      assert result == %{"limit" => 20, "after" => "abc"}
    end

    test "converts cursor forward with only first" do
      flop = %Flop{first: 20}

      result = Pagination.to_rest(flop)

      assert result == %{"limit" => 20}
    end

    test "converts cursor forward with only after" do
      flop = %Flop{after: "abc"}

      result = Pagination.to_rest(flop)

      assert result == %{"after" => "abc"}
    end

    test "converts cursor backward pagination" do
      flop = %Flop{last: 20, before: "xyz"}

      result = Pagination.to_rest(flop)

      assert result == %{"limit" => 20, "before" => "xyz"}
    end

    test "converts cursor backward with only last" do
      flop = %Flop{last: 20}

      result = Pagination.to_rest(flop)

      assert result == %{"limit" => 20}
    end

    test "converts cursor backward with only before" do
      flop = %Flop{before: "xyz"}

      result = Pagination.to_rest(flop)

      assert result == %{"before" => "xyz"}
    end

    test "converts page-based pagination" do
      flop = %Flop{page: 2, page_size: 25}

      result = Pagination.to_rest(flop)

      assert result == %{"page" => 2, "page_size" => 25}
    end

    test "converts page-based with only page" do
      flop = %Flop{page: 3}

      result = Pagination.to_rest(flop)

      assert result == %{"page" => 3}
    end

    test "converts page-based with only page_size" do
      flop = %Flop{page_size: 25}

      result = Pagination.to_rest(flop)

      assert result == %{"page_size" => 25}
    end

    test "converts offset-based pagination" do
      flop = %Flop{offset: 50, limit: 25}

      result = Pagination.to_rest(flop)

      assert result == %{"offset" => 50, "limit" => 25}
    end

    test "converts offset-based with only offset" do
      flop = %Flop{offset: 50}

      result = Pagination.to_rest(flop)

      assert result == %{"offset" => 50}
    end

    test "converts offset-based with only limit" do
      flop = %Flop{limit: 25}

      result = Pagination.to_rest(flop)

      assert result == %{"limit" => 25}
    end
  end
end
