defmodule FlopRest.Filters do
  @moduledoc """
  Extracts and transforms REST-style filter params to Flop format and vice versa.
  """

  alias Flop.Filter
  alias FlopRest.Operators
  alias FlopRest.Pagination
  alias FlopRest.Sorting

  @doc """
  Extracts filters from params map.

  Handles:
  - Bare values: `status=published` → `{field: status, op: ==, value: published}`
  - Operators: `amount[gte]=10` → `{field: amount, op: >=, value: 10}`
  - Lists: `status[in][]=draft&status[in][]=published`
  - Multiple ops on same field: `amount[gte]=10&amount[lte]=100` → two filters

  Unknown operators are passed through verbatim for Flop to validate.
  """
  @spec extract(map()) :: [map()]
  def extract(params) do
    reserved = reserved_keys()

    params
    |> Enum.reject(fn {key, _value} -> key in reserved end)
    |> Enum.flat_map(&expand_filter/1)
  end

  defp reserved_keys do
    Pagination.reserved_keys() ++ Sorting.reserved_keys()
  end

  defp expand_filter({field, value}) when is_map(value) do
    Enum.map(value, fn {op, val} ->
      %{"field" => field, "op" => Operators.to_flop(op), "value" => normalize_value(val)}
    end)
  end

  defp expand_filter({field, value}) do
    [%{"field" => field, "op" => "==", "value" => value}]
  end

  defp normalize_value(value) when is_map(value) do
    # Handle nested map with list values (Plug's parsing of []=)
    # e.g., %{"" => ["draft", "published"]} from status[in][]=draft&status[in][]=published
    case Map.values(value) do
      [list] when is_list(list) -> list
      _ -> value
    end
  end

  defp normalize_value(value), do: value

  @doc """
  Converts a list of Flop.Filter structs back to REST-style params.

  Equality filters (`:==`) become bare key-value params.
  Other operators become nested params like `field[operator]`.

  ## Examples

      iex> FlopRest.Filters.to_rest([%Flop.Filter{field: :status, op: :==, value: "active"}])
      [status: "active"]

      iex> FlopRest.Filters.to_rest([%Flop.Filter{field: :amount, op: :>=, value: 100}])
      [{"amount[gte]", 100}]

      iex> FlopRest.Filters.to_rest([])
      []

      iex> FlopRest.Filters.to_rest(nil)
      []

  """
  @spec to_rest([Filter.t()] | nil) :: keyword()
  def to_rest(nil), do: []
  def to_rest([]), do: []

  def to_rest(filters) when is_list(filters) do
    Enum.map(filters, &filter_to_rest/1)
  end

  defp filter_to_rest(%Filter{field: field, op: op, value: value}) do
    field_string = to_string(field)

    case Operators.to_rest(op) do
      nil -> {String.to_atom(field_string), value}
      rest_op -> {"#{field_string}[#{rest_op}]", value}
    end
  end
end
