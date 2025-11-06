# frozen_string_literal: true

module Monitorix
  module Plugin
    class ActiveRecord
      SQL_STRING_REGEX = /'(?:''|\\'|[^'])*'/
      SQL_NUMERIC_REGEX = /(?<!\w)\d+(?:\.\d+)?(?!\w)/
      SQL_PARAMETER_REGEX = /\$\d+/
      SQL_IN_REGEX = /(\bIN\s*\()([^)]+)(\))/i
      SQL_ONE_LINE_COMMENT_REGEX = /--.*$/
      SQL_MULTI_LINE_COMMENT_REGEX = /\/\*.*?\*\//m

      IGNORED_QUERIES = %w[SCHEMA EXPLAIN CACHE].freeze

      def self.install
        return if @installed
        return unless defined?(ActiveSupport::Notifications)

        ActiveSupport::Notifications.subscribe("sql.active_record", new)

        @installed = true
      end

      def start(name, id, payload)
        request_tracker = Monitorix.current_request
        return unless request_tracker
        return if IGNORED_QUERIES.include?(payload[:name])

        normalized_sql = normalize_sql(payload[:sql])

        request_tracker.start_layer("sql", payload[:name] || "SQL",
          query: normalized_sql,
          original_query: payload[:sql]
        )

        Thread.current[:monitorix_sql_event_id] = id
      end

      def finish(name, id, payload)
        request_tracker = Monitorix.current_request
        return unless request_tracker
        return if IGNORED_QUERIES.include?(payload[:name])

        # Only stop if this is the matching event
        return unless Thread.current[:monitorix_sql_event_id] == id

        request_tracker.stop_layer
        Thread.current[:monitorix_sql_event_id] = nil
      end

      def self.normalize_sql(sql)
        return "" if sql.nil?

        normalized = sql.dup
        normalized.gsub!(SQL_STRING_REGEX, "?")
        normalized.gsub!(SQL_PARAMETER_REGEX, "?")
        normalized.gsub!(SQL_NUMERIC_REGEX, "?")
        normalized.gsub!(SQL_IN_REGEX, '\1?\3')
        normalized.gsub!(SQL_ONE_LINE_COMMENT_REGEX, "")
        normalized.gsub!(SQL_MULTI_LINE_COMMENT_REGEX, "")
        normalized.strip!
        normalized
      end

      private_class_method :normalize_sql
    end
  end
end
