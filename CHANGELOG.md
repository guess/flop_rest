# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-02-04

### Added

- `FlopRest.to_query/1,2` to convert Flop structs back to REST-style query params
- `FlopRest.build_path/2,3` to build URL paths with REST-style query strings (merges with existing query params)
- `FlopRest.Operators.to_rest/1` for reverse operator mapping (Flop → REST)
- `FlopRest.Pagination.to_rest/1` for reverse pagination transformation
- `FlopRest.Sorting.to_rest/1` for reverse sorting transformation
- `FlopRest.Filters.to_rest/1` for reverse filter transformation
- Accepts both `Flop.t()` and `Flop.Meta.t()` structs

### Changed

- Added `flop` and `plug` as runtime dependencies
- `limit` alone now defaults to cursor-based pagination (`first`) instead of offset-based. This ensures Flop returns cursor metadata for use with `starting_after`/`ending_before`. To use offset-based pagination, include `offset` (e.g., `offset=0&limit=25`).

## [0.1.0] - 2025-02-03

### Added

- Initial release of FlopRest
- `FlopRest.normalize/1` to transform REST-style query params to Flop format
- Filter transformation with support for:
  - Bare values as equality filters (`status=published`)
  - Nested operator syntax (`amount[gte]=100`)
  - All Flop operators: `eq`, `ne`, `lt`, `lte`, `gt`, `gte`, `in`, `not_in`, `contains`, `not_contains`, `like`, `not_like`, `like_and`, `like_or`, `ilike`, `not_ilike`, `ilike_and`, `ilike_or`, `empty`, `not_empty`, `search`
  - Unknown operators passed through for Flop validation
- Sorting transformation:
  - Comma-separated fields (`sort=name,-created_at`)
  - `-` prefix for descending order
  - `+` or no prefix for ascending order
- Pagination support for all three Flop pagination types:
  - Cursor-based (Stripe-style): `limit`, `starting_after`, `ending_before`
  - Page-based: `page`, `page_size`
  - Offset-based: `offset`, `limit`

[0.2.0]: https://github.com/guess/flop_rest/releases/tag/v0.2.0
[0.1.0]: https://github.com/guess/flop_rest/releases/tag/v0.1.0
