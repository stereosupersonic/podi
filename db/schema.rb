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

ActiveRecord::Schema[7.1].define(version: 2023_12_15_163302) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.string "google_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "events", "episodes"

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
end
