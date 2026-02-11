# 🔄 FlopRest

REST-friendly query parameters for [Flop](https://github.com/woylie/flop).

- **🎯 Stripe-Style Parameters**: Intuitive `field[operator]=value` syntax that API consumers expect
- **🔀 All Pagination Types**: Cursor-based, page-based, and offset-based pagination
- **🔗 Pagination Links**: Generate `next`/`prev` URLs from Flop metadata with `build_path/2`
- **⚡ Frontend-Ready**: Works naturally with URLSearchParams, axios, TanStack Query, and more

[![Hex.pm](https://img.shields.io/hexpm/v/flop_rest.svg)](https://hex.pm/packages/flop_rest)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/flop_rest)
[![CI](https://github.com/guess/flop_rest/actions/workflows/ci.yml/badge.svg)](https://github.com/guess/flop_rest/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/guess/flop_rest/blob/main/LICENSE)

<div align="center">
    <img src="https://github.com/guess/flop_rest/raw/main/docs/flop_rest.png" alt="FlopRest" width="250">
</div>

## The Problem

Flop is excellent for filtering, sorting, and paginating Ecto queries. But its query parameter format isn't ideal for API consumers:

```
GET /events
  ?filters[0][field]=status
  &filters[0][op]=in
  &filters[0][value][]=published
  &filters[0][value][]=draft
  &filters[1][field]=starts_at
  &filters[1][op]=>=
  &filters[1][value]=2024-01-01
  &order_by[0]=starts_at
  &order_directions[0]=desc
  &first=20
```

This is verbose, error-prone, and unfamiliar to developers used to modern REST APIs.

## The Solution

FlopRest transforms intuitive, Stripe-style query parameters into Flop format:

```
GET /events?status[in]=published,draft&starts_at[gte]=2024-01-01&sort=-starts_at&limit=20
```

Same query. Same Flop power underneath. Better developer experience on top.

## When to Use FlopRest

**Building a Phoenix HTML/LiveView app?** Use [Flop Phoenix](https://hexdocs.pm/flop_phoenix) — it provides UI components for pagination, tables, and filters.

**Building a JSON API?** Use FlopRest — it transforms REST-style query parameters that frontend developers expect.

## Frontend Integration

Standard JavaScript works out of the box:

```javascript
// No special serialization needed
const params = new URLSearchParams({
  status: "published",
  "created_at[gte]": "2024-01-01",
  sort: "-created_at",
  limit: "20",
});

fetch(`/api/events?${params}`);
```

Works naturally with TanStack Query, SWR, RTK Query, axios, or any HTTP client.

## Installation

Add `flop_rest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flop_rest, "~> 0.4"},
    {:flop, "~> 0.26"}
  ]
end
```

## Usage

Transform incoming REST parameters to Flop format:

```elixir
def index(conn, params) do
  flop_params = FlopRest.normalize(params)

  with {:ok, {events, meta}} <- Flop.validate_and_run(Event, flop_params, for: Event) do
    json(conn, %{data: events})
  end
end
```

### Schema-Aware Filtering

Pass the `:for` option to restrict filters to your schema's `filterable` fields. Non-filterable params are kept in the result at the root level for your own handling:

```elixir
# Given a schema with filterable: [:name, :status]
FlopRest.normalize(%{"name" => "Fido", "custom_field" => "value"}, for: Pet)
# => %{
#   "filters" => [%{"field" => "name", "op" => "==", "value" => "Fido"}],
#   "custom_field" => "value"
# }
```

This matches Flop's API conventions and lets you safely pass user params while keeping non-filter data accessible:

```elixir
def index(conn, params) do
  flop_params = FlopRest.normalize(params, for: Pet)

  with {:ok, {pets, meta}} <- Flop.validate_and_run(Pet, flop_params, for: Pet) do
    json(conn, %{data: pets})
  end
end
```

### Building Pagination Links

Use `build_path/2` to generate pagination links for API responses:

```elixir
def index(conn, params) do
  flop_params = FlopRest.normalize(params)

  with {:ok, {events, meta}} <- Flop.validate_and_run(Event, flop_params, for: Event) do
    json(conn, %{
      data: events,
      links: %{
        self: FlopRest.build_path(conn.request_path, meta.flop),
        next: meta.has_next_page? && FlopRest.build_path(conn.request_path, meta.next_flop),
        prev: meta.has_previous_page? && FlopRest.build_path(conn.request_path, meta.previous_flop)
      }
    })
  end
end
```

This produces links like:

```json
{
  "data": [...],
  "links": {
    "self": "/events?after=abc123&limit=20",
    "next": "/events?after=xyz789&limit=20",
    "prev": "/events?before=abc123&limit=20"
  }
}
```

Use `to_query/1` if you need the raw map to merge with other parameters:

```elixir
query = FlopRest.to_query(meta.next_flop)
# => %{"limit" => 20, "after" => "xyz789"}
```

Both functions accept `Flop.t()` or `Flop.Meta.t()` structs.

## Query Parameter Reference

Everything below describes what your API consumers send as query parameters. `FlopRest.normalize/1` handles the translation to Flop format automatically.

### Filters

A value on its own means "equals":

```
GET /events?status=published
```

Add an operator in brackets to change the comparison:

```
GET /events?amount[gte]=100
GET /events?amount[lt]=500
```

You can combine multiple operators on the same field:

```
GET /events?amount[gte]=100&amount[lt]=500
```

#### List values

Some operators accept multiple values. Use commas to separate them:

```
GET /events?status[in]=draft,published
```

If a value itself contains a comma, use the bracket `[]` syntax instead:

```
GET /events?status[in][]=draft&status[in][]=has,comma
```

The operators that split on commas are: `in`, `not_in`, `like_and`, `like_or`, `ilike_and`, `ilike_or`.

#### Operators

| Operator       | Example                         | SQL                                           |
| -------------- | ------------------------------- | --------------------------------------------- |
| _(none)_       | `status=active`                 | `status = 'active'`                           |
| `eq`           | `status[eq]=active`             | `status = 'active'`                           |
| `ne`           | `status[ne]=archived`           | `status != 'archived'`                        |
| `gt`           | `age[gt]=18`                    | `age > 18`                                    |
| `gte`          | `age[gte]=18`                   | `age >= 18`                                   |
| `lt`           | `price[lt]=100`                 | `price < 100`                                 |
| `lte`          | `price[lte]=100`                | `price <= 100`                                |
| `in`           | `status[in]=draft,published`    | `status IN ('draft', 'published')`            |
| `not_in`       | `status[not_in]=draft,archived` | `status NOT IN ('draft', 'archived')`         |
| `contains`     | `tags[contains]=elixir`         | `'elixir' = ANY(tags)`                        |
| `not_contains` | `tags[not_contains]=go`         | `'go' != ALL(tags)`                           |
| `like`         | `name[like]=%john%`             | `name LIKE '%john%'`                          |
| `not_like`     | `name[not_like]=%test%`         | `name NOT LIKE '%test%'`                      |
| `like_and`     | `name[like_and]=Rubi,Rosa`      | `name LIKE '%Rubi%' AND name LIKE '%Rosa%'`   |
| `like_or`      | `name[like_or]=Rubi,Rosa`       | `name LIKE '%Rubi%' OR name LIKE '%Rosa%'`    |
| `ilike`        | `name[ilike]=%john%`            | `name ILIKE '%john%'`                         |
| `not_ilike`    | `name[not_ilike]=%test%`        | `name NOT ILIKE '%test%'`                     |
| `ilike_and`    | `name[ilike_and]=Rubi,Rosa`     | `name ILIKE '%Rubi%' AND name ILIKE '%Rosa%'` |
| `ilike_or`     | `name[ilike_or]=Rubi,Rosa`      | `name ILIKE '%Rubi%' OR name ILIKE '%Rosa%'`  |
| `empty`        | `deleted_at[empty]=true`        | `deleted_at IS NULL`                          |
| `not_empty`    | `deleted_at[not_empty]=true`    | `deleted_at IS NOT NULL`                      |
| `search`       | `q[search]=john`                | Configurable in Flop (ILIKE by default)       |

Unknown operators are passed through for Flop to validate.

### Sorting

Use the `sort` parameter with `-` prefix for descending:

```
GET /events?sort=name                   # ascending by name
GET /events?sort=-created_at            # descending by created_at
GET /events?sort=-created_at,name       # descending by created_at, then ascending by name
```

### Pagination

FlopRest supports all three Flop pagination types. The type is detected automatically based on which parameters are present.

**Cursor-based** (Stripe-style):

```
GET /events?limit=20                    # first 20 results
GET /events?limit=20&after=abc123       # next 20 after cursor
GET /events?limit=20&before=xyz789      # previous 20 before cursor
```

**Page-based:**

```
GET /events?page=2&page_size=25
```

**Offset-based:**

```
GET /events?offset=50&limit=25
```

## Design Philosophy

FlopRest is a **pure transformation layer**. It does not validate parameters - that's Flop's job. Invalid operators or conflicting pagination params are passed through, and Flop will return appropriate errors.

This keeps FlopRest simple and ensures Flop remains the single source of truth for validation rules.

## License

MIT License. See [LICENSE](LICENSE) for details.
