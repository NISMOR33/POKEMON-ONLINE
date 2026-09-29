#===============================================================================
# Complete AZERTY keyboard/mouse profile for Essentials 21.1 / mkxp-z.
# Symbols passed to pressex? are SDL PHYSICAL scancodes, not printed letters:
# French Z = :W, Q = :A, A = :Q. Never mix these with global Win32 key polling.
# This profile replaces native action bindings (including old saved F1 bindings).
#===============================================================================
module AZERTYControls
  BINDINGS = {
    Input::UP => [:W, :UP], Input::LEFT => [:A, :LEFT],
    Input::DOWN => [:S, :DOWN], Input::RIGHT => [:D, :RIGHT],
    Input::USE => [:E, :RETURN, :SPACE, :C, 1],
    Input::BACK => [:ESCAPE, :X, 2],
    Input::ACTION => [:TAB], Input::SPECIAL => [:F],
    Input::JUMPUP => [:Q, :PAGEUP], Input::JUMPDOWN => [:R, :PAGEDOWN],
    Input::AUX1 => [:F4], Input::AUX2 => [:V],
    :run => [:LSHIFT, :RSHIFT], :chat => [:T], :help => [:F1]
  }.freeze
  DIRECTIONS = [Input::DOWN, Input::LEFT, Input::RIGHT, Input::UP].freeze
  HELP = [
    ["DEPLACEMENTS ET SOURIS", "ZQSD / fleches : deplacement et navigation",
     "Maj : courir / inverser la course auto",
     "E / Entree / Espace / C / clic G : valider",
     "Echap / X / clic D : retour ou menu",
     "Le clic valide la selection en cours."],
    ["MENUS ET RACCOURCIS", "Tab : menu / action secondaire",
     "F : objets enregistres / actions de terrain",
     "T : chat multijoueur sur la carte",
     "A / Page prec. : page ou fonction precedente",
     "R / Page suiv. : page ou fonction suivante"],
    ["COMBAT ET POKEMON", "ZQSD : choix ; E : OK ; Echap : retour",
     "Tab : action (ex. Mega-Evolution)",
     "A / R : informations, selon l'ecran",
     "A sur la carte : montrer/cacher le suiveur",
     "V : action auxiliaire, selon l'ecran"],
    ["OUTILS ET SAISIE", "F4 : vitesse x1 / x1,5 / x2, selon options",
     "F1 : aide sur la carte ; F8 : capture",
     "Alt + Entree : plein ecran ; F9 : debug",
     "Texte : Entree OK, Echap annule, Retour efface",
     "Profil AZERTY fixe ; anciens reglages ignores"]
  ].freeze

  class << self
    def focused?
      return true unless RUBY_PLATFORM =~ /mswin|mingw/
      return false unless defined?(Win32API)
      @foreground ||= Win32API.new('user32', 'GetForegroundWindow', '', 'l')
      @window_pid ||= Win32API.new('user32', 'GetWindowThreadProcessId', 'lp', 'l')
      buffer = [0].pack('L')
      @window_pid.call(@foreground.call, buffer)
      buffer.unpack1('L') == Process.pid
    rescue StandardError
      false # Fail closed: never control another player's unfocused window.
    end

    def text_entry?
      Input.respond_to?(:text_input) && Input.text_input
    end

    def overworld?
      return false unless defined?(Scene_Map) && $scene.is_a?(Scene_Map)
      return false unless $game_temp && $game_player && $PokemonGlobal
      return false if $game_temp.in_menu || $game_temp.in_battle ||
                      $game_temp.message_window_showing || $game_temp.in_mini_update
      return false if text_entry? || @modal || pbMapInterpreterRunning?
      !$PokemonGlobal.forced_movement?
    end

    def modal
      previous = @modal
      temp = $game_temp
      previous_menu = temp.in_menu if temp
      @modal = true
      temp.in_menu = true if temp
      yield
    ensure
      @modal = previous
      temp.in_menu = previous_menu if temp
      suppress_held!
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def virtual?(method, button)
      defined?(PEMK::Autopilot::VInput) && PEMK::Autopilot.active? &&
        PEMK::Autopilot::VInput.public_send(method, button)
    end

    def suppress_held!
      @blocked ||= {}
      BINDINGS.each_value do |keys|
        keys.each { |key| @blocked[key] = true if Input.pressex?(key) }
      end
      @down = {}; @triggered = {}; @repeated = {}; @released = {}
    end

    def update
      @down ||= {}; @blocked ||= {}; @started ||= {}; @next_repeat ||= {}
      old = @down
      @down = {}; @triggered = {}; @repeated = {}; @released = {}
      active = focused? && !text_entry?
      alt = Input.pressex?(:LALT) || Input.pressex?(:RALT)
      ctrl = Input.pressex?(:LCTRL) || Input.pressex?(:RCTRL)
      time = now
      BINDINGS.each do |button, keys|
        held = false
        keys.each do |key|
          raw = Input.pressex?(key)
          @blocked.delete(key) unless raw
          valid = active && !alt && !ctrl
          valid &&= Input.mouse_in_window if key.is_a?(Integer)
          @blocked[key] = true if raw && !valid
          held ||= raw && valid && !@blocked[key]
        end
        if held
          @down[button] = true
          if !old[button]
            @triggered[button] = @repeated[button] = true
            @started[button] = time
            @next_repeat[button] = time + 0.35
          elsif time >= @next_repeat[button]
            @repeated[button] = true
            @next_repeat[button] = time + 0.08
          end
        elsif old[button]
          @released[button] = true
        end
      end
    end

    def state(method, button)
      # Merge virtual input at action level so legacy native bindings cannot leak.
      return true if virtual?(method, button)
      table = { :press? => @down, :trigger? => @triggered,
                :repeat? => @repeated, :release? => @released }[method]
      !!(table && table[button])
    end

    def directions
      dirs = DIRECTIONS.select { |key| state(:press?, key) }
      dirs -= [Input::UP, Input::DOWN] if dirs.include?(Input::UP) && dirs.include?(Input::DOWN)
      dirs -= [Input::LEFT, Input::RIGHT] if dirs.include?(Input::LEFT) && dirs.include?(Input::RIGHT)
      dirs
    end

    def dir4
      directions.max_by { |key| (@started || {})[key] || 0 } || 0
    end

    def dir8
      dirs = directions
      return dir4 if dirs.size < 2
      return dirs.include?(Input::LEFT) ? 7 : 9 if dirs.include?(Input::UP)
      dirs.include?(Input::LEFT) ? 1 : 3
    end
  end
