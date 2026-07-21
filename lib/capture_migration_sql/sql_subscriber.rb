# frozen_string_literal: true

require "active_support/subscriber"

# Subscriber that is attached to ActiveRecord and will handle writing
# migration SQL to the output stream.
module CaptureMigrationSql
  class SqlSubscriber < ::ActiveSupport::Subscriber
    IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"]

    SHOW_STATEMENT = /\ASHOW\b/i
    EXPLAIN_STATEMENT = /\AEXPLAIN\b/i
    SELECT_INFORMATION_SCHEMA = /\ASELECT.*information_schema/im
    SQLLITE_VERSION = /\ASELECT sqlite_version\(/i
    IGNORE_STATEMENTS = Regexp.union(SHOW_STATEMENT, EXPLAIN_STATEMENT, SELECT_INFORMATION_SCHEMA, SQLLITE_VERSION)

    ATTACH_MUTEX = Mutex.new

    class << self
      def attach_if_necessary
        ATTACH_MUTEX.synchronize do
          unless defined?(@attached) && @attached
            attach_to(:active_record)
            @attached = true
          end
        end
      end
    end

    def sql(event)
      stream = CaptureMigrationSql.capture_stream
      return unless stream && CaptureMigrationSql.capture_enabled?

      payload = event.payload
      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])
      sql = payload[:sql]
      return if sql.nil?

      sql = sql.strip
      return if IGNORE_STATEMENTS.match(sql)
      return if schema_migrations_query?(sql)

      sql = "#{sql};" unless sql.end_with?(";")
      stream.write("#{sql}\n\n")
    end

    private

    # Ignore ActiveRecord's own reads of the schema migrations table. The
    # table name is resolved at runtime so that custom table names and any
    # table name prefix or suffix are matched, staying consistent with the
    # name written to the SQL file.
    def schema_migrations_query?(sql)
      table_name = CaptureMigrationSql.schema_migrations_table_name
      return false if table_name.nil? || table_name.empty?
      /\ASELECT.*FROM.*#{Regexp.escape(table_name)}/im.match?(sql)
    end
  end
end
