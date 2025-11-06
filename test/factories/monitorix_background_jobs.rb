# frozen_string_literal: true

FactoryBot.define do
  factory :monitorix_background_job, class: "Monitorix::BackgroundJob" do
    job_id { SecureRandom.uuid }
    job_class { "#{Faker::Hacker.noun.capitalize}Job" }
    queue_name { %w[default mailers low high].sample }
    status { %w[pending running completed failed].sample }
    duration_ms { Faker::Number.between(from: 100.0, to: 10000.0) }
    queue_latency_ms { Faker::Number.between(from: 0.0, to: 1000.0) }
    enqueued_at { 1.hour.ago }
    started_at { 30.minutes.ago }
    finished_at { Time.current }
    arguments { [{ user_id: Faker::Number.number(digits: 4) }] }
    metadata { {} }

    trait :failed do
      status { "failed" }
      error_message { Faker::Lorem.sentence }
      error_backtrace { Array.new(5) { "#{Faker::File.file_name(ext: 'rb')}:#{Faker::Number.number(digits: 2)}" }.join("\n") }
    end

    trait :completed do
      status { "completed" }
      error_message { nil }
      error_backtrace { nil }
    end
  end
end
