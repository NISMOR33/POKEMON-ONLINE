#===============================================================================
# Hide Mystery Gift option in Load Screen completely for multi-save (brute force approch)
#===============================================================================
if Object.const_defined?(:PokemonLoadScreen) && defined?(SaveData::AUTO_SLOTS)
  class PokemonLoadScreen
    alias_method :pbStartLoadScreen_old, :pbStartLoadScreen

    def pbStartLoadScreen
      @selected_file = SaveData.get_newest_save_slot
      if @selected_file
        @save_data = load_save_file(SaveData.get_full_path(@selected_file))
      else
        @save_data = {}
      end

      commands = []
      cmd_main     = -1
      cmd_options  = -1
      cmd_language = -1
      cmd_debug    = -1
      cmd_quit     = -1

      show_continue = !@save_data.empty?
      if show_continue
        commands[cmd_main = commands.length] = _INTL('Continuer')
      else
        commands[cmd_main = commands.length] = _INTL('Nouvelle Partie')
      end

      commands[cmd_options = commands.length]  = _INTL('Options')
      commands[cmd_language = commands.length] = _INTL('Language') if Settings::LANGUAGES.length >= 2
      commands[cmd_debug = commands.length]    = _INTL('Debug') if $DEBUG
      commands[cmd_quit = commands.length]     = _INTL('Quit Game')

      map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
      @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
      @scene.pbSetParty(@save_data[:player]) if show_continue
      @scene.pbStartScene2

      loop do
        command = @scene.pbChoose(commands, -1)
        pbPlayDecisionSE if command != cmd_quit

        case command
        when cmd_main
          @scene.pbEndScene
          if show_continue
            Game.load(@save_data)
          else
            Game.start_new
          end
          return
        when cmd_options
          pbFadeOutIn do
            scene = PokemonOption_Scene.new
            screen = PokemonOptionScreen.new(scene)
            screen.pbStartScreen(true)
          end
        when cmd_language
          @scene.pbEndScene
          $PokemonSystem.language = pbChooseLanguage
          MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
          if show_continue
            @save_data[:pokemon_system] = $PokemonSystem
            File.open(SaveData.get_full_path(@selected_file), "wb") { |file| Marshal.dump(@save_data, file) }
          end
          $scene = pbCallTitle
          return
        when cmd_debug
          pbFadeOutIn { pbDebugMenu(false) }
        when cmd_quit
          pbPlayCloseMenuSE
          @scene.pbEndScene
          $scene = nil
          return
        else
          pbPlayBuzzerSE
        end
      end
    end
  end
end
