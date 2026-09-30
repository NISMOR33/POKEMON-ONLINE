# Non-blocking save status; timestamps use real time, independently of F4.
module SaveStatus
  class << self
    def now; Process.clock_gettime(Process::CLOCK_MONOTONIC); end

    def session!
      return if @player.equal?($player)
      dispose
      @player = $player
      @depth = 0; @last_save = nil; @pending = false; @failed = false
      @saving_until = 0; @success_until = 0
      stamp = $player.last_time_saved if $player && $player.respond_to?(:last_time_saved)
      @loaded_age = stamp.is_a?(Time) ? [Time.now - stamp, 0].max : nil
      @loaded_at = now
    end

    def begin_save
      session!
      @depth ||= 0
      if @depth == 0
        @saving_until = now + 0.7
        @attempt_push = nil
      end
      @depth += 1
      render
      # Present the icon BEFORE a synchronous disk write, without pumping the
      # network/game again (which could recursively request another checkpoint).
      if @depth == 1 && @sprite && @sprite.visible &&
         !PEMK::Checkpoint.instance_variable_get(:@terminating) &&
         Graphics.respond_to?(:pemk_orig_update)
        Graphics.pemk_orig_update
      end
    end

    def finish_save(ok, push = nil)
      @attempt_push = push unless push.nil?
      @depth = [(@depth || 1) - 1, 0].max
      return if @depth > 0
      if ok
        @last_save = now
        @failed = false
        @pending = PEMK::Auth.logged_in? && ![:pushed, :unchanged].include?(@attempt_push)
        @success_until = now + 4.0
      else
        @failed = true
        @saving_until = 0
      end
      render
    end

    def synced(path, status)
      return unless path == SaveData::FILE_PATH
      @pending = false if [:pushed, :unchanged].include?(status)
    end

    def age_text
      seconds = if @last_save
                  now - @last_save
                elsif @loaded_age
                  @loaded_age + now - @loaded_at
                end
      return 'Aucune sauvegarde dans cette session' unless seconds
      seconds = [seconds.to_i, 0].max
      return "Il y a #{seconds} s" if seconds < 60
      return "Il y a #{seconds / 60} min" if seconds < 3600
      "Il y a #{seconds / 3600} h #{(seconds % 3600) / 60} min"
    end

    def display
      return [:saving, 'Sauvegarde en cours...', age_text] if (@depth || 0) > 0 || now < (@saving_until || 0)
      return [:error, 'Échec de sauvegarde', age_text] if @failed
      return [:pending, 'Sauvegardé sur cet appareil', 'Synchro serveur en attente'] if @pending
      return [:success, 'Sauvegardé !', age_text] if now < (@success_until || 0)
      return [:idle, 'Dernière sauvegarde', age_text] if @last_save || @loaded_age
      [:idle, 'Sauvegarde auto active', 'Toutes les 2 min, dès que possible']
    end

    def dispose
      if @sprite && !@sprite.disposed?
        @sprite.bitmap.dispose if @sprite.bitmap && !@sprite.bitmap.disposed?
        @sprite.dispose
      end
      @sprite = nil
      @last_display = nil
    end

    def render
      unless $player && defined?(Scene_Map) && $scene.is_a?(Scene_Map)
        dispose
        return
      end
      unless @sprite && !@sprite.disposed?
        @sprite = Sprite.new
        @sprite.bitmap = Bitmap.new(108, 20)
        @sprite.z = 99_999
      end
      @sprite.x = Graphics.width - 114
      @sprite.y = 6
      in_house_map = $game_map && defined?(PEMK::Housing) && PEMK::Housing.is_house_map?($game_map.map_id)
      in_housing_edit = defined?(PEMK::HousingEditor) && PEMK::HousingEditor.active?
      is_saving_active = (@depth || 0) > 0 || now < (@saving_until || 0) || now < (@success_until || 0)
      @sprite.visible = !($game_temp && $game_temp.in_battle) && !in_housing_edit && (in_house_map || is_saving_active)
      state, title, detail = display
      # Keep the age visible even when the server is unavailable.
      detail = "#{age_text} · synchro en attente" if state == :pending
      signature = [state, title, detail]
      return if signature == @last_display
      @last_display = signature
      bitmap = @sprite.bitmap
      bitmap.clear
      bitmap.fill_rect(0, 0, 108, 20, Color.new(16, 24, 36, 175))
      color = case state
              when :saving then Color.new(100, 185, 255)
              when :success then Color.new(100, 225, 145)
              when :error then Color.new(255, 115, 105)
              when :pending then Color.new(255, 205, 100)
              else Color.new(165, 195, 210)
              end
      # Compact disk + one short line; preserve detailed state in display().
      bitmap.fill_rect(5, 5, 9, 10, color)
      bitmap.fill_rect(7, 5, 5, 3, Color.new(16, 24, 36))
      bitmap.fill_rect(7, 11, 5, 3, Color.new(16, 24, 36))
      label = case state
              when :saving then 'Sauvegarde…'
              when :success then 'Sauvegardé'
              when :error then 'Échec sauvegarde'
              when :pending then 'Synchro en attente'
              else (@last_save || @loaded_age) ? age_text : 'Auto active'
              end
      bitmap.font.name = 'Arial'
      bitmap.font.size = 10
      bitmap.font.bold = false
      bitmap.font.color = color
      bitmap.draw_text(19, 1, 85, 18, label)
    rescue StandardError => e
      # A cosmetic failure must never prevent a save.
      PEMK.log("save HUD: #{e.class}: #{e.message}") unless @render_failed
      @render_failed = true
      dispose
    end

    def update
      session!
      render
    end
  end

  module GameHooks
    def save(*args, **kwargs)
      SaveStatus.begin_save
      ok = false
      begin
        ok = super
      ensure
        SaveStatus.finish_save(ok)
      end
    end

    def auto_save(*args, **kwargs)
      SaveStatus.begin_save
      ok = false
      begin
        ok = super
      ensure
        SaveStatus.finish_save(ok)
      end
    end
  end

  module CheckpointHooks
    def commit(*args, **kwargs)
      SaveStatus.begin_save
      result = [false, nil]
      begin
        result = super
      ensure
        SaveStatus.finish_save(result[0], result[1])
      end
    end
  end

  module SyncHooks
    def push_blob(path, **kwargs)
      status = super(path, **kwargs)
      SaveStatus.synced(path, status)
      status
    end
  end

  module GraphicsHooks
    def update(*args)
      SaveStatus.update
      super
    end
  end
end

Game.singleton_class.prepend(SaveStatus::GameHooks)
PEMK::Checkpoint.singleton_class.prepend(SaveStatus::CheckpointHooks)
PEMK::Sync.singleton_class.prepend(SaveStatus::SyncHooks)
Graphics.singleton_class.prepend(SaveStatus::GraphicsHooks)
