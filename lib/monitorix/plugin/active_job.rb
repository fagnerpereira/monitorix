# frozen_string_literal: true

module Monitorix
  module Plugin
    class ActiveJob
      def self.install
        return if @installed
        return unless defined?(::ActiveJob)

        # Install hook when ActiveJob is loaded
        ActiveSupport.on_load(:active_job) do
          around_perform do |job, block|
            Monitorix::Plugin::ActiveJob.track_job(job, &block)
          end
        end

        @installed = true
      end

      def self.track_job(job, &block)
        job_record = Monitorix::BackgroundJob.create!(
          job_id: job.job_id,
          job_class: job.class.name,
          queue_name: job.queue_name,
          status: "running",
          enqueued_at: job.enqueued_at,
          started_at: Time.current,
          arguments: sanitize_arguments(job.arguments)
        )

        # Calculate queue latency
        if job.enqueued_at
          latency_ms = (Time.current - job.enqueued_at) * 1000
          job_record.update(queue_latency_ms: latency_ms)
        end

        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

        begin
          result = block.call
          finished_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

          job_record.update!(
            status: "completed",
            finished_at: Time.current,
            duration_ms: finished_at - started_at
          )

          result
        rescue StandardError => e
          finished_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

          job_record.update!(
            status: "failed",
            finished_at: Time.current,
            duration_ms: finished_at - started_at,
            error_message: e.message,
            error_backtrace: e.backtrace&.join("\n")
          )

          raise
        end
      end

      def self.sanitize_arguments(arguments)
        # Basic sanitization - remove sensitive data
        return [] if arguments.nil?

        arguments.map do |arg|
          case arg
          when Hash
            arg.except(:password, :password_confirmation, :token, :secret)
          else
            arg
          end
        end
      end
    end
  end
end
