# FlopRest

[![Hex.pm](https://img.shields.io/hexpm/v/flop_rest.svg)](https://hex.pm/packages/flop_rest)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/flop_rest)
[![CI](https://github.com/guess/flop_rest/actions/workflows/ci.yml/badge.svg)](https://github.com/guess/flop_rest/actions/workflows/ci.yml)

REST-friendly query parameters for [Flop](https://github.com/woylie/flop).

## The Problem

Flop is excellent for filtering, sorting, and paginating Ecto queries. But its query parameter format isn't ideal for API consumers:

```
GET /events
  ?filters[0][field]=status
  &filters[0][op]==
  &filters[0][value]=published
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
GET /events?status=published&starts_at[gte]=2024-01-01&sort=-starts_at&limit=20
```

Same query. Same Flop power underneath. Better developer experience on top.

## Installation

Add `flop_rest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flop_rest, "~> 0.1.0"},
    {:flop, "~> 0.26"}
  ]
end
```

## Usage

```elixir
def index(conn, params) do
  flop_params = FlopRest.normalize(params)

  with {:ok, {events, meta}} <- Flop.validate_and_run(Event, flop_params) do
    render(conn, :index, events: events, meta: meta)
  end
end
```

## Filters

Bare values become equality filters:

```
status=published     →  %{field: "status", op: "==", value: "published"}
```

Operators are specified as nested keys:

```
amount[gte]=100      →  %{field: "amount", op: ">=", value: "100"}
amount[lt]=500       →  %{field: "amount", op: "<", value: "500"}
```

Multiple operators on the same field create multiple filters:

```
amount[gte]=100&amount[lt]=500  →  two separate filters
```

List values for `in` and `not_in`:

```
status[in][]=draft&status[in][]=review  →  %{field: "status", op: "in", value: ["draft", "review"]}
```

### Operator Reference

| REST Operator | Flop Operator | Description |
|---------------|---------------|-------------|
| `eq` | `==` | Equal (also bare value) |
| `ne` | `!=` | Not equal |
| `lt` | `<` | Less than |
| `lte` | `<=` | Less than or equal |
| `gt` | `>` | Greater than |
| `gte` | `>=` | Greater than or equal |
| `in` | `in` | In list |
| `not_in` | `not_in` | Not in list |
| `contains` | `contains` | Array contains |
| `not_contains` | `not_contains` | Array does not contain |
| `like` | `like` | SQL LIKE |
| `not_like` | `not_like` | SQL NOT LIKE |
| `like_and` | `like_and` | LIKE with AND |
| `like_or` | `like_or` | LIKE with OR |
| `ilike` | `ilike` | Case-insensitive LIKE |
| `not_ilike` | `not_ilike` | Case-insensitive NOT LIKE |
| `ilike_and` | `ilike_and` | Case-insensitive LIKE with AND |
| `ilike_or` | `ilike_or` | Case-insensitive LIKE with OR |
| `empty` | `empty` | Is NULL |
| `not_empty` | `not_empty` | Is NOT NULL |
| `search` | `=~` | Search (configurable in Flop) |

Unknown operators are passed through for Flop to validate.

## Sorting

Use `-` prefix for descending, `+` or no prefix for ascending:

```
sort=name              →  order_by: ["name"], order_directions: ["asc"]
sort=-created_at       →  order_by: ["created_at"], order_directions: ["desc"]
sort=-created_at,name  →  order_by: ["created_at", "name"], order_directions: ["desc", "asc"]
```

## Pagination

FlopRest supports all three Flop pagination types.

### Cursor-based (Stripe-style)

```
limit=20                        →  first: 20
limit=20&starting_after=abc123  →  first: 20, after: "abc123"
limit=20&ending_before=xyz789   →  last: 20, before: "xyz789"
```

### Page-based

```
page=2&page_size=25  →  page: 2, page_size: 25
```

### Offset-based

```
offset=50&limit=25  →  offset: 50, limit: 25
```

## Design Philosophy

FlopRest is a **pure transformation layer**. It does not validate parameters - that's Flop's job. Invalid operators or conflicting pagination params are passed through, and Flop will return appropriate errors.

This keeps FlopRest simple and ensures Flop remains the single source of truth for validation rules.

## License

MIT License. See [LICENSE](LICENSE) for details.
