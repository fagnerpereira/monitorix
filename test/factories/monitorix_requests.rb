# frozen_string_literal: true

FactoryBot.define do
  factory :monitorix_request, class: "Monitorix::Request" do
    endpoint { "#{Faker::Hacker.noun.capitalize}Controller##{Faker::Hacker.verb}" }
    controller { "#{Faker::Hacker.noun.capitalize}Controller" }
    action { Faker::Hacker.verb }
    http_method { %w[GET POST PUT PATCH DELETE].sample }
    path { "/#{Faker::Internet.slug}" }
    status_code { [200, 201, 204, 400, 404, 422, 500, 503].sample }
    duration_ms { Faker::Number.between(from: 10.0, to: 5000.0) }
    db_time_ms { Faker::Number.between(from: 0.0, to: 100.0) }
    view_time_ms { Faker::Number.between(from: 0.0, to: 50.0) }
    query_count { Faker::Number.between(from: 0, to: 50) }
    format { %w[html json xml].sample }
    transaction_id { SecureRandom.uuid }
    user_agent { Faker::Internet.user_agent }
    ip_address { Faker::Internet.ip_v4_address }
    params { { id: Faker::Number.number(digits: 4) } }
    headers { { "HTTP_ACCEPT" => "text/html" } }
    metadata { {} }

    trait :slow do
      duration_ms { Faker::Number.between(from: 500.0, to: 5000.0) }
    end

    trait :fast do
      duration_ms { Faker::Number.between(from: 10.0, to: 100.0) }
    end

    trait :error do
      status_code { [500, 502, 503].sample }
    end

    trait :success do
      status_code { [200, 201, 204].sample }
    end
  end
end
