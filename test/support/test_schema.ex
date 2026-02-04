defmodule FlopRest.TestSchema.Pet do
  @moduledoc false
  use Ecto.Schema

  @derive {Flop.Schema, filterable: [:name, :species, :age], sortable: [:name, :age]}

  schema "pets" do
    field(:name, :string)
    field(:species, :string)
    field(:age, :integer)
    # Not filterable - for testing that non-filterable fields become extra params
    field(:internal_code, :string)
  end
end
