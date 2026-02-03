defmodule FlopRest do
  @moduledoc """
  Transform Stripe-style REST query params to Flop format.

  FlopRest is a pure transformation layer - no validation is performed.
  Invalid params are passed through for Flop to validate.

  ## Quick Start

      def index(conn, params) do
        flop_params = FlopRest.normalize(params)

        with {:ok, {events, meta}} <- Flop.validate_and_run(Event, flop_params) do
          render(conn, :index, events: events, meta: meta)
        end
      end

  ## Filters

  Bare values become equality filters, operators are nested keys:

      FlopRest.normalize(%{"status" => "published", "amount" => %{"gte" => "100"}})
      # => %{
      #   "filters" => [
      #     %{"field" => "amount", "op" => ">=", "value" => "100"},
      #     %{"field" => "status", "op" => "==", "value" => "published"}
      #   ]
      # }

  ## Sorting

  Use `-` prefix for descending:

      FlopRest.normalize(%{"sort" => "-created_at,name"})
      # => %{"order_by" => ["created_at", "name"], "order_directions" => ["desc", "asc"]}

  ## Pagination

  Supports cursor-based, page-based, and offset-based:

      # Cursor-based
      FlopRest.normalize(%{"limit" => "20", "starting_after" => "abc"})
      # => %{"first" => 20, "after" => "abc"}

      # Page-based
      FlopRest.normalize(%{"page" => "2", "page_size" => "25"})
      # => %{"page" => 2, "page_size" => 25}

      # Offset-based
      FlopRest.normalize(%{"offset" => "50", "limit" => "25"})
      # => %{"offset" => 50, "limit" => 25}

  See the [README](readme.html) for the full operator reference.
  """

  alias FlopRest.Filters
  alias FlopRest.Pagination
  alias FlopRest.Sorting

  @doc """
  Transforms REST-style params to Flop format.

  ## Examples

      iex> FlopRest.normalize(%{"status" => "published"})
      %{"filters" => [%{"field" => "status", "op" => "==", "value" => "published"}]}

      iex> FlopRest.normalize(%{"sort" => "-created_at"})
      %{"order_by" => ["created_at"], "order_directions" => ["desc"]}

      iex> FlopRest.normalize(%{"page" => "2", "page_size" => "10"})
      %{"page" => 2, "page_size" => 10}

      iex> FlopRest.normalize(%{})
      %{}

  """
  @spec normalize(map()) :: map()
  def normalize(params) when is_map(params) do
    filters = Filters.extract(params)
    pagination = Pagination.transform(params)
    sorting = Sorting.parse(Map.get(params, "sort"))

    %{}
    |> maybe_put("filters", filters)
    |> Map.merge(pagination)
    |> Map.merge(sorting)
  end

  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
