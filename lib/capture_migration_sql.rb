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
      unless ActiveRecord::Migration.include?(MigrationExtension)
        ActiveRecord::Migration.prepend(MigrationExtension)
      end
      @sql_directory = (directory || Rails.root + "db" + "migration_sql")
      @starting_with_version = starting_with.to_i
    end

    # Return the directory set by `capture_sql` for storing migration SQL.
    def directory
      @sql_directory if defined?(@sql_directory)
    end

    # Return the migration version number to start capaturing SQL.
    def starting_with_version
      @starting_with_version if defined?(@starting_with_version)
    end
  end

  module MigrationExtension
    # Monkey patch to public but internal ActiveRecord method to pass
    # a connection that will log SQL statements.
    def exec_migration(conn, direction)
      log_migration_sql(conn, direction) do
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
      define_connection_sql_capture(connection)
      save_connection = @connection
      begin
        @connection = connection
        stream = save_connection.sql_stream
        connection.sql_capture(stream) do
          stream.write("-- BEGIN #{label}\n\n") if label && stream
          retval = yield
          stream.write("-- END #{label}\n\n") if label && stream
          retval
        end
      ensure
        @connection = save_connection
      end
    end

    def sql_logging(enabled:, &block)
      save_val = Thread.current[:capture_migration_sql_disabled]
      begin
        Thread.current[:capture_migration_sql_disabled] = (enabled == false)
        yield
      ensure
        Thread.current[:capture_migration_sql_disabled] = save_val
      end
    end

    def log_migration_sql(conn, direction)
      migration_sql_dir = CaptureMigrationSql.directory
      output_file = File.join(migration_sql_dir, "#{version}_#{name.underscore}.sql") if version && name
      if output_file && direction == :up && version.to_i >= CaptureMigrationSql.starting_with_version
        define_connection_sql_capture(conn)
        Dir.mkdir(migration_sql_dir) unless File.exist?(migration_sql_dir)
        File.open(output_file, "w") do |f|
          f.write("--\n-- #{name} : #{version}\n--\n\n")
          conn.sql_capture(f) do
            yield
          end
          f.write("INSERT INTO schema_versions (VERSION) VALUES #{version.to_i};\n")
        end
      else
        File.unlink(output_file) if output_file && File.exist?(output_file)
        yield
      end
    end

    # Add `sql_capture` method to connection that will be used for running migration.
    def define_connection_sql_capture(conn)
      unless conn.respond_to?(:sql_capture)
        def conn.sql_capture(stream)
          @sql_stream = stream
          yield
        ensure
          @sql_stream = nil
        end

        def conn.sql_stream
          @sql_stream ||= nil
        end

        # TODO: Hook into ActiveRecord::LogSubscriber to get the SQL generated
        def conn.execute(sql, name = nil)
          if sql_stream && !Thread.current[:capture_migration_sql_disabled]
            unless sql =~ /^SHOW/ || sql =~ /^SELECT.*FROM.*schema_migrations/ || sql =~ /^SELECT.*information_schema/m
              sql_stream.write("#{sql.strip.chomp(';')};\n\n")
            end
          end
          super(sql, name)
        end
      end
    end
  end
end
