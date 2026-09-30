# encoding: utf-8
#===============================================================================
# PEMK_Housing :: 006 Shop
#-------------------------------------------------------------------------------
# Interface d'achat de mobilier. Utilise pbMessage pour l'UI de base.
# Ouverte depuis Housing.open_shop (nécessite que le catalogue soit chargé).
#===============================================================================
module PEMK
  module HousingShop
    @waiting = false
    @pending_buy = nil

    class << self
      def waiting?
        @waiting
      end

      def on_catalog_received
        @waiting = false
      end

      def on_buy_ok(new_uids)
        @pending_buy = nil
      end

      def on_error(msg)
        @pending_buy = nil
      end

      # Main shop loop. Catalog must already be loaded.
      def run
        catalog = Housing.catalog
        return pbMessage("Catalogue indisponible.".dup) unless catalog && !catalog.empty?

        loop do
          # Build display list
          items = catalog.select { |i| i[:price].to_i > 0 }
          names = items.map { |i|
            iname = i[:name].to_s.force_encoding("UTF-8")
            "#{iname}  #{i[:price]}¥ (#{i[:footprint_w]}x#{i[:footprint_h]})"
          }
          choice = pbMessage("Boutique de meubles :".dup, names + ["Quitter".dup], names.length)
          break if choice < 0 || choice >= items.length

          item = items[choice]
          qty_opts = ["1", "2", "3", "5", "10", "Annuler"]
          item_name = item[:name].to_s.force_encoding("UTF-8")
          qty_idx  = pbMessage("Quantité pour #{item_name} :".dup, qty_opts, qty_opts.length - 1)
          next if qty_idx < 0 || qty_idx >= qty_opts.length - 1

          qty  = qty_opts[qty_idx].to_i
          cost = item[:price] * qty
          confirm = pbConfirmMessage("Acheter #{qty}x #{item_name} pour #{cost}¥ ?".dup)
          next unless confirm

          # Send buy request and wait briefly for ok/error
          Housing.send_buy(item[:id], qty)
          @pending_buy = true
          @waiting     = false   # reset; on_buy_ok will clear pending_buy

          deadline = Time.now + 3
          until !@pending_buy || Time.now > deadline
            Graphics.update
            Input.update
            PEMK.client&.poll&.each { |msg| PEMK::Dispatch.handle(msg) } rescue nil
          end

          if @pending_buy
            pbMessage("Pas de réponse du serveur. Réessaie.".dup)
            @pending_buy = nil
          else
            pbMessage("Achat effectué !".dup)
          end
        end
      end
    end
  end
end

