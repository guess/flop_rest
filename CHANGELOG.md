# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/guess/flop_rest/releases/tag/v0.1.0
