# CaptureMigrationSql

This gem adds the ability to capture and persist the SQL statements executed by migrations. There are a couple of reasons why you may want to do this.

1. Having a list of SQL changes in a migration can allow a more thorough review of database changes during a code review. The Ruby schema directives in Rails are nice for simple tables and for documentation purposes, but if you need to tune your database for performance or data integrity, seeing the raw SQL can give you a better idea of exactly what each change involves.

2. Not everyone gets to run database migrations in production. If you have a DBA who needs to approve and run all changes for security and performance reasons, you'll probably need to give them the individual SQL changes. This gem logs all those changes for you in a consistent place so you don't have to hunt for them in your development logs or reverse engineer them from the Ruby code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capture_migration_sql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capture_migration_sql

## Usage

Add this to a file in `config/initializers` in your Rails application:

```ruby
CaptureMigrationSql.capture
```

This will log each migration to a file in the `db/migration_sql` directory. You can also specify a different directory by passing the path the the `capture` method. Additionally, you can specify a first migration to start with. This will avoid generating files for all previous versions.

```ruby
# Create all files in the directory 'tmp/migration_sql'
CaptureMigrationSql.capture(directory: "tmp/migration_sql")

# Only capture migrations starting with version 20181010081254
CaptureMigrationSql.capture(starting_with: 20181010081254)
```

Within a migration, you can enable and disable capturing SQL within a block:

```ruby
def up
  disable_sql_logging do
    # SQL will not be logged here

    enable_sql_logging do
      # SQL will be logged here
    end

    # SQL will not be logged here
  end
end
```

You should disable SQL logging in migration logic that generate queries to clean up or move data that may result in different results per environment. For instance a block of code that selects rows from an existing table and munges the data for an update would result in different queries for each developer that ran the migration if they had different data in their local database.

Finally, if you application uses multiple databases, you can specify which database connection to use for schema statements within a block. You can also specify an optional label that will be added as a comment in the SQL file.

```ruby
def up
  using_connection(other_database_connection, label: "Comment for file") do
    # schema statements here will use other_database_connection instead of ActiveRecord::Base.connection
  end
end
```

You can either pass in a database connection object or a class that extends from `ActiveRecord::Base`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bdurand/capture_migration_sql.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
