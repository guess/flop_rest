defmodule FlopRest.Operators do
  @moduledoc """
  Maps REST-style operator strings to Flop operator strings.

  ## Operator Reference

  | Operator       | Example                          | SQL                                                  |
  | -------------- | -------------------------------- | ---------------------------------------------------- |
  | _(none)_       | `status=active`                  | `status = 'active'`                                  |
  | `eq`           | `status[eq]=active`              | `status = 'active'`                                  |
  | `ne`           | `status[ne]=archived`            | `status != 'archived'`                               |
  | `gt`           | `age[gt]=18`                     | `age > 18`                                           |
  | `gte`          | `age[gte]=18`                    | `age >= 18`                                          |
  | `lt`           | `price[lt]=100`                  | `price < 100`                                        |
  | `lte`          | `price[lte]=100`                 | `price <= 100`                                       |
  | `in`           | `status[in]=draft,published`     | `status IN ('draft', 'published')`                   |
  | `not_in`       | `status[not_in]=draft,archived`  | `status NOT IN ('draft', 'archived')`                |
  | `contains`     | `tags[contains]=elixir`          | `'elixir' = ANY(tags)`                               |
  | `not_contains` | `tags[not_contains]=go`          | `'go' != ALL(tags)`                                  |
  | `like`         | `name[like]=%john%`              | `name LIKE '%john%'`                                 |
  | `not_like`     | `name[not_like]=%test%`          | `name NOT LIKE '%test%'`                             |
  | `like_and`     | `name[like_and]=Rubi,Rosa`       | `name LIKE '%Rubi%' AND name LIKE '%Rosa%'`          |
  | `like_or`      | `name[like_or]=Rubi,Rosa`        | `name LIKE '%Rubi%' OR name LIKE '%Rosa%'`           |
  | `ilike`        | `name[ilike]=%john%`             | `name ILIKE '%john%'`                                |
  | `not_ilike`    | `name[not_ilike]=%test%`         | `name NOT ILIKE '%test%'`                            |
  | `ilike_and`    | `name[ilike_and]=Rubi,Rosa`      | `name ILIKE '%Rubi%' AND name ILIKE '%Rosa%'`        |
  | `ilike_or`     | `name[ilike_or]=Rubi,Rosa`       | `name ILIKE '%Rubi%' OR name ILIKE '%Rosa%'`         |
  | `empty`        | `deleted_at[empty]=true`         | `deleted_at IS NULL`                                 |
  | `not_empty`    | `deleted_at[not_empty]=true`     | `deleted_at IS NOT NULL`                             |
  | `search`       | `q[search]=john`                 | Configurable in Flop (ILIKE by default)              |

  Unknown operators are passed through for Flop to validate.

  ## List Operators

  The operators `in`, `not_in`, `like_and`, `like_or`, `ilike_and`, and `ilike_or`
  automatically split comma-separated string values into lists. A single value
  (no commas) is passed through as a string, allowing Flop to apply its own
  parsing (e.g. whitespace splitting for `like_and`).

  Use the bracket `[]` syntax if values themselves contain commas:

      status[in][]=draft&status[in][]=has,comma
  """

  @list_operators MapSet.new([
                    "in",
                    "not_in",
                    "like_and",
                    "like_or",
                    "ilike_and",
                    "ilike_or"
                  ])

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

  @flop_to_rest %{
    :== => nil,
    :!= => "ne",
    :=~ => "search",
    :< => "lt",
    :<= => "lte",
    :> => "gt",
    :>= => "gte",
    :empty => "empty",
    :not_empty => "not_empty",
    :in => "in",
    :not_in => "not_in",
    :contains => "contains",
    :not_contains => "not_contains",
    :like => "like",
    :not_like => "not_like",
    :like_and => "like_and",
    :like_or => "like_or",
    :ilike => "ilike",
    :not_ilike => "not_ilike",
    :ilike_and => "ilike_and",
    :ilike_or => "ilike_or"
  }

  @doc """
  Returns whether the given REST operator expects a list value.

  List operators will have comma-separated string values automatically
  split into lists during filter extraction.

  ## Examples

      iex> FlopRest.Operators.list_operator?("in")
      true

      iex> FlopRest.Operators.list_operator?("gte")
      false

  """
  @spec list_operator?(String.t()) :: boolean()
  def list_operator?(op), do: MapSet.member?(@list_operators, op)

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

  @doc """
  Converts a Flop operator atom to the corresponding REST operator string.

  Returns `nil` for equality operator (`:==`) since equality filters use
  bare values without an operator suffix in REST style.

  Unknown operators are passed through as strings.

  ## Examples

      iex> FlopRest.Operators.to_rest(:>=)
      "gte"

      iex> FlopRest.Operators.to_rest(:==)
      nil

      iex> FlopRest.Operators.to_rest(:unknown)
      "unknown"

  """
  @spec to_rest(atom()) :: String.t() | nil
  def to_rest(flop_op) when is_atom(flop_op) do
    case Map.fetch(@flop_to_rest, flop_op) do
      {:ok, rest_op} -> rest_op
      :error -> Atom.to_string(flop_op)
    end
  end
end
