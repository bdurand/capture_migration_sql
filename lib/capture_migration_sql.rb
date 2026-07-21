require_relative "capture_migration_sql/migration_extension"
require_relative "capture_migration_sql/sql_subscriber"
require_relative "capture_migration_sql/version"

module CaptureMigrationSql
  class << self
    # Call this method in an initializer to invoke dumping the SQL executed
    # during migrations in to a file.
    #
    # The `directory` argument indicates the directory where the files should be stored.
    # If the directory is not specified, the files will be stored in `db/migration_sql/`.
    #
    # The `starting_with` argument can be used to specify which migration you
    # wish to start capturing SQL with. This can be useful if you are adding
    # this gem to an existing project with a history of migrations that you
    # don't want to go back and edit.
    def capture(directory: nil, starting_with: 0)
      unless ::ActiveRecord::Migration.include?(MigrationExtension)
        ::ActiveRecord::Migration.prepend(MigrationExtension)
      end
      @sql_directory = (directory || Rails.root + "db" + "migration_sql")
      @starting_with_version = starting_with.to_i
    end

    # Return the directory set by `capture_sql` for storing migration SQL.
    def directory
      @sql_directory if defined?(@sql_directory)
    end

    # Return the migration version number to start capturing SQL.
    def starting_with_version
      @starting_with_version if defined?(@starting_with_version)
    end

    # Return true if capturing SQL is enabled for migrations.
    def capture_enabled?
      !!Thread.current[:capture_migration_sql_enabled]
    end

    # Return the stream migration SQL is being written to.
    def capture_stream
      Thread.current[:capture_migration_sql_stream]
    end

    # Resolve the schema migrations table name so that both the SQL that is
    # written to the file and the statement filter honor custom table names
    # and any table name prefix or suffix. Falls back to "schema_migrations"
    # if the name cannot be determined.
    def schema_migrations_table_name
      if defined?(ActiveRecord::SchemaMigration) && ActiveRecord::SchemaMigration.respond_to?(:table_name)
        ActiveRecord::SchemaMigration.table_name
      else
        connection = ActiveRecord::Base.connection
        schema_migration = if connection.respond_to?(:schema_migration)
          connection.schema_migration
        elsif connection.pool.respond_to?(:schema_migration)
          connection.pool.schema_migration
        end
        schema_migration ? schema_migration.table_name : "schema_migrations"
      end
    end
  end
end
