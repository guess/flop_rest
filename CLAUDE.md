# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all checks (what CI runs)
mix compile --warnings-as-errors && mix format --check-formatted && mix credo --strict && mix coveralls

# Run tests
mix test                    # All tests
mix test test/flop_rest_test.exs  # Single file
mix test test/flop_rest_test.exs:7  # Single test by line number

# Formatting (uses Styler plugin)
mix format

# Linting
mix credo --strict

# Type checking
mix dialyzer

# Generate docs
mix docs
```

## Architecture

FlopRest is a pure transformation library that converts Stripe-style REST query parameters into Flop format. It depends on Flop and Plug at runtime.

### Module Structure

- `FlopRest` - Main entry point with `normalize/1` function that orchestrates the transformation
- `FlopRest.Filters` - Extracts filter params, handles bare values (`status=published`) and operator syntax (`amount[gte]=100`)
- `FlopRest.Operators` - Maps REST operators (e.g., `gte`, `ne`) to Flop operators (e.g., `>=`, `!=`)
- `FlopRest.Pagination` - Detects and transforms three pagination types: cursor-based, page-based, and offset-based
- `FlopRest.Sorting` - Parses sort strings with `-` prefix for descending order

### Design Philosophy

FlopRest performs **no validation**. Invalid operators or conflicting pagination params are passed through verbatim for Flop to validate. This keeps the library simple and ensures Flop remains the single source of truth for validation rules.

### Test Organization

Tests mirror the module structure with separate files for filters, operators, pagination, and sorting. The main `flop_rest_test.exs` tests the integration through `normalize/1`.
