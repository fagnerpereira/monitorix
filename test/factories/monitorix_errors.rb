# frozen_string_literal: true

FactoryBot.define do
  factory :monitorix_error, class: "Monitorix::Error" do
    association :request, factory: :monitorix_request
    exception_class { %w[ArgumentError RuntimeError StandardError ActiveRecord::RecordNotFound].sample }
    message { Faker::Lorem.sentence }
    backtrace { Array.new(10) { "#{Faker::File.file_name(ext: 'rb')}:#{Faker::Number.number(digits: 2)}" }.join("\n") }
    file { Faker::File.file_name(dir: "app", ext: "rb") }
    line { Faker::Number.between(from: 1, to: 500) }
    endpoint { "UsersController#show" }
    occurrences { 1 }
    first_seen_at { Time.current }
    last_seen_at { Time.current }
    resolved { false }
    context { {} }

    trait :resolved do
      resolved { true }
    end

    trait :frequent do
      occurrences { Faker::Number.between(from: 10, to: 100) }
    end
  end
end
