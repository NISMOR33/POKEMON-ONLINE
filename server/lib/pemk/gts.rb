# frozen_string_literal: true

require "json"
require "securerandom"

module PEMK
  # Server-authoritative Global Trade System (Hôtel des Ventes) — GTS Module.
  # Manages fixed-price sales, auctions, fee deposits, and ledger money transactions.
  class GTS
    LISTING_FEE_RATE = 0.05 # 5% tax on sales to control economy inflation
    DEFAULT_EXPIRY   = 48   # Hours until listing expires

    def initialize(db, ledger, logger: nil)
      @db     = db
      @ledger = ledger
      @log    = logger || ->(_m) {}
    end

    # Fetch active GTS listings matching filters
    def fetch_listings(type = "all", category = "all", query = "", sort_by = "recent", page = 1, per_page = 20)
      ds = @db[:gts_listings].where(status: "active")

      ds = ds.where(listing_type: type) if type && type != "all"
      ds = ds.where(category: category) if category && category != "all"
      if query && !query.strip.empty?
        ds = ds.where(Sequel.ilike(:title, "%#{query.strip}%"))
      end

      case sort_by
      when "price_asc"  then ds = ds.order(:price)
      when "price_desc" then ds = ds.order(Sequel.desc(:price))
      when "expiring"   then ds = ds.order(:expires_at)
      else                   ds = ds.order(Sequel.desc(:id))
      end

      offset = (page - 1) * per_page
      listings = ds.limit(per_page, offset).map do |row|
        {
          id:                          row[:id],
          listing_uid:                 row[:listing_uid],
          seller_name:                 row[:seller_name],
          listing_type:                row[:listing_type],
          category:                    row[:category],
          title:                       row[:title],
          data_json:                   row[:data_json],
          price_type:                  row[:price_type],
          price:                       row[:price],
          current_bid:                 row[:current_bid],
          highest_bidder_name:         row[:highest_bidder_name],
          expires_at:                  row[:expires_at].to_s
        }
      end

      [:ok, listings]
    rescue StandardError => e
      @log.call("gts: fetch_listings failed: #{e.class}: #{e.message}")
      [:error, "FETCH_FAILED", e.message]
    end

    # Fetch player's active listings and pending claims
    def fetch_mine(character_id)
      my_listings = @db[:gts_listings].where(seller_character_id: character_id, status: "active").map do |row|
        {
          listing_uid: row[:listing_uid],
          title:       row[:title],
          price_type:  row[:price_type],
          price:       row[:price],
          current_bid: row[:current_bid],
          expires_at:  row[:expires_at].to_s
        }
      end

      claims = @db[:gts_claims].where(character_id: character_id, claimed: false).map do |row|
        {
          claim_id:   row[:id],
          claim_type: row[:claim_type], # 'money', 'pokemon', 'item'
          title:      row[:title],
          amount:     row[:amount],
          data_json:  row[:data_json]
        }
      end

      [:ok, my_listings, claims]
    rescue StandardError => e
      @log.call("gts: fetch_mine failed for char #{character_id}: #{e.message}")
      [:error, "FETCH_FAILED", e.message]
    end

    # Create a new GTS listing
    def create_listing(character_id, account_id, seller_name, listing_type, data_json, title, price_type, price, duration_hours = 48)
      price = price.to_i
      return [:error, "INVALID_PRICE", "Le prix doit être supérieur à 0 $"] if price <= 0

      deposit_fee = [(price * LISTING_FEE_RATE).round, 100].max

      # Verify and deduct deposit fee from ledger
      balance = @ledger.balance(account_id)
      return [:error, "INSUFFICIENT_FUNDS", "Frais de dépôt insuffisants (#{deposit_fee} $)"] if balance < deposit_fee

      listing_uid = "gts_#{SecureRandom.hex(8)}"
      expires_at  = Time.now + (duration_hours * 3600)

      @db.transaction do
        @ledger.adjust(account_id, -deposit_fee, "gts_deposit_fee", listing_uid)

        @db[:gts_listings].insert(
          listing_uid:                 listing_uid,
          seller_account_id:           account_id,
          seller_character_id:         character_id,
          seller_name:                 seller_name,
          listing_type:                listing_type.to_s,
          category:                    "all",
          title:                       title,
          data_json:                   data_json,
          price_type:                  price_type.to_s,
          price:                       price,
          current_bid:                 0,
          status:                      "active",
          created_at:                  Sequel::CURRENT_TIMESTAMP,
          expires_at:                  expires_at
        )
      end

      [:ok, listing_uid, deposit_fee]
    rescue StandardError => e
      @log.call("gts: create_listing failed: #{e.message}")
      [:error, "CREATE_FAILED", e.message]
    end

    # Buy a fixed-price listing
    def buy_fixed(buyer_character_id, buyer_account_id, buyer_name, listing_uid)
      listing = @db[:gts_listings].where(listing_uid: listing_uid, status: "active", price_type: "fixed").for_update.first
      return [:error, "NOT_FOUND", "Annonce introuvable ou expirée."] unless listing

      if listing[:seller_character_id] == buyer_character_id
        return [:error, "OWN_LISTING", "Vous ne pouvez pas acheter votre propre annonce."]
      end

      price = listing[:price]
      balance = @ledger.balance(buyer_account_id)
      return [:error, "INSUFFICIENT_FUNDS", "Fonds insuffisants (#{price} $ requis)."] if balance < price

      seller_payout = (price * (1.0 - LISTING_FEE_RATE)).round

      @db.transaction do
        # Deduct from buyer
        @ledger.adjust(buyer_account_id, -price, "gts_purchase", listing_uid)

        # Pay seller via claim table
        @db[:gts_claims].insert(
          account_id:   listing[:seller_account_id],
          character_id: listing[:seller_character_id],
          claim_type:   "money",
          title:        "Vente GTS : #{listing[:title]}",
          amount:       seller_payout,
          data_json:    "{}",
          claimed:      false,
          created_at:   Sequel::CURRENT_TIMESTAMP
        )

        # Give item/pokemon claim to buyer
        @db[:gts_claims].insert(
          account_id:   buyer_account_id,
          character_id: buyer_character_id,
          claim_type:   listing[:listing_type],
          title:        listing[:title],
          amount:       1,
          data_json:    listing[:data_json],
          claimed:      false,
          created_at:   Sequel::CURRENT_TIMESTAMP
        )

        # Mark listing as sold
        @db[:gts_listings].where(id: listing[:id]).update(status: "sold")
      end

      [:ok, "Achat réussi de #{listing[:title]} !"]
    rescue StandardError => e
      @log.call("gts: buy_fixed failed: #{e.message}")
      [:error, "BUY_FAILED", e.message]
    end
  end
end

