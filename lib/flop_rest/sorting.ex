defmodule FlopRest.Sorting do
  @moduledoc """
  Parses REST-style sort strings into Flop format.
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
end
