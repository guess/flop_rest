defmodule FlopRest do
  @moduledoc """
  Bidirectional transformation between Stripe-style REST query params and Flop format.

  FlopRest is a pure transformation layer - no validation is performed.
  Invalid params are passed through for Flop to validate.

  ## Quick Start

      def index(conn, params) do
        flop_params = FlopRest.normalize(params)

        with {:ok, {events, meta}} <- Flop.validate_and_run(Event, flop_params, for: Event) do
          json(conn, %{
            data: EventJSON.index(events),
            links: %{
              self: FlopRest.build_path(conn.request_path, meta),
              next: if(meta.has_next_page?, do: FlopRest.build_path(conn.request_path, meta.next_flop)),
              prev: if(meta.has_previous_page?, do: FlopRest.build_path(conn.request_path, meta.previous_flop))
            }
          })
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
  alias Plug.Conn.Query

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

  @doc """
  Converts a Flop struct or Meta struct back to REST-style query params.

  Accepts either a `Flop.t()` struct or a `Flop.Meta.t()` struct (extracts the flop from it).

  ## Examples

      iex> FlopRest.to_query(%Flop{first: 20, after: "abc", order_by: [:name], order_directions: [:desc]})
      [sort: "-name", limit: 20, starting_after: "abc"]

      iex> FlopRest.to_query(%Flop{page: 2, page_size: 25})
      [page: 2, page_size: 25]

      iex> FlopRest.to_query(%Flop{filters: [%Flop.Filter{field: :status, op: :==, value: "active"}]})
      [status: "active"]

      iex> FlopRest.to_query(%Flop{})
      []

  """
  @spec to_query(Flop.t() | Flop.Meta.t()) :: keyword()
  def to_query(flop_or_meta), do: to_query(flop_or_meta, [])

  @doc """
  Converts a Flop struct or Meta struct back to REST-style query params with options.

  ## Options

    * `:for` - Schema module for looking up default values via `Flop.get_option/3`.
      Values matching defaults will be omitted from the output.
    * `:backend` - Backend module for looking up default values.

  ## Examples

      iex> FlopRest.to_query(%Flop{page: 2, page_size: 25}, [])
      [page: 2, page_size: 25]

  """
  @spec to_query(Flop.t() | Flop.Meta.t(), keyword()) :: keyword()
  def to_query(%Flop.Meta{flop: flop}, opts), do: to_query(flop, opts)

  def to_query(%Flop{} = flop, _opts) do
    filters = Filters.to_rest(flop.filters)
    sorting = Sorting.to_rest(flop)
    pagination = Pagination.to_rest(flop)

    filters ++ sorting ++ pagination
  end

  @doc """
  Builds a URL path with REST-style query params from a Flop struct.

  Existing query parameters in the path are preserved and merged with Flop params.
  Flop params take precedence over existing params with the same key.

  ## Examples

      iex> FlopRest.build_path("/events", %Flop{page: 2, page_size: 25})
      "/events?page=2&page_size=25"

      iex> FlopRest.build_path("/events", %Flop{first: 20, after: "abc"})
      "/events?limit=20&starting_after=abc"

      iex> FlopRest.build_path("/events?species=dog", %Flop{page: 2, page_size: 25})
      "/events?page=2&page_size=25&species=dog"

      iex> FlopRest.build_path("/events?page=1", %Flop{page: 3})
      "/events?page=3"

      iex> FlopRest.build_path("/events", %Flop{})
      "/events"

  """
  @spec build_path(String.t(), Flop.t() | Flop.Meta.t()) :: String.t()
  def build_path(path, flop_or_meta), do: build_path(path, flop_or_meta, [])

  @doc """
  Builds a URL path with REST-style query params from a Flop struct with options.

  Existing query parameters in the path are preserved and merged with Flop params.
  Flop params take precedence over existing params with the same key.

  ## Options

    * `:for` - Schema module for looking up default values via `Flop.get_option/3`.
      Values matching defaults will be omitted from the output.
    * `:backend` - Backend module for looking up default values.

  ## Examples

      iex> FlopRest.build_path("/events", %Flop{page: 2, page_size: 25}, [])
      "/events?page=2&page_size=25"

      iex> FlopRest.build_path("/events", %Flop{filters: [%Flop.Filter{field: :status, op: :>=, value: 100}]}, [])
      "/events?status%5Bgte%5D=100"

      iex> FlopRest.build_path("/events?category=music", %Flop{page: 2, page_size: 10}, [])
      "/events?category=music&page=2&page_size=10"

  """
  @spec build_path(String.t(), Flop.t() | Flop.Meta.t(), keyword()) :: String.t()
  def build_path(path, flop_or_meta, opts) do
    %URI{path: uri_path, query: existing_query} = URI.parse(path)
    flop_query = to_query(flop_or_meta, opts)

    merged_query =
      (existing_query || "")
      |> Query.decode()
      |> Map.merge(Map.new(flop_query, fn {k, v} -> {to_string(k), v} end))

    case merged_query do
      empty when empty == %{} -> uri_path
      query -> "#{uri_path}?#{Query.encode(query)}"
    end
  end
end
