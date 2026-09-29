#===============================================================================
# PEMK :: PersistHooks  (client side)
#-------------------------------------------------------------------------------
# Wires Phase 2 into the engine via aliases:
#   - Game.start_new : run the blocking login prompt right when New Game is clicked.
#   - Game.start_new / Game.load : stamp the server identity onto $player.
#   - Game.save : push the fresh save hash to the server.
#===============================================================================

module Game
  class << self
    unless method_defined?(:pokemmo_orig_start_new)
      alias_method :pokemmo_orig_start_new, :start_new
      alias_method :pokemmo_orig_load,      :load
      alias_method :pokemmo_orig_save,      :save

      def start_new
        # Trigger the MMO Login / Registration screen right when New Game is pressed
        if defined?(PEMK) && PEMK.enabled? && !PEMK::Auth.logged_in?
          PEMK::Auth.login_blocking
        end

        pokemmo_orig_start_new
        PEMK::Auth.apply_identity
        PEMK::Auth.reconcile_economy       # ledger snapshot (empty for a new account)
        PEMK::Auth.reconcile_inventory     # unseeded -> seed the fresh bag on the first flush
        PEMK::Auth.reconcile_monsters      # uid sweep + first party projection
        (PEMK::Inventory.restore_stores rescue nil)  # PC, mailbox, held items (after evictions)
        (PEMK::TradeRedeliver.ask_owed rescue nil)   # traded Pokemon the save may lack
        (PEMK::Flags.reconcile rescue nil) # union the server's progression facts
        (PEMK::Shop.settled_by_login rescue nil)     # the restore already holds every deal the server made
        ($game_temp.begun_new_game = false) if $game_temp && PEMK::Auth.logged_in?
      end

      def load(save_data)
        if defined?(PEMK) && PEMK.enabled? && !PEMK::Auth.logged_in?
          PEMK::Auth.login_blocking
        end

        pokemmo_orig_load(save_data)
        PEMK::Auth.apply_identity
        PEMK::Auth.reconcile_economy
        PEMK::Auth.reconcile_inventory
        PEMK::Auth.reconcile_monsters
        (PEMK::Inventory.restore_stores rescue nil)
        (PEMK::TradeRedeliver.ask_owed rescue nil)
        (PEMK::Flags.reconcile rescue nil)
        (PEMK::Shop.settled_by_login rescue nil)
        PEMK::Auth.clear_pending
      end

      def save(save_file = SaveData::FILE_PATH, safe: false)
        ok, push = PEMK::Checkpoint.commit(save_file: save_file, safe: safe, force: true)
        PEMK::Checkpoint.on_manual_save(ok, push)
        if ok && PEMK::Auth.logged_in? && !(push == :pushed || push == :unchanged)
          (PEMK::NetStatus.notify(:save_not_synced, _INTL("Saved on this device, but NOT synced to the server yet. Retrying in the background...")) rescue nil)
        end
        ok
      end
    end
  end
end