end

module Input
  class << self
    alias_method :azerty_native_update, :update
    alias_method :azerty_native_press, :press?
    alias_method :azerty_native_trigger, :trigger?
    alias_method :azerty_native_repeat, :repeat?
    alias_method :azerty_native_release, :release?

    def update
      azerty_native_update
      AZERTYControls.update
      delta_speed_update if respond_to?(:delta_speed_update)
    end

    def press?(button)
      return AZERTYControls.state(:press?, button) if AZERTYControls::BINDINGS.key?(button)
      azerty_native_press(button)
    end

    def trigger?(button)
      if button == Input::ACTION && AZERTYControls.overworld?
        return true if AZERTYControls.state(:trigger?, Input::BACK)
      end
      return AZERTYControls.state(:trigger?, button) if AZERTYControls::BINDINGS.key?(button)
      azerty_native_trigger(button)
    end

    def repeat?(button)
      return AZERTYControls.state(:repeat?, button) if AZERTYControls::BINDINGS.key?(button)
      azerty_native_repeat(button)
    end

    def release?(button)
      return AZERTYControls.state(:release?, button) if AZERTYControls::BINDINGS.key?(button)
      azerty_native_release(button)
    end

    def dir4; AZERTYControls.dir4; end
    def dir8; AZERTYControls.dir8; end
  end
end

class Game_Player
  # Keep the engine's running-shoe/terrain/event restrictions, with a separate run key.
  def can_run?
    return @move_speed > 3 if @move_route_forcing
    return false if @bumping
    return false if $game_temp.in_menu || $game_temp.in_battle ||
                    $game_temp.message_window_showing || pbMapInterpreterRunning?
    return false if !$player.has_running_shoes && !$PokemonGlobal.diving &&
                    !$PokemonGlobal.surfing && !$PokemonGlobal.bicycle
    return false if jumping? || pbTerrainTag.must_walk
    ($PokemonSystem.runstyle == 1) ^ AZERTYControls.state(:press?, :run)
  end
end

class Scene_Map
  alias_method :azerty_scene_update, :update
  def update
    if AZERTYControls.overworld? && !$game_player.moving? &&
       AZERTYControls.state(:trigger?, :help)
      AZERTYControls.modal { pbEventScreen(ButtonEventScene) }
    end
    azerty_scene_update
  end
end

# Replace the old C/X/Z/D illustrations with an accurate, readable four-page help.
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super(viewport)
    Graphics.freeze
    @current_screen = 1
    addImage(0, 0, "Graphics/UI/Controls help/bg")
    @labels = []; @label_screens = []; @keys = []; @key_screens = []
    AZERTYControls::HELP.each_with_index do |lines, index|
      lines.each_with_index do |line, row|
        addLabelForScreen(index + 1, 12, 32 + row * 48, Graphics.width - 24, line)
      end
      addLabelForScreen(index + 1, 12, 336, Graphics.width - 24,
                        "#{index + 1}/4 - E : suite ; Echap : fermer")
    end
    set_up_screen(@current_screen)
    Graphics.transition
    onCTrigger.set(method(:pbOnScreenEnd))
    onBTrigger.set(method(:pbCloseControls))
  end

  def pbCloseControls(scene, *args)
    scene.dispose
  end

  def pbOnScreenEnd(scene, *args)
    if @current_screen >= AZERTYControls::HELP.length
      scene.dispose
    else
      @current_screen += 1
      onCTrigger.clear
      set_up_screen(@current_screen)
      onCTrigger.set(method(:pbOnScreenEnd))
    end
  end
end
