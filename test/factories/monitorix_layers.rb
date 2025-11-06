# frozen_string_literal: true

FactoryBot.define do
  factory :monitorix_layer, class: "Monitorix::Layer" do
    association :request, factory: :monitorix_request
    layer_type { %w[controller sql view partial].sample }
    name { "#{layer_type.capitalize} Operation" }
    duration_ms { Faker::Number.between(from: 1.0, to: 100.0) }
    self_time_ms { Faker::Number.between(from: 0.5, to: 50.0) }
    metadata { {} }

    trait :sql do
      layer_type { "sql" }
      name { "SELECT" }
      query { "SELECT * FROM users WHERE id = ?" }
    end

    trait :controller do
      layer_type { "controller" }
      name { "UsersController#index" }
      file { "app/controllers/users_controller.rb" }
      line { Faker::Number.between(from: 1, to: 100) }
    end

    trait :view do
      layer_type { "view" }
      name { "users/index.html.erb" }
      file { "app/views/users/index.html.erb" }
    end

    trait :with_parent do
      association :parent, factory: :monitorix_layer
    end
  end
end
