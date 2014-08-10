# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140810175237) do

  create_table "card_attributes", force: true do |t|
    t.integer  "card_template_id"
    t.string   "key"
    t.integer  "value"
    t.integer  "attribute_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "card_attributes", ["card_template_id"], name: "index_card_attributes_on_card_template_id"

  create_table "card_piles", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "card_templates", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cards", force: true do |t|
    t.integer  "card_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "game_id"
  end

  add_index "cards", ["card_template_id"], name: "index_cards_on_card_template_id"

  create_table "games", force: true do |t|
    t.string   "name"
    t.string   "phase"
    t.integer  "turn"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "trash_id"
  end

  add_index "games", ["trash_id"], name: "index_games_on_trash_id"

  create_table "piles", force: true do |t|
    t.integer  "card_pile_id"
    t.integer  "card_id"
    t.integer  "card_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "piles", ["card_id"], name: "index_piles_on_card_id", unique: true
  add_index "piles", ["card_pile_id"], name: "index_piles_on_card_pile_id"

  create_table "player_attributes", force: true do |t|
    t.integer  "player_id"
    t.string   "key"
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "players", force: true do |t|
    t.integer  "game_id"
    t.integer  "user_id"
    t.integer  "play_order"
    t.integer  "deck_id"
    t.integer  "hand_id"
    t.integer  "play_area_id"
    t.integer  "discard_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "players", ["game_id"], name: "index_players_on_game_id"
  add_index "players", ["user_id"], name: "index_players_on_user_id"

  create_table "supplies", force: true do |t|
    t.integer  "game_id"
    t.string   "supply_type"
    t.integer  "card_pile_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "supplies", ["card_pile_id"], name: "index_supplies_on_card_pile_id"
  add_index "supplies", ["game_id"], name: "index_supplies_on_game_id"

  create_table "users", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
