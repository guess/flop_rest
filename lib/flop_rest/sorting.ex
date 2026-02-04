defmodule FlopRest.Sorting do
  @moduledoc """
  Parses REST-style sort strings into Flop format and vice versa.
  """

  @reserved_keys ~w(sort)

  @doc """
  Parses a sort string like "-field,other_field" into Flop format.

  ## Examples

      iex> FlopRest.Sorting.parse("-starts_at,name")
      %{"order_by" => ["starts_at", "name"], "order_directions" => ["desc", "asc"]}

      iex> FlopRest.Sorting.parse(nil)
      %{}

  """
  @spec parse(String.t() | nil) :: map()
  def parse(nil), do: %{}
  def parse(""), do: %{}

  def parse(sort_string) when is_binary(sort_string) do
    {fields, directions} =
      sort_string
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&parse_field/1)
      |> Enum.unzip()

    %{"order_by" => fields, "order_directions" => directions}
  end

  @doc """
  Returns the list of reserved sorting keys.
  """
  @spec reserved_keys() :: [String.t()]
  def reserved_keys, do: @reserved_keys

  defp parse_field("-" <> field), do: {field, "desc"}
  defp parse_field("+" <> field), do: {field, "asc"}
  defp parse_field(field), do: {field, "asc"}

  @doc """
  Converts a Flop struct's sorting fields back to REST-style sort string.

  ## Examples

      iex> FlopRest.Sorting.to_rest(%Flop{order_by: [:name], order_directions: [:asc]})
      %{"sort" => "name"}

      iex> FlopRest.Sorting.to_rest(%Flop{order_by: [:name], order_directions: [:desc]})
      %{"sort" => "-name"}

      iex> FlopRest.Sorting.to_rest(%Flop{order_by: [:name, :age], order_directions: [:asc, :desc]})
      %{"sort" => "name,-age"}

      iex> FlopRest.Sorting.to_rest(%Flop{})
      %{}

  """
  @spec to_rest(Flop.t()) :: map()
  def to_rest(%Flop{order_by: nil}), do: %{}
  def to_rest(%Flop{order_by: []}), do: %{}

  def to_rest(%Flop{order_by: fields, order_directions: directions}) do
    directions = directions || []

    sort_string =
      fields
      |> Enum.with_index()
      |> Enum.map_join(",", fn {field, index} ->
        direction = Enum.at(directions, index, :asc)
        format_field(field, direction)
      end)

    %{"sort" => sort_string}
  end

  defp format_field(field, :desc), do: "-#{field}"
  defp format_field(field, :desc_nulls_first), do: "-#{field}"
  defp format_field(field, :desc_nulls_last), do: "-#{field}"
  defp format_field(field, _asc), do: "#{field}"
end
