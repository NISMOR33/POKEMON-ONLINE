# Emerald chat: compact history, integrated composer and bounded speech bubbles.
module PEMK
  module Chat
    HISTORY_LIMIT = 80
    MAX_TEXT = 150
    @messages = []
    @speech_bubbles = {}
    @last_msg_time = -100.0
    @revision = 0
    @scroll = 0
    @draft = ''

    class << self
      attr_reader :messages, :last_msg_time, :revision, :scroll, :draft, :notice
      def now; Process.clock_gettime(Process::CLOCK_MONOTONIC); end
      def composing?; !!@composing; end
      def connected?
        c = PEMK.client
        c && c.respond_to?(:connected?) && c.connected?
      end

      def init_hud
        dispose_hud
        @hud_window = Sprite_ChatHUD.new
      end

      def dispose_hud
        @hud_window.dispose if @hud_window && !@hud_window.disposed?
        @hud_window = nil
        @speech_bubbles.each_value { |sprite| sprite.dispose unless sprite.disposed? }
        @speech_bubbles.clear
      end

      def context!
        if !@session_player.equal?($player)
          dispose_hud
          @session_player = $player
          @messages.clear
          @draft = ''; @scroll = 0; @notice = nil
          @last_msg_time = -100.0; @revision += 1
        end
        map = $game_map ? $game_map.map_id : nil
        if @map != map
          @speech_bubbles.each_value { |sprite| sprite.dispose unless sprite.disposed? }
          @speech_bubbles.clear
          @map = map
        end
      end

      def unobstructed?
        $scene.is_a?(Scene_Map) && $game_temp && !$game_temp.in_battle &&
          (composing? || (!$game_temp.in_menu && !$game_temp.message_window_showing))
      end

      def update
        context!
        return unless $scene.is_a?(Scene_Map)
        @hud_window = Sprite_ChatHUD.new if !@hud_window || @hud_window.disposed?
        @hud_window.update
        update_speech_bubbles
        if defined?(AZERTYControls) && AZERTYControls.overworld? &&
           AZERTYControls.state(:trigger?, :chat)
          open_chat_input
        end
      end

      def open_chat_input
        return if composing?
        return unless defined?(AZERTYControls) && AZERTYControls.overworld?
        @composing = true; @scroll = 0; @notice = nil; @revision += 1
        begin
          AZERTYControls.modal { compose_text }
        ensure
          @composing = false
          @last_msg_time = now
          @revision += 1
          @hud_window.refresh if @hud_window && !@hud_window.disposed?
        end
      end

      def compose_text
        entry = Window_TextEntry_Keyboard.new(@draft, 12, Graphics.height - 94,
                                              Graphics.width - 110, 64)
        entry.maxlength = MAX_TEXT
        entry.opacity = 0
        entry.z = 100_002
        entry.instance_variable_set(:@baseColor, Color.new(235, 245, 243))
        entry.instance_variable_set(:@shadowColor, Color.new(18, 34, 44))
        entry.contents.font.name = 'Arial'
        entry.contents.font.size = 16
        entry.refresh
        previous_text_mode = Input.text_input
        Input.text_input = true
        Input.gets # Do not insert the T which opened the composer.
        loop do
          Graphics.update
          Input.update
          if Input.triggerex?(:ESCAPE)
            @draft = entry.text
            break
          end
          entry.update
          @draft = entry.text
          if Input.triggerex?(:PAGEUP)
            @scroll = [@scroll + 1, [@messages.length - 1, 0].max].min
            @revision += 1
          elsif Input.triggerex?(:PAGEDOWN)
            @scroll = [@scroll - 1, 0].max
            @revision += 1
          elsif Input.triggerex?(:RETURN)
            break if submit(@draft)
          end
          update
        end
      ensure
        Input.text_input = previous_text_mode unless previous_text_mode.nil?
        entry.dispose if entry && !entry.disposed?
        Input.update
      end

      def submit(text)
        text = clean(text, MAX_TEXT)
        return false if text.empty?
        unless connected?
          @notice = 'Hors ligne : message conservé.'
          @revision += 1
          return false
        end
        result = PEMK.client.send_message({ type: :chat, text: text })
        if result == false
          @notice = 'Envoi impossible. Réessaie avec Entrée.'
          @revision += 1
          return false
        end
        @draft = ''
        true # Display only the server echo, never a misleading local duplicate.
      rescue StandardError
        @notice = 'Envoi impossible. Ton texte est conservé.'
        @revision += 1
        false
      end

      def clean(value, limit)
        value.to_s.gsub(/[\x00-\x1f\x7f]/, ' ').gsub(/\s+/, ' ').strip.each_char.take(limit).join
      end

      def on_message(msg)
        context!
        text = clean(msg[:text], MAX_TEXT)
        return if text.empty?
        from = msg[:from]
        local = from && from == PEMK.self_id
        character = local ? $game_player : (PEMK::Remotes.players[from] if defined?(PEMK::Remotes))
        fallback = local && $player ? $player.name : (character.player_name if character && character.respond_to?(:player_name))
        name = clean(msg[:name] || fallback || 'Dresseur', 24)
        name = 'Dresseur' if name.empty?
        @messages << { name: name, text: text, time: Time.now.strftime('%H:%M'), local: !!local }
        @messages.shift while @messages.length > HISTORY_LIMIT
        @scroll = [@scroll + 1, @messages.length - 1].min if @scroll > 0
        @last_msg_time = now; @revision += 1
        show_speech_bubble(local ? :local : from, character, text, name) if character && $scene.is_a?(Scene_Map)
        @hud_window.refresh if @hud_window && !@hud_window.disposed?
      end

      def show_speech_bubble(key, character, text, name = 'Dresseur')
        old = @speech_bubbles.delete(key)
        old.dispose if old && !old.disposed?
        @speech_bubbles[key] = Sprite_SpeechBubble.new(nil, character, text, name)
      end

      def update_speech_bubbles
        @speech_bubbles.keys.each do |key|
          sprite = @speech_bubbles[key]
          gone = key != :local && defined?(PEMK::Remotes) && !PEMK::Remotes.players.key?(key)
          sprite.update unless sprite.disposed? || gone
          if gone || sprite.disposed? || sprite.finished
            sprite.dispose unless sprite.disposed?
            @speech_bubbles.delete(key)
          end
        end
      end
    end
  end

  module ChatStyle
    module_function
    def color(*rgba); Color.new(*rgba); end
    def font(bitmap, size = 14, tint = color(225, 236, 239), bold = false)
      bitmap.font.name = 'Arial'; bitmap.font.size = size
      bitmap.font.bold = bold; bitmap.font.color = tint
    end
    def panel(bitmap, x, y, width, height, fill, border)
      bitmap.fill_rect(x + 3, y, width - 6, height, border)
      bitmap.fill_rect(x, y + 3, width, height - 6, border)
      bitmap.fill_rect(x + 4, y + 1, width - 8, height - 2, fill)
      bitmap.fill_rect(x + 1, y + 4, width - 2, height - 8, fill)
    end
    def icon(bitmap, x, y, tint)
      bitmap.fill_rect(x, y, 13, 9, tint)
      bitmap.fill_rect(x + 2, y + 9, 3, 3, tint)
      bitmap.fill_rect(x + 3, y + 3, 7, 1, color(20, 37, 46))
      bitmap.fill_rect(x + 3, y + 5, 5, 1, color(20, 37, 46))
    end
    def name_color(name)
      palette = [[106, 221, 180], [130, 195, 244], [228, 192, 119], [191, 171, 235]]
      color(*palette[name.each_codepoint.reduce(0) { |hash, n| (hash * 31 + n) % 65536 } % palette.length])
    end
    def ellipsis(bitmap, text, width)
      return text if bitmap.text_size(text).width <= width
      chars = text.each_char.to_a
      chars.pop while !chars.empty? && bitmap.text_size(chars.join + '…').width > width
      chars.join + '…'
    end
    def wrap(bitmap, text, width)
      lines = []; line = ''
      text.split(/\s+/).each do |word|
        candidate = line.empty? ? word : "#{line} #{word}"
        if bitmap.text_size(candidate).width <= width
          line = candidate
          next
        end
        lines << line unless line.empty?
        line = ''
        word.each_char do |char|
          if !line.empty? && bitmap.text_size(line + char).width > width
            lines << line; line = ''
          end
          line += char
        end
      end
      lines << line unless line.empty?
      lines.empty? ? [''] : lines
    end
  end
