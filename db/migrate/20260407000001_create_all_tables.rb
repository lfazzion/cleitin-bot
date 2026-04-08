# frozen_string_literal: true

class CreateAllTables < ActiveRecord::Migration[8.1]
  def change
    create_table "social_profiles" do |t|
      t.string "platform", null: false
      t.string "platform_username", null: false
      t.string "platform_user_id", null: false
      t.string "display_name"
      t.text "bio"
      t.bigint "followers_count"
      t.bigint "following_count"
      t.integer "posts_count", default: 0, null: false
      t.boolean "verified", default: false
      t.boolean "is_private", default: false
      t.string "profile_url"
      t.string "avatar_url"
      t.datetime "last_collected_at"
      t.string "collection_status", default: "pending"
      t.string "platform_url"
      t.timestamps

      t.index ["platform", "platform_user_id"], unique: true
      t.index ["platform"]
      t.index ["verified"]
    end

    create_table "social_posts" do |t|
      t.integer "social_profile_id", null: false
      t.string "platform_post_id", null: false
      t.string "post_type", null: false
      t.text "content"
      t.bigint "likes_count"
      t.bigint "comments_count"
      t.bigint "shares_count"
      t.bigint "views_count"
      t.datetime "posted_at"
      t.json "media_urls", default: []
      t.string "video_url"
      t.string "thumbnail_url"
      t.string "shortcode"
      t.timestamps

      t.index ["social_profile_id", "platform_post_id"], unique: true
      t.index ["social_profile_id"]
      t.index ["post_type"]
      t.index ["posted_at"]
    end

    add_foreign_key "social_posts", "social_profiles"

    create_table "profile_snapshots" do |t|
      t.integer "social_profile_id", null: false
      t.bigint "followers_count"
      t.bigint "following_count"
      t.bigint "posts_count"
      t.datetime "recorded_at", null: false
      t.timestamps

      t.index ["social_profile_id"]
      t.index ["recorded_at"]
    end

    add_foreign_key "profile_snapshots", "social_profiles"

    create_table "news_articles" do |t|
      t.string "title"
      t.text "description"
      t.string "link", null: false
      t.string "source"
      t.datetime "pub_date"
      t.string "query_used"
      t.timestamps

      t.index ["link"], unique: true
      t.index ["pub_date"]
      t.index ["source"]
    end

    create_table "discovered_profiles" do |t|
      t.string "platform", null: false
      t.string "username", null: false
      t.text "bio"
      t.string "profile_url"
      t.string "classification"
      t.text "classification_reason"
      t.integer "source_profile_id"
      t.datetime "classified_at"
      t.timestamps

      t.index ["platform", "username"], unique: true
      t.index ["classification"]
      t.index ["source_profile_id"]
    end

    add_foreign_key "discovered_profiles", "social_profiles", column: "source_profile_id"

    create_table "external_catalogs" do |t|
      t.string "source", null: false
      t.string "external_id", null: false
      t.string "title", null: false
      t.string "media_type"
      t.text "description"
      t.date "release_date"
      t.float "popularity"
      t.float "vote_average"
      t.integer "vote_count"
      t.string "poster_url"
      t.string "genres"
      t.json "metadata", default: {}
      t.string "original_language"
      t.boolean "adult", default: false
      t.string "status"
      t.timestamps

      t.index ["source", "external_id"], unique: true
      t.index ["source"]
      t.index ["media_type"]
      t.index ["release_date"]
    end

    create_table "events" do |t|
      t.string "title", null: false
      t.text "description"
      t.string "source"
      t.string "source_url"
      t.string "location"
      t.date "start_date"
      t.date "end_date"
      t.string "event_type"
      t.string "image_url"
      t.string "organizer"
      t.timestamps

      t.index ["source_url"], unique: true
      t.index ["event_type"]
      t.index ["start_date"]
      t.index ["location"]
    end
  end
end
