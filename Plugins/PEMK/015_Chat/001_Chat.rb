#===============================================================================
# PEMK :: Chat UI
#===============================================================================
module PEMK
  module Chat
    @messages = []
    @hud_window = nil
    @speech_bubbles = {}
    @last_msg_time = 0

    def self.init_hud
      dispose_hud
      @hud_window = Sprite_ChatHUD.new
      @speech_bubbles = {}
    end

    def self.dispose_hud
      @hud_window.dispose if @hud_window && !@hud_window.disposed?
      @hud_window = nil
      @speech_bubbles.each_value { |s| s.dispose if s && !s.disposed? }
      @speech_bubbles.clear
    end

    def self.update
      if !@hud_window || @hud_window.disposed?
        @hud_window = Sprite_ChatHUD.new
        @hud_window.refresh
      end
      @hud_window.update

      update_speech_bubbles
      
      if Input.trigger?(Input::SPECIAL)
        open_chat_input
      end
    end

    def self.open_chat_input
      text = pbMessageFreeText(_INTL("Chat:"), "", false, 150)
      if text && !text.empty?
        c = PEMK.client
        if c
          c.send_message({ type: :chat, text: text }) if c.respond_to?(:send_message)
        end
      end
    end

    def self.on_message(msg)
      from = msg[:from]
      text = msg[:text]
      return unless text

      name = "Unknown"
      
      if from == PEMK.self_id
        name = $player ? $player.name : "Me"
        show_speech_bubble(:local, $game_player, text) if $game_player
      elsif from
        rp = nil
        if defined?(PEMK::Remotes) && PEMK::Remotes.respond_to?(:players)
          rp = PEMK::Remotes.players[from]
        elsif defined?(PEMK::World) && PEMK::World.respond_to?(:entities)
          rp = PEMK::World.entities[from]
        end
        if rp
          name = rp.respond_to?(:player_name) ? rp.player_name : rp.name
          show_speech_bubble(from, rp, text)
        end
      end
      
      name = msg[:name] if msg[:name] 
      
      @messages.push({name: name, text: text})
      @messages.shift if @messages.size > 7
      @last_msg_time = System.uptime rescue Graphics.frame_count
      @hud_window.refresh if @hud_window && !@hud_window.disposed?
    end

    def self.show_speech_bubble(key, character, text)
      return unless character
      s = @speech_bubbles[key]
      s.dispose if s && !s.disposed?
      viewport = ($scene.is_a?(Scene_Map) ? ($scene.spriteset.viewport1 rescue nil) : nil)
      @speech_bubbles[key] = Sprite_SpeechBubble.new(viewport, character, text)
    end
    
    def self.update_speech_bubbles
      @speech_bubbles.each do |key, sprite|
        if sprite.disposed?
          @speech_bubbles.delete(key)
        else
          sprite.update
          if sprite.finished
            sprite.dispose
            @speech_bubbles.delete(key)
          end
        end
      end
    end
    
    def self.last_msg_time
      @last_msg_time
    end
  end
end

class Sprite_ChatHUD < Sprite
  def initialize
    super(nil)
    self.x = 4
    self.y = Graphics.height - 180
    self.z = 99999
    self.bitmap = Bitmap.new(300, 160)
    pbSetSmallFont(self.bitmap) rescue nil
  end

  def name_color(name)
    hash = name.hash.abs
    r = 150 + (hash % 100)
    g = 150 + ((hash / 100) % 100)
    b = 150 + ((hash / (100 * 100)) % 100)
    return Color.new(r, g, b)
  end

  def update
    super
    # Fade out after 10 seconds (approx 400 frames)
    now = System.uptime rescue Graphics.frame_count
    diff = now - PEMK::Chat.last_msg_time
    
    # Diff could be in seconds or frames depending on System.uptime vs Graphics.frame_count
    # Let's assume frames if it's large, seconds if small.
    # To be safe, let's just use Graphics.frame_count explicitly
    @last_fc ||= Graphics.frame_count
    
    diff_frames = Graphics.frame_count - (PEMK::Chat.instance_variable_get(:@last_fc_msg) || 0)
    
    if diff_frames > 400
      self.opacity -= 10 if self.opacity > 0
    else
      self.opacity = 255
    end
  end

  def refresh
    self.bitmap.clear if self.bitmap
    PEMK::Chat.instance_variable_set(:@last_fc_msg, Graphics.frame_count)
    self.opacity = 255
    
    messages = PEMK::Chat.instance_variable_get(:@messages)
    return if messages.empty?
    
    # Calculate required height
    line_h = 20
    req_h = messages.size * line_h + 8
    req_w = 300
    
    self.y = Graphics.height - req_h - 4
    self.bitmap.fill_rect(0, 0, req_w, req_h, Color.new(0, 0, 0, 120))
    
    y_offset = 4
    messages.each do |msg|
      name_str = "[#{msg[:name]}]"
      text_str = msg[:text]
      color = name_color(msg[:name])
      
      self.bitmap.font.color = color
      self.bitmap.draw_text(4, y_offset, req_w, line_h, name_str)
      name_w = self.bitmap.text_size(name_str).width
      
      self.bitmap.font.color = Color.new(255,255,255)
      self.bitmap.draw_text(4 + name_w + 6, y_offset, req_w - name_w - 10, line_h, text_str)
      
      y_offset += line_h
    end
  end
