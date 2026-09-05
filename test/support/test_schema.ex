defmodule FlopRest.TestSchema.Pet do
  @moduledoc false
  use Ecto.Schema

  # Flop 0.29 turned `Flop.Schema` from a protocol into a behaviour, so `@derive` raises
  # there and `use Flop.Schema` does not exist before it. Declaring both keeps this schema
  # compilable against either Flop, which is what lets the suite prove FlopRest works on
  # both sides of that change.
  if Code.ensure_loaded?(Flop) and function_exported?(Flop, :allowed_fields, 2) do
    use Flop.Schema

    @flop_options filterable: [:name, :species, :age], sortable: [:name, :age]
  else
    @derive {Flop.Schema, filterable: [:name, :species, :age], sortable: [:name, :age]}
  end

  schema "pets" do
    field(:name, :string)
    field(:species, :string)
    field(:age, :integer)
    # Not filterable - for testing that non-filterable fields become extra params
    field(:internal_code, :string)
  end
end
