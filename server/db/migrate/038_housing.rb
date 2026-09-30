# frozen_string_literal: true

# Phase A — Player housing.
#
# Design decisions:
#  - One house per player (owner_character_id UNIQUE).
#  - Layout is DERIVED from furniture_owned.placed_in_house_id — no jsonb layout
#    column in houses. Single source of truth.
#  - furniture_owned.uid is server-generated ("f_" + SecureRandom.hex(8)), never
#    trusted from the client.
#  - All money flows through economy_ledger (Ledger#adjust called inside a
#    transaction that also writes furniture_owned).
#  - version is bumped atomically with every placement mutation; clients carry
#    base_version to detect conflicts.
Sequel.migration do
  change do
    # ------------------------------------------------------------------ houses --
    create_table(:houses) do
      primary_key :id, type: :Bignum
      foreign_key :owner_character_id, :characters, type: :Bignum,
                  null: false, on_delete: :cascade
      String   :name,           null: false, default: "Maison"
      Integer  :size_tier,      null: false, default: 1           # 1=S 2=M 3=L 4=XL
      String   :visibility,     null: false, default: "private"   # private|friends|invite|public
      column   :appearance,     :jsonb, null: false,
               default: Sequel.lit("'{}'::jsonb")                # wallpaper, floor, music (Phase B)
      Integer  :version,        null: false, default: 0
      TrueClass :hidden_by_admin, null: false, default: false
      DateTime :created_at,     null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at,     null: false, default: Sequel::CURRENT_TIMESTAMP

      index :owner_character_id, unique: true, name: :houses_owner_unique
    end

    # ------------------------------------------------------------- furniture_catalog --
    create_table(:furniture_catalog) do
      primary_key :id, type: :Bignum
      String  :key,         null: false                 # e.g. "bed_wood_01"
      String  :name,        null: false
      String  :category,    null: false                 # decor|functional|wall|floor|partition
      Integer :footprint_w, null: false, default: 1
      Integer :footprint_h, null: false, default: 1
      TrueClass :blocking,  null: false, default: true  # false for floor/rugs
      Integer :price,       null: false, default: 0
      String  :currency,    null: false, default: "money"
      Integer :min_tier,    null: false, default: 1     # house size tier required
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :key, unique: true, name: :furniture_catalog_key_unique
    end

    # ----------------------------------------------------------- furniture_owned --
    create_table(:furniture_owned) do
      primary_key :id, type: :Bignum
      String      :uid,          null: false             # "f_" + SecureRandom.hex(8), server-generated
      foreign_key :owner_character_id, :characters, type: :Bignum,
                  null: false, on_delete: :cascade
      foreign_key :catalog_id,   :furniture_catalog, type: :Bignum,
                  null: false, on_delete: :restrict
      # placement (nil when in inventory, not placed)
      foreign_key :placed_in_house_id, :houses, type: :Bignum,
                  null: true, on_delete: :set_null
      Integer  :x,   null: true
      Integer  :y,   null: true
      Integer  :rot, null: true, default: 0   # 0 | 90 | 180 | 270
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uid, unique: true, name: :furniture_owned_uid_unique
      index :owner_character_id, name: :furniture_owned_owner_idx
      index :placed_in_house_id, name: :furniture_owned_house_idx
    end

    # ----------------------------------------------------------- seed catalog ----
    # 6 test furniture items for Phase A development / QA.
    [
      { key: "bed_wood_01",    name: "Lit en bois",     category: "functional", footprint_w: 2, footprint_h: 2, blocking: true,  price: 500,  currency: "money", min_tier: 1 },
      { key: "table_wood_01",  name: "Table",           category: "decor",      footprint_w: 2, footprint_h: 1, blocking: true,  price: 300,  currency: "money", min_tier: 1 },
      { key: "chair_wood_01",  name: "Chaise",          category: "decor",      footprint_w: 1, footprint_h: 1, blocking: true,  price: 150,  currency: "money", min_tier: 1 },
      { key: "plant_small_01", name: "Plante",          category: "decor",      footprint_w: 1, footprint_h: 1, blocking: true,  price: 200,  currency: "money", min_tier: 1 },
      { key: "lamp_stand_01",  name: "Lampadaire",      category: "decor",      footprint_w: 1, footprint_h: 1, blocking: true,  price: 400,  currency: "money", min_tier: 1 },
      { key: "rug_basic_01",   name: "Tapis basique",   category: "floor",      footprint_w: 2, footprint_h: 2, blocking: false, price: 250,  currency: "money", min_tier: 1 },
    ].each do |row|
      now = Time.now
      self[:furniture_catalog].insert_conflict(target: :key).insert(row.merge(created_at: now))
    end
  end
end

