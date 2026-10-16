# Changelog
All notable changes to this project will be documented in this file.


## v0.3.0 - 2026-10-16
### Added
* Group modules per LINE API group
### Fixed
* Fields with `format: uri` are now decoded as strings instead of raising `UndefinedFunctionError` on a missing `Uri` model (#8)

## v0.2.0 - 2026-09-01
### Added
* Update usages guide

## v0.1.0 - 2026-09-01
### Added
* Generate and sync all API clients from line-openapi
