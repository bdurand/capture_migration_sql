# frozen_string_literal: true

# Extension methods for ActiveRecord::Migration class.
module CaptureMigrationSql
  module MigrationExtension
    # Monkey patch to public but internal ActiveRecord method to pass
    # a connection that will log SQL statements.
    def exec_migration(conn, direction)
      log_migration_sql(direction) do
        super(conn, direction)
      end
    end

    # Disable SQL logging. You can use this method to turn off logging SQL
    # when the migration is munging data that may vary between environments.
    def disable_sql_logging(&block)
      sql_logging(enabled: false, &block)
    end

    # Enable SQL logging. You can call this method within a block where SQL
    # logging was disabled to renable it.
    def enable_sql_logging(&block)
      sql_logging(enabled: true, &block)
    end

    # Use a different database connection for the block. You can use this
    # if your application has multiple databases to swap connections for
    # the migration. You can pass in either a database connection or an
    # ActiveRecord::Base class to use the connection used by that class.
    #
    # The label argument will be added to the logged SQL as a comment.
    def using_connection(connection_or_class, label: nil, &block)
      if connection_or_class.is_a?(Class) && connection_or_class < ActiveRecord::Base
        label ||= connection_or_class.name
        connection_or_class.connection_pool.with_connection do |connection|
          switch_connection_in_block(connection, label: label, &block)
        end
      else
        switch_connection_in_block(connection_or_class, label: label, &block)
      end
    end

    private

    def switch_connection_in_block(connection, label:, &block)
      save_connection = @connection
      begin
        @connection = connection
        stream = CaptureMigrationSql.capture_stream
        stream.write("-- BEGIN #{label}\n\n") if label && stream
        retval = yield
        stream.write("-- END #{label}\n\n") if label && stream
        retval
      ensure
        @connection = save_connection
      end
    end

    def sql_logging(enabled:, &block)
      save_val = Thread.current[:capture_migration_sql_enabled]
      begin
        Thread.current[:capture_migration_sql_enabled] = enabled
        yield
      ensure
        Thread.current[:capture_migration_sql_enabled] = save_val
      end
    end

    def log_migration_sql(direction, &block)
      migration_sql_dir = CaptureMigrationSql.directory
      output_file = File.join(migration_sql_dir, "#{version}_#{name.underscore}.sql") if version && name
      if output_file && direction == :up && version.to_i >= CaptureMigrationSql.starting_with_version
        Dir.mkdir(migration_sql_dir) unless File.exist?(migration_sql_dir)
        SqlSubscriber.attach_if_necessary
        File.open(output_file, "w") do |f|
          f.write("--\n-- #{name} : #{version}\n--\n\n")
          save_stream = Thread.current[:capture_migration_sql_stream]
          begin
            Thread.current[:capture_migration_sql_stream] = f
            sql_logging(enabled: true, &block)
          ensure
            Thread.current[:capture_migration_sql_stream] = save_stream
          end
          f.write("INSERT INTO schema_versions (VERSION) VALUES #{version.to_i};\n")
        end
      else
        File.unlink(output_file) if output_file && File.exist?(output_file)
        yield
      end
    end
  end
end
