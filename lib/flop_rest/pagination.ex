defmodule FlopRest.Pagination do
  @moduledoc """
  Transforms REST-style pagination params to Flop format.

  Supports three pagination types:

  - **Cursor-based**: `limit`, `starting_after`, `ending_before`
  - **Page-based**: `page`, `page_size`
  - **Offset-based**: `offset`, `limit`

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

      iex> FlopRest.Pagination.transform(%{"page" => "2", "page_size" => "25"})
      %{"page" => 2, "page_size" => 25}

      iex> FlopRest.Pagination.transform(%{"offset" => "50", "limit" => "25"})
      %{"offset" => 50, "limit" => 25}

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
      Map.has_key?(params, "limit") -> :offset
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
end
