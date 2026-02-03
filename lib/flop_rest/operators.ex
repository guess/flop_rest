defmodule FlopRest.Operators do
  @moduledoc """
  Maps REST-style operator strings to Flop operator strings.
  """

  @operator_map %{
    "eq" => "==",
    "ne" => "!=",
    "search" => "=~",
    "lt" => "<",
    "lte" => "<=",
    "gt" => ">",
    "gte" => ">=",
    "empty" => "empty",
    "not_empty" => "not_empty",
    "in" => "in",
    "not_in" => "not_in",
    "contains" => "contains",
    "not_contains" => "not_contains",
    "like" => "like",
    "not_like" => "not_like",
    "like_and" => "like_and",
    "like_or" => "like_or",
    "ilike" => "ilike",
    "not_ilike" => "not_ilike",
    "ilike_and" => "ilike_and",
    "ilike_or" => "ilike_or"
  }

  @doc """
  Converts a REST operator string to the corresponding Flop operator.

  Known operators are mapped (e.g., "gte" → ">=").
  Unknown operators are passed through verbatim for Flop to validate.

  ## Examples

      iex> FlopRest.Operators.to_flop("gte")
      ">="

      iex> FlopRest.Operators.to_flop("unknown")
      "unknown"

  """
  @spec to_flop(String.t()) :: String.t()
  def to_flop(operator) do
    Map.get(@operator_map, operator, operator)
  end
end
