# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:gts_listings) do
      primary_key :id
      String :listing_uid, null: false, unique: true
      Integer :seller_account_id, null: false
      Integer :seller_character_id, null: false
      String :seller_name, null: false
      String :listing_type, null: false # 'pokemon' or 'item'
      String :category, null: false, default: "all"
      String :title, null: false
      Text :data_json, null: false
      String :price_type, null: false, default: "fixed" # 'fixed' or 'auction'
      Integer :price, null: false
      Integer :current_bid, default: 0
      Integer :highest_bidder_account_id
      Integer :highest_bidder_character_id
      String :highest_bidder_name
      String :status, null: false, default: "active" # 'active', 'sold', 'expired', 'cancelled'
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :expires_at, null: false

      index :status
      index :listing_type
      index :seller_character_id
    end

    create_table(:gts_claims) do
      primary_key :id
      Integer :account_id, null: false
      Integer :character_id, null: false
      String :claim_type, null: false # 'money', 'pokemon', 'item'
      String :title, null: false
      Integer :amount, default: 0
      Text :data_json, null: false, default: "{}"
      TrueClass :claimed, null: false, default: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index [:character_id, :claimed]
    end
  end
end

