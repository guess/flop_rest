defmodule FlopRest.Pagination do
  @moduledoc """
  Transforms REST-style pagination params to Flop format and vice versa.

  Supports three pagination types:

  - **Cursor-based**: `limit`, `starting_after`, `ending_before`
  - **Page-based**: `page`, `page_size`
  - **Offset-based**: `offset`, `limit`

  When only `limit` is provided, it defaults to cursor-based pagination
  (`first`). This ensures Flop returns cursor metadata that can be used
  for subsequent requests with `starting_after`/`ending_before`. To force
  offset-based pagination, include `offset` (e.g., `offset=0`).

  No validation is performed - conflicting params are passed through
  for Flop to validate.
  """

  @cursor_keys ~w(starting_after ending_before)
  @page_keys ~w(page page_size)
  @offset_keys ~w(offset)
  @reserved_keys ~w(limit starting_after ending_before page page_size offset)

  @doc """
  Transforms pagination parameters to Flop format.

  ## Examples

      iex> FlopRest.Pagination.transform(%{"limit" => "20", "starting_after" => "abc"})
      %{"first" => 20, "after" => "abc"}

      iex> FlopRest.Pagination.transform(%{"limit" => "20"})
      %{"first" => 20}

      iex> FlopRest.Pagination.transform(%{"page" => "2", "page_size" => "25"})
      %{"page" => 2, "page_size" => 25}

      iex> FlopRest.Pagination.transform(%{"offset" => "0", "limit" => "25"})
      %{"offset" => 0, "limit" => 25}

  """
  @spec transform(map()) :: map()
  def transform(params) do
    pagination_type = detect_pagination_type(params)
    build_pagination(params, pagination_type)
  end

  @doc """
  Returns the list of reserved pagination keys.
  """
  @spec reserved_keys() :: [String.t()]
  def reserved_keys, do: @reserved_keys

  defp detect_pagination_type(params) do
    has_cursor = has_any_key?(params, @cursor_keys)
    has_page = has_any_key?(params, @page_keys)
    has_offset = has_any_key?(params, @offset_keys)

    cond do
      has_cursor -> :cursor
      has_page -> :page
      has_offset -> :offset
      Map.has_key?(params, "limit") -> :cursor
      true -> :none
    end
  end

  defp has_any_key?(params, keys), do: Enum.any?(keys, &Map.has_key?(params, &1))

  defp build_pagination(_params, :none), do: %{}

  defp build_pagination(params, :cursor) do
    if Map.has_key?(params, "ending_before") do
      build_cursor_backward(params)
    else
      build_cursor_forward(params)
    end
  end

  defp build_pagination(params, :page) do
    %{}
    |> maybe_put("page", params["page"], &parse_int/1)
    |> maybe_put("page_size", params["page_size"], &parse_int/1)
  end

  defp build_pagination(params, :offset) do
    %{}
    |> maybe_put("offset", params["offset"], &parse_int/1)
    |> maybe_put("limit", params["limit"], &parse_int/1)
  end

  defp build_cursor_forward(params) do
    %{}
    |> maybe_put("first", params["limit"], &parse_int/1)
    |> maybe_put("after", params["starting_after"])
  end

  defp build_cursor_backward(params) do
    %{}
    |> maybe_put("last", params["limit"], &parse_int/1)
    |> maybe_put("before", params["ending_before"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put(map, _key, nil, _transform), do: map
  defp maybe_put(map, key, value, transform), do: Map.put(map, key, transform.(value))

  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(value) when is_integer(value), do: value

  @doc """
  Converts a Flop struct's pagination fields back to REST-style params.

  ## Examples

      iex> FlopRest.Pagination.to_rest(%Flop{first: 20, after: "abc"})
      [limit: 20, starting_after: "abc"]

      iex> FlopRest.Pagination.to_rest(%Flop{last: 20, before: "xyz"})
      [limit: 20, ending_before: "xyz"]

      iex> FlopRest.Pagination.to_rest(%Flop{page: 2, page_size: 25})
      [page: 2, page_size: 25]

      iex> FlopRest.Pagination.to_rest(%Flop{offset: 50, limit: 25})
      [offset: 50, limit: 25]

      iex> FlopRest.Pagination.to_rest(%Flop{})
      []

  """
  @spec to_rest(Flop.t()) :: keyword()
  def to_rest(%Flop{} = flop) do
    flop |> detect_rest_pagination_type() |> build_rest_pagination(flop)
  end

  defp detect_rest_pagination_type(%Flop{first: first, after: cursor}) when not is_nil(first) or not is_nil(cursor),
    do: :cursor_forward

  defp detect_rest_pagination_type(%Flop{last: last, before: cursor}) when not is_nil(last) or not is_nil(cursor),
    do: :cursor_backward

  defp detect_rest_pagination_type(%Flop{page: page, page_size: page_size})
       when not is_nil(page) or not is_nil(page_size),
       do: :page

  defp detect_rest_pagination_type(%Flop{offset: offset, limit: limit}) when not is_nil(offset) or not is_nil(limit),
    do: :offset

  defp detect_rest_pagination_type(_flop), do: :none

  defp build_rest_pagination(:cursor_forward, flop) do
    []
    |> maybe_prepend(:starting_after, flop.after)
    |> maybe_prepend(:limit, flop.first)
  end

  defp build_rest_pagination(:cursor_backward, flop) do
    []
    |> maybe_prepend(:ending_before, flop.before)
    |> maybe_prepend(:limit, flop.last)
  end

  defp build_rest_pagination(:page, flop) do
    []
    |> maybe_prepend(:page_size, flop.page_size)
    |> maybe_prepend(:page, flop.page)
  end

  defp build_rest_pagination(:offset, flop) do
    []
    |> maybe_prepend(:limit, flop.limit)
    |> maybe_prepend(:offset, flop.offset)
  end

  defp build_rest_pagination(:none, _flop), do: []

  defp maybe_prepend(list, _key, nil), do: list
  defp maybe_prepend(list, key, value), do: [{key, value} | list]
end
