# frozen_string_literal: true

require "active_support/subscriber"

# Subscriber that is attached to ActiveRecord and will handle writing
# migration SQL to the output stream.
module CaptureMigrationSql
  class SqlSubscriber < ::ActiveSupport::Subscriber
    IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"]

    SHOW_STATEMENT = /\ASHOW\b/i
    EXPLAIN_STATEMENT = /\AEXPLAIN\b/i
    SELECT_SCHEMA_MIGRATIONS = /\ASELECT.*FROM.*schema_migrations/im
    SELECT_INFORMATION_SCHEMA = /\ASELECT.*information_schema/im
    SQLLITE_VERSION = /\ASELECT sqlite_version\(/i
    IGNORE_STATEMENTS = Regexp.union(SHOW_STATEMENT, EXPLAIN_STATEMENT, SELECT_SCHEMA_MIGRATIONS, SELECT_INFORMATION_SCHEMA, SQLLITE_VERSION)

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

      sql = "#{sql};" unless sql.end_with?(";")
      stream.write("#{sql}\n\n")
    end
  end
end