end

class Sprite_ChatHUD < Sprite
  def initialize
    super(nil)
    self.z = 100_000
    refresh
  end

  def update
    super
    chat = PEMK::Chat
    self.visible = chat.composing? && chat.unobstructed?
    signature = [chat.revision, chat.composing?, chat.draft, chat.connected?,
                 (chat.now - chat.last_msg_time > 12), Graphics.width, Graphics.height]
    if signature != @signature
      @signature = signature
      refresh
    end
  end

  def refresh
    chat = PEMK::Chat; style = PEMK::ChatStyle
    expanded = chat.composing?
    self.visible = expanded && chat.unobstructed?
    return unless expanded
    compact = !expanded && (chat.messages.empty? || chat.now - chat.last_msg_time > 12)
    width = expanded ? Graphics.width - 24 : (compact ? 188 : 300)
    height = expanded ? [Graphics.height - 90, 294].min : (compact ? 30 : 156)
    if !self.bitmap || self.bitmap.width != width || self.bitmap.height != height
      self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
      self.bitmap = Bitmap.new(width, height)
    end
    b = self.bitmap; b.clear
    self.x = 12; self.y = Graphics.height - height - 12
    style.panel(b, 0, 0, width, height, style.color(16, 31, 42, 238), style.color(58, 93, 101, 245))
    style.icon(b, 11, 10, style.color(108, 222, 179))
    style.font(b, 12, style.color(196, 220, 222), true)
    b.draw_text(33, 4, 150, 22, compact ? 'T   DISCUSSION' : 'DISCUSSION')
    return if compact
    style.font(b, 11, style.color(144, 168, 177))
    b.draw_text(width - 154, 4, 142, 22, chat.connected? ? 'EN LIGNE' : 'HORS LIGNE', 2)
    b.fill_rect(10, 30, width - 20, 1, style.color(47, 69, 79))
    bottom = expanded ? height - 93 : height - 24
    available = bottom - 39
    rows = []
    ending = chat.messages.length - chat.scroll
    chat.messages.first(ending).reverse_each do |message|
      style.font(b, 14)
      lines = style.wrap(b, message[:text], width - 26)
      unless expanded
        lines = lines.first(2)
        lines[-1] = style.ellipsis(b, lines[-1] + '…', width - 26) if style.wrap(b, message[:text], width - 26).length > 2
      end
      row_height = 19 + lines.length * 17 + 9
      break if row_height > available
      rows.unshift([message, lines, row_height]); available -= row_height
    end
    y = 39
    rows.each do |message, lines, row_height|
      style.font(b, 12, style.name_color(message[:name]), true)
      name = message[:local] ? "#{message[:name]} · vous" : message[:name]
      b.draw_text(13, y, width - 77, 17, style.ellipsis(b, name, width - 77))
      style.font(b, 10, style.color(130, 153, 164))
      b.draw_text(width - 54, y, 40, 17, message[:time], 2)
      style.font(b, 14)
      lines.each_with_index { |line, i| b.draw_text(13, y + 19 + i * 17, width - 26, 18, line) }
      y += row_height
    end
    if rows.empty?
      style.font(b, 14, style.color(152, 180, 184))
      b.draw_text(13, 47, width - 26, 22, 'Un bonjour, une rencontre, une aventure.')
    end
    if expanded
      style.panel(b, 10, height - 76, width - 20, 42, style.color(10, 23, 33), style.color(76, 143, 132))
      if chat.draft.empty?
        style.font(b, 14, style.color(135, 162, 170))
        b.draw_text(23, height - 66, width - 104, 23, 'Écris ton message...')
      end
      style.font(b, 11, style.color(128, 174, 166))
      b.draw_text(width - 67, height - 63, 44, 20, "#{chat.draft.length}/150", 2)
      style.font(b, 11, style.color(164, 189, 192))
      b.draw_text(13, height - 29, width - 26, 22, 'Entrée  envoyer    Échap  fermer    Pg préc./suiv.  historique')
      style.font(b, 11, style.color(228, 190, 119))
      b.draw_text(13, height - 96, width - 26, 19, chat.notice || (chat.scroll > 0 ? 'Historique · Pg suiv. pour revenir aux messages récents' : ''))
    else
      style.font(b, 11, style.color(137, 177, 171))
      b.draw_text(13, height - 24, width - 26, 19, 'T  Écrire / ouvrir l’historique')
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

