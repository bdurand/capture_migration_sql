# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.5

### Fixed

- SQL files are no longer deleted before a down migration runs; if the down migration fails, the SQL file is kept since the migration is still applied.
- SQL files are now written to a temporary file and atomically renamed into place, so a process killed mid-migration can no longer leave a permanent, truncated SQL file behind.
- The migration SQL directory is now created with `FileUtils.mkdir_p`, eliminating a race condition between concurrent migration processes and supporting nested custom directories.
- Attaching the SQL subscriber is now thread safe, preventing duplicate subscribers (and duplicated SQL output) when migrations run in parallel threads.
- Ignored statement filters are now applied after stripping leading whitespace, so statements with leading whitespace no longer bypass them.
- The `INSERT INTO schema_migrations` statement written to SQL files now honors custom schema migrations table names and table name prefixes and suffixes.
- Connection labels from `using_connection` are no longer written to the SQL file when SQL logging is disabled.

### Changed

- Rails 5.2 and Ruby 2.6 are the minimum supported versions.

## 1.0.4

### Fixed

- SQL files are now removed when they were created from a failed migration.

## 1.0.3

### Changed

- SQL files will not be changed if they already exist.

## 1.0.2

### Changed

- Fix data type for insterting into schema_migrations

## 1.0.1

### Changed

- Fix SQL for insterting into schema_migrations

## 1.0.0

### Added

- Initial release
