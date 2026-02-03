defmodule FlopRest.Filters do
  @moduledoc """
  Extracts and transforms REST-style filter params to Flop format.
  """

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
end