end

class Sprite_SpeechBubble < Sprite
  attr_reader :finished
  def initialize(viewport, character, text)
    super(viewport)
    @character = character; @text = text; @timer = 180; @finished = false
    
    temp_bmp = Bitmap.new(1, 1)
    pbSetSystemFont(temp_bmp) rescue nil
    temp_bmp.font.size = 20
    
    max_w = 180
    words = text.split(" ")
    lines = []
    current_line = ""
    words.each do |w|
      test_line = current_line.empty? ? w : current_line + " " + w
      if temp_bmp.text_size(test_line).width > max_w
        lines << current_line unless current_line.empty?
        current_line = w
      else
        current_line = test_line
      end
    end
    lines << current_line unless current_line.empty?
    
    longest = lines.map { |l| temp_bmp.text_size(l).width }.max || 32
    temp_bmp.dispose

    padding_x = 8
    padding_y = 6
    w = longest + (padding_x * 2)
    h = (lines.size * 22) + (padding_y * 2)
    w = 32 if w < 32

    self.bitmap = Bitmap.new(w, h + 8)
    pbSetSystemFont(self.bitmap) rescue nil
    self.bitmap.font.size = 20
    
    bg = Color.new(250, 250, 250, 230)
    bd = Color.new(30, 30, 30, 255)
    
    # Outer border
    self.bitmap.fill_rect(1, 0, w - 2, h, bd)
    self.bitmap.fill_rect(0, 1, w, h - 2, bd)
    # Inner background
    self.bitmap.fill_rect(1, 1, w - 2, h - 2, bg)
    
    # Tail
    self.bitmap.fill_rect(w / 2 - 4, h, 8, 2, bd)
    self.bitmap.fill_rect(w / 2 - 3, h, 6, 2, bg)
    self.bitmap.fill_rect(w / 2 - 2, h + 2, 4, 2, bd)
    self.bitmap.fill_rect(w / 2 - 1, h + 2, 2, 2, bg)
    self.bitmap.fill_rect(w / 2 - 1, h + 4, 2, 2, bd)

    # Draw Text standard way (no shadow artifact)
    self.bitmap.font.color = Color.new(20, 20, 20)
    y_pos = padding_y - 2
    lines.each do |line|
      # center text manually
      lw = self.bitmap.text_size(line).width
      self.bitmap.draw_text((w - lw)/2, y_pos, lw, 22, line)
      y_pos += 22
    end
    
    self.ox = w / 2
    self.oy = h + 8 + 32
    self.z = 99999
    update_position
  end
  def update_position
    return unless @character
    self.x = @character.screen_x; self.y = @character.screen_y - 24
  end
  def update
    super; update_position
    @timer -= 1; @finished = true if @timer <= 0
  end
end

module PEMK
  module Dispatch
    class << self
      unless method_defined?(:chat_original_handle)
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
end

class Scene_Map
  unless method_defined?(:pokemmo_chat_orig_scene_update)
    alias_method :pokemmo_chat_orig_scene_update, :update
    def update
      PEMK::Chat.update
      pokemmo_chat_orig_scene_update
    end
  end
  
  if method_defined?(:terminate)
    unless method_defined?(:pokemmo_chat_orig_scene_terminate)
      alias_method :pokemmo_chat_orig_scene_terminate, :terminate
      def terminate
        PEMK::Chat.dispose_hud
        pokemmo_chat_orig_scene_terminate
      end
    end
  end

  if method_defined?(:end)
    unless method_defined?(:pokemmo_chat_orig_scene_end)
      alias_method :pokemmo_chat_orig_scene_end, :end
      def end
        PEMK::Chat.dispose_hud
        pokemmo_chat_orig_scene_end
      end
    end
  end
end
