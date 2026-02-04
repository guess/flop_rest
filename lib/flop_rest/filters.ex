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
    {filters, _extra_params} = extract(params, nil)
    filters
  end

  @doc """
  Extracts filters from params map, optionally filtering by a set of allowed fields.

  When `filterable` is provided, only fields in the set become filters.
  Other params are returned as the second element of the tuple.

  ## Parameters

    * `params` - The params map to extract filters from
    * `filterable` - A MapSet of string field names that are allowed as filters,
      or `nil` to allow all fields

  ## Returns

  A tuple of `{filters, extra_params}` where:
    * `filters` - List of filter maps for filterable fields
    * `extra_params` - Map of params that weren't converted to filters

  ## Examples

      iex> FlopRest.Filters.extract(%{"name" => "Fido", "custom" => "value"}, MapSet.new(["name"]))
      {[%{"field" => "name", "op" => "==", "value" => "Fido"}], %{"custom" => "value"}}

  """
  @spec extract(map(), MapSet.t(String.t()) | nil) :: {[map()], map()}
  def extract(params, filterable) do
    reserved = reserved_keys()

    params
    |> Enum.reject(fn {key, _value} -> key in reserved end)
    |> split_by_filterable(filterable)
  end

  defp split_by_filterable(params, nil) do
    {Enum.flat_map(params, &expand_filter/1), %{}}
  end

  defp split_by_filterable(params, filterable) do
    {filter_params, extra_params} =
      Enum.split_with(params, fn {key, _value} ->
        base_field = extract_base_field(key)
        MapSet.member?(filterable, base_field)
      end)

    {Enum.flat_map(filter_params, &expand_filter/1), Map.new(extra_params)}
  end

  defp extract_base_field(key) do
    # Handle both "field" and "field[op]" formats
    case String.split(key, "[", parts: 2) do
      [base | _] -> base
      _ -> key
    end
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
      %{"status" => "active"}

      iex> FlopRest.Filters.to_rest([%Flop.Filter{field: :amount, op: :>=, value: 100}])
      %{"amount[gte]" => 100}

      iex> FlopRest.Filters.to_rest([])
      %{}

      iex> FlopRest.Filters.to_rest(nil)
      %{}

  """
  @spec to_rest([Filter.t()] | nil) :: map()
  def to_rest(nil), do: %{}
  def to_rest([]), do: %{}

  def to_rest(filters) when is_list(filters) do
    Map.new(filters, &filter_to_rest/1)
  end

  defp filter_to_rest(%Filter{field: field, op: op, value: value}) do
    field_string = to_string(field)

    case Operators.to_rest(op) do
      nil -> {field_string, value}
      rest_op -> {"#{field_string}[#{rest_op}]", value}
    end
  end
end
