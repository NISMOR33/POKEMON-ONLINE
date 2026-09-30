#===============================================================================
# PEMK_Housing :: 003 Menu
#-------------------------------------------------------------------------------
# Main hotel receptionist menu, exit handler & login redirect.
# Called from the NPC event on Map 33.
# Handles: Ma maison / Boutique de meubles / Annuler.
# Teleports into the house map and handles exiting back to the overworld.
# Auto-redirects player back to hotel NPC if reloading a save inside the house.
#===============================================================================
module PEMK
  module Housing
    @return_pos        = nil  # [map_id, x, y, direction]
    @leaving           = false
    @entering_via_menu = false

    class << self
      attr_accessor :return_pos, :entering_via_menu, :leaving

      # Entry point called by the hotel NPC event.
      def open_menu
        unless connected?
          pbMessage("Tu n'es pas connecté au serveur.")
          return
        end

        cmds = ["Ma maison", "Boutique de meubles", "Annuler"]
        choice = pbMessage("Bienvenue ! Que puis-je faire pour vous ?", cmds, cmds.length - 1)

        case choice
        when 0 then enter_house
        when 1 then open_shop
        # 2 = Annuler, nothing
        end
      end

      # Teleport into the player's house. Requests state from server and waits.
      def enter_house
        @entering_via_menu = true

        begin
          tier = 1
          tier = Housing.state[:size_tier] if Housing.state

          # Store return position before entering house
          if $game_map && $game_player
            @return_pos = [
              $game_map.map_id,
              $game_player.x,
              $game_player.y,
              $game_player.direction
            ]
            PEMK.log("housing: saved return_pos = #{@return_pos.inspect}")
          end

          # Request state from server (creates the house on first visit)
          Housing.send_enter

          # Wait up to 3 seconds for server reply
          deadline = Time.now + 3
          until Housing.state || Time.now > deadline
            Graphics.update
            Input.update
            PEMK.client&.poll&.each { |msg| PEMK::Dispatch.handle(msg) } rescue nil
          end

          unless Housing.state
            pbMessage("Impossible de joindre le serveur. Réessaie dans un moment.")
            return
          end

          # Use correct map and entry coordinates for the size tier received
          tier   = Housing.state[:size_tier]
          map_id = MAP_FOR_TIER.fetch(tier, HOUSE_MAP_S)
          entry_grid = entry_grid_for(tier)
          entry_x = GRID_ORIGIN_X + entry_grid[0]
          entry_y = GRID_ORIGIN_Y + entry_grid[1]

          PEMK.log("housing: entering house map=#{map_id} spawn=(#{entry_x},#{entry_y})")

          # Teleport
          pbFadeOutIn {
            $game_temp.player_new_map_id    = map_id
            $game_temp.player_new_x         = entry_x
            $game_temp.player_new_y         = entry_y
            $game_temp.player_new_direction = 8   # face up (toward interior)
            $scene.transfer_player if $scene.respond_to?(:transfer_player)
          }

          # After teleport, trigger renderer
          HousingRenderer.setup if defined?(HousingRenderer)
        ensure
          @entering_via_menu = false
        end
      end

      # Leave house when stepping on the exit threshold or when auto-redirected
      def leave_house
        return if @leaving
        @leaving = true

        begin
          # Clean up renderer & editor HUD completely
          HousingRenderer.dispose   if defined?(HousingRenderer)
          HousingEditor.dispose_all if defined?(HousingEditor)

          # Fallback return position if none saved: hotel NPC map 33
          r_map, r_x, r_y, r_dir = @return_pos || HOTEL_NPC_SPAWN

          PEMK.log("housing: leaving house -> single transfer to map #{r_map} (#{r_x}, #{r_y}) dir=#{r_dir}")

          # Reset state immediately BEFORE starting transfer so check_leave stops firing
          Housing.reset

          pbFadeOutIn {
            $game_temp.player_new_map_id    = r_map
            $game_temp.player_new_x         = r_x
            $game_temp.player_new_y         = r_y
            $game_temp.player_new_direction = r_dir || 2
            $scene.transfer_player if $scene.respond_to?(:transfer_player)
          }

          PEMK.log("housing: transfer to overworld map #{r_map} complete")
        ensure
          @leaving = false
        end
      end

      # Check if player stepped on exit threshold
      def check_leave
        return if @leaving
        return unless $game_map && $game_player && Housing.state
        return if $game_temp.player_transferring || $game_temp.transition_processing

        tier = Housing.state[:size_tier]
        current_map = MAP_FOR_TIER[tier]
        return unless $game_map.map_id == current_map

        exit_info = EXIT_TILES[tier]
        return unless exit_info

        px = $game_player.x
        py = $game_player.y

        if py == exit_info[:y] && exit_info[:x_range].include?(px)
          leave_house
        end
      end

      # Redirect player to hotel receptionist ONLY if reloading a save file inside house map (Housing.state is nil)
      def check_login_house_redirect
        return if @leaving
        return if @entering_via_menu
        return unless $scene.is_a?(Scene_Map) && $game_map
        return unless is_house_map?($game_map.map_id)
        return if $game_temp&.player_transferring || $game_temp&.transition_processing

        # If Housing.state exists, the player entered legitimately via menu in this session!
        return if Housing.state

        PEMK.log("housing: player loaded save inside house map #{$game_map.map_id} without active session state -> redirecting to hotel NPC")
        leave_house
      end

      # Open the furniture shop.
      def open_shop
        unless connected?
          pbMessage("Tu n'es pas connecté au serveur.")
          return
        end

        pbMessage("Chargement du catalogue...")
        Housing.send_catalog

        deadline = Time.now + 3
        until Housing.catalog || Time.now > deadline
          Graphics.update
          Input.update
          PEMK.client&.poll&.each { |msg| PEMK::Dispatch.handle(msg) } rescue nil
        end

        unless Housing.catalog
          pbMessage("Impossible de charger le catalogue. Réessaie.")
          return
        end

        HousingShop.run if defined?(HousingShop)
      end
    end
  end
end

# Hook Scene_Map#update to check exit threshold AND auto-redirect on game load inside house
class Scene_Map
  alias_method :pemk_housing_leave_orig_update, :update

  def update
    if $scene.is_a?(Scene_Map) && $game_map && PEMK::Housing.is_house_map?($game_map.map_id)
      unless PEMK::Housing.entering_via_menu || PEMK::Housing.state
        PEMK::Housing.check_login_house_redirect
      end
    end
    PEMK::Housing.check_leave if $scene.is_a?(Scene_Map) && PEMK::Housing.state
    pemk_housing_leave_orig_update
  end
end

# Multi-event hooks for game load / map enter
if defined?(EventHandlers)
  EventHandlers.add(:on_enter_map, :pemk_housing_login_redirect, proc { |_old_map_id|
    PEMK::Housing.check_login_house_redirect
  })
  EventHandlers.add(:on_map_or_load, :pemk_housing_load_redirect, proc {
    PEMK::Housing.check_login_house_redirect
  })
end

