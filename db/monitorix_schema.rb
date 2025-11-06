# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_06_130336) do
  create_table "monitorix_background_jobs", force: :cascade do |t|
    t.json "arguments"
    t.datetime "created_at", null: false
    t.float "duration_ms"
    t.datetime "enqueued_at"
    t.text "error_backtrace"
    t.text "error_message"
    t.datetime "finished_at"
    t.string "job_class", null: false
    t.string "job_id"
    t.json "metadata"
    t.float "queue_latency_ms"
    t.string "queue_name"
    t.datetime "started_at"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_monitorix_background_jobs_on_created_at"
    t.index ["job_class"], name: "index_monitorix_background_jobs_on_job_class"
    t.index ["job_id"], name: "index_monitorix_background_jobs_on_job_id"
    t.index ["queue_name"], name: "index_monitorix_background_jobs_on_queue_name"
    t.index ["status"], name: "index_monitorix_background_jobs_on_status"
  end

  create_table "monitorix_code_suggestions", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "file", null: false
    t.datetime "first_seen_at"
    t.boolean "ignored", default: false
    t.datetime "last_seen_at"
    t.integer "line"
    t.text "message", null: false
    t.integer "occurrences", default: 1
    t.string "rule_name"
    t.string "severity", null: false
    t.text "suggestion"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_monitorix_code_suggestions_on_category"
    t.index ["file", "line", "rule_name"], name: "index_monitorix_code_suggestions_unique", unique: true
    t.index ["file"], name: "index_monitorix_code_suggestions_on_file"
    t.index ["ignored"], name: "index_monitorix_code_suggestions_on_ignored"
    t.index ["severity"], name: "index_monitorix_code_suggestions_on_severity"
  end

  create_table "monitorix_errors", force: :cascade do |t|
    t.text "backtrace"
    t.json "context"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "exception_class", null: false
    t.string "file"
    t.datetime "first_seen_at"
    t.datetime "last_seen_at"
    t.integer "line"
    t.text "message"
    t.integer "occurrences", default: 1
    t.integer "request_id"
    t.boolean "resolved", default: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_monitorix_errors_on_created_at"
    t.index ["exception_class", "file", "line"], name: "index_monitorix_errors_on_exception_class_and_file_and_line"
    t.index ["exception_class"], name: "index_monitorix_errors_on_exception_class"
    t.index ["request_id"], name: "index_monitorix_errors_on_request_id"
    t.index ["resolved"], name: "index_monitorix_errors_on_resolved"
  end

  create_table "monitorix_layers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "duration_ms", null: false
    t.string "file"
    t.string "layer_type", null: false
    t.integer "line"
    t.json "metadata"
    t.string "name", null: false
    t.integer "parent_id"
    t.text "query"
    t.integer "request_id", null: false
    t.float "self_time_ms"
    t.datetime "updated_at", null: false
    t.index ["layer_type"], name: "index_monitorix_layers_on_layer_type"
    t.index ["parent_id"], name: "index_monitorix_layers_on_parent_id"
    t.index ["request_id", "layer_type"], name: "index_monitorix_layers_on_request_id_and_layer_type"
    t.index ["request_id"], name: "index_monitorix_layers_on_request_id"
  end

  create_table "monitorix_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "metric_type", null: false
    t.string "name", null: false
    t.json "tags"
    t.datetime "updated_at", null: false
    t.float "value", null: false
    t.index ["created_at"], name: "index_monitorix_metrics_on_created_at"
    t.index ["endpoint"], name: "index_monitorix_metrics_on_endpoint"
    t.index ["name", "created_at"], name: "index_monitorix_metrics_on_name_and_created_at"
    t.index ["name"], name: "index_monitorix_metrics_on_name"
  end

  create_table "monitorix_requests", force: :cascade do |t|
    t.string "action"
    t.string "controller"
    t.datetime "created_at", null: false
    t.float "db_time_ms", default: 0.0
    t.float "duration_ms", null: false
    t.string "endpoint", null: false
    t.string "format"
    t.json "headers"
    t.string "http_method"
    t.string "ip_address"
    t.json "metadata"
    t.json "params"
    t.string "path"
    t.integer "query_count", default: 0
    t.integer "status_code"
    t.string "transaction_id"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.float "view_time_ms", default: 0.0
    t.index ["controller", "action"], name: "index_monitorix_requests_on_controller_and_action"
    t.index ["created_at"], name: "index_monitorix_requests_on_created_at"
    t.index ["duration_ms"], name: "index_monitorix_requests_on_duration_ms"
    t.index ["endpoint"], name: "index_monitorix_requests_on_endpoint"
    t.index ["transaction_id"], name: "index_monitorix_requests_on_transaction_id", unique: true
  end

  add_foreign_key "monitorix_errors", "monitorix_requests", column: "request_id"
  add_foreign_key "monitorix_layers", "monitorix_layers", column: "parent_id"
  add_foreign_key "monitorix_layers", "monitorix_requests", column: "request_id"
end