class Sprite_SpeechBubble < Sprite
  attr_reader :finished
  def initialize(viewport, character, text, name = 'Dresseur')
    super(nil)
    @character = character
    @born = PEMK::Chat.now
    @duration = [[3.5 + text.length * 0.045, 5.0].max, 10.0].min
    @finished = false
    style = PEMK::ChatStyle
    measure = Bitmap.new(1, 1)
    style.font(measure, 14)
    lines = style.wrap(measure, text, 202)
    if lines.length > 4
      lines = lines.first(4)
      lines[-1] = style.ellipsis(measure, lines[-1] + '…', 202)
    end
    width = [[lines.map { |line| measure.text_size(line).width }.max + 26, 132].max, 228].min
    height = 31 + lines.length * 18
    measure.dispose
    self.bitmap = Bitmap.new(width + 3, height + 10)
    b = self.bitmap
    style.panel(b, 2, 3, width, height, style.color(6, 18, 24, 85), style.color(6, 18, 24, 45))
    style.panel(b, 0, 0, width, height, style.color(249, 248, 234, 250), style.color(72, 116, 104))
    b.fill_rect(10, 9, 3, 10, style.color(61, 161, 127))
    style.font(b, 11, style.color(46, 105, 89), true)
    b.draw_text(18, 5, width - 28, 18, style.ellipsis(b, name, width - 28))
    style.font(b, 14, style.color(31, 51, 55))
    lines.each_with_index { |line, i| b.draw_text(12, 25 + i * 18, width - 24, 19, line) }
    b.fill_rect(width / 2 - 5, height - 1, 10, 3, style.color(72, 116, 104))
    b.fill_rect(width / 2 - 3, height + 2, 6, 2, style.color(72, 116, 104))
    b.fill_rect(width / 2 - 1, height + 4, 2, 2, style.color(72, 116, 104))
    self.z = 80_000
    update
  end

  def update
    super
    age = PEMK::Chat.now - @born
    @finished = age >= @duration
    self.opacity = (255 * [[age / 0.15, 1.0].min, [(@duration - age) / 0.5, 0.0].max].min).to_i.clamp(0, 255)
    cx = @character.screen_x; cy = @character.screen_y
    self.visible = PEMK::Chat.unobstructed? && cx.between?(0, Graphics.width) && cy.between?(0, Graphics.height + 32)
    self.x = (cx - self.bitmap.width / 2).clamp(6, [Graphics.width - self.bitmap.width - 6, 6].max)
    self.y = (cy - 42 - self.bitmap.height).clamp(6, [Graphics.height - self.bitmap.height - 8, 6].max)
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

module PEMK
  module Dispatch
    class << self
      alias_method :chat_original_handle, :handle
      def handle(msg)
        if msg.is_a?(Hash) && msg[:type] == :chat
          Chat.on_message(msg)
        else
          chat_original_handle(msg)
        end
      end
    end
  end
end

class Scene_Map
  alias_method :pokemmo_chat_orig_scene_update, :update
  def update
    PEMK::Chat.update
    pokemmo_chat_orig_scene_update
  end
end

# Scene_Map has no guaranteed terminate callback. Dispose also on other scenes.
module PEMKChatSceneCleanup
  def update(*args)
    PEMK::Chat.dispose_hud unless $scene.is_a?(Scene_Map)
    super
  end
end
Graphics.singleton_class.prepend(PEMKChatSceneCleanup)
