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

ActiveRecord::Schema[8.0].define(version: 2025_11_28_121732) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "episodes", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description", null: false
    t.integer "downloads_count", default: 0
    t.date "published_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "nodes"
    t.boolean "active", default: true
    t.integer "number", default: 0, null: false
    t.string "artwork_url"
    t.text "chapter_marks"
    t.text "image_data"
    t.boolean "visible", default: true
    t.boolean "rss_feed", default: true
    t.index ["number"], name: "index_episodes_on_number", unique: true
    t.index ["published_on"], name: "index_episodes_on_published_on"
    t.index ["rss_feed"], name: "index_episodes_on_rss_feed"
    t.index ["slug"], name: "index_episodes_on_slug", unique: true
    t.index ["title"], name: "index_episodes_on_title", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.bigint "episode_id", null: false
    t.jsonb "data"
    t.datetime "downloaded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "geo_data", default: {}
    t.index ["downloaded_at"], name: "index_events_on_downloaded_at"
    t.index ["episode_id"], name: "index_events_on_episode_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.string "language", null: false
    t.text "seo_keywords"
    t.string "author", null: false
    t.string "owner", null: false
    t.string "email", null: false
    t.string "logo_url", null: false
    t.string "default_episode_artwork_url", null: false
    t.string "itunes_category", null: false
    t.string "itunes_sub_category", null: false
    t.string "itunes_language", null: false
    t.integer "about_episode_number", null: false
    t.string "facebook_url"
    t.string "youtube_url"
    t.string "twitter_url"
    t.string "instagram_url"
    t.string "itunes_url"
    t.string "spotify_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "password_digest", default: "", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "events", "episodes"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade

  create_view "episode_current_statistics", sql_definition: <<-SQL
      SELECT e.id AS episode_id,
      e.number,
      e.title,
      e.published_on,
      to_char((e.published_on)::timestamp with time zone, 'day'::text) AS day,
      (date_part('week'::text, e.published_on))::integer AS week,
      (date_part('year'::text, e.published_on))::integer AS year,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'PT12H'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'PT12H'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a12h,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P1D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P1D'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a1d,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P3D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P3D'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a3d,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P7D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P7D'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a7d,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P14D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P14D'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a14d,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P30D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P30D'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a30d,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P60D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P60D'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a60d,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P3M'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P3M'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a3m,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P6M'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P6M'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a6m,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P1Y'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P1Y'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a12m,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P1Y6M'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P1Y6M'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a18m,
      count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P2Y'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P2Y'::interval))) THEN 1
              ELSE NULL::integer
          END) AS a24m,
      count(*) AS cnt
     FROM (episodes e
       LEFT JOIN events ev ON ((e.id = ev.episode_id)))
    GROUP BY e.id
    ORDER BY (count(
          CASE
              WHEN ((e.published_on <= (CURRENT_DATE - 'P1D'::interval)) AND (ev.created_at >= (CURRENT_DATE - 'P1D'::interval))) THEN 1
              ELSE NULL::integer
          END)) DESC;
  SQL
  create_view "episode_statistics", sql_definition: <<-SQL
      SELECT e.id AS episode_id,
      e.number,
      e.title,
      e.published_on,
      to_char((e.published_on)::timestamp with time zone, 'day'::text) AS day,
      (date_part('week'::text, e.published_on))::integer AS week,
      (date_part('year'::text, e.published_on))::integer AS year,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'PT12H'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a12h,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P1D'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a1d,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P3D'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a3d,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P7D'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a7d,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P14D'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a14d,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P30D'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a30d,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P60D'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a60d,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P3M'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a3m,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P6M'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a6m,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P1Y'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a12m,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P1Y6M'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a18m,
      count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P2Y'::interval)) THEN 1
              ELSE NULL::integer
          END) AS a24m,
      count(*) AS cnt
     FROM (episodes e
       LEFT JOIN events ev ON ((e.id = ev.episode_id)))
    WHERE (e.published_on >= ( SELECT events.created_at
             FROM events
            ORDER BY events.created_at
           LIMIT 1))
    GROUP BY e.id
    ORDER BY (count(
          CASE
              WHEN (ev.created_at <= (e.published_on + 'P1D'::interval)) THEN 1
              ELSE NULL::integer
          END)) DESC;
  SQL
end
