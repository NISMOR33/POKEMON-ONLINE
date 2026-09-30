# frozen_string_literal: true

require "json"

Sequel.migration do
  up do
    cols = schema(:furniture_catalog).map(&:first)

    alter_table(:furniture_catalog) do
      add_column :rotatable, TrueClass, default: false unless cols.include?(:rotatable)
      add_column :sprite, String unless cols.include?(:sprite)
      add_column :image_w, Integer, default: 32 unless cols.include?(:image_w)
      add_column :image_h, Integer, default: 32 unless cols.include?(:image_h)
      add_column :interactive_type, String, null: true unless cols.include?(:interactive_type)
      add_column :enabled, TrueClass, default: true unless cols.include?(:enabled)
      add_column :tradable, TrueClass, default: true unless cols.include?(:tradable)
      add_column :created_at, DateTime, null: true unless cols.include?(:created_at)
      add_column :updated_at, DateTime, null: true unless cols.include?(:updated_at)
    end

    # 1. Disable old test items without deleting them
    old_keys = %w[bed_wood_01 table_wood_01 chair_wood_01 plant_small_01 lamp_stand_01 rug_basic_01]
    from(:furniture_catalog).where(key: old_keys).update(enabled: false)

    # 2. Insert or update 37 real furniture items from meubles.json
    json_path = File.expand_path("../meubles.json", __dir__)
    if File.exist?(json_path)
      items = JSON.parse(File.read(json_path))
      now = Time.now

      items.each do |item|
        row = {
          key:              item["key"],
          name:             item["name"],
          category:         item["category"],
          footprint_w:      item["footprint_w"] || 1,
          footprint_h:      item["footprint_h"] || 1,
          blocking:         item["blocking"].nil? ? true : item["blocking"],
          price:            item["price"] || 100,
          currency:         item["currency"] || "money",
          interactive_type: item["interactive_type"],
          rotatable:        item["rotatable"] || false,
          min_tier:         item["min_tier"] || 1,
          tradable:         item["tradable"].nil? ? true : item["tradable"],
          sprite:           item["sprite"],
          image_w:          item["image_w"] || 32,
          image_h:          item["image_h"] || 32,
          enabled:          true,
          created_at:       now,
          updated_at:       now
        }

        existing = from(:furniture_catalog).where(key: item["key"]).first
        if existing
          from(:furniture_catalog).where(id: existing[:id]).update(row)
        else
          from(:furniture_catalog).insert(row)
        end
      end
    end
  end

  down do
    cols = schema(:furniture_catalog).map(&:first)

    alter_table(:furniture_catalog) do
      drop_column :rotatable if cols.include?(:rotatable)
      drop_column :sprite if cols.include?(:sprite)
      drop_column :image_w if cols.include?(:image_w)
      drop_column :image_h if cols.include?(:image_h)
      drop_column :interactive_type if cols.include?(:interactive_type)
      drop_column :enabled if cols.include?(:enabled)
      drop_column :tradable if cols.include?(:tradable)
      drop_column :created_at if cols.include?(:created_at)
      drop_column :updated_at if cols.include?(:updated_at)
    end
  end
end

