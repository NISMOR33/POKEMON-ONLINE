require 'minitest/autorun'
require 'ostruct'
require 'json'
class Color
  attr_reader :rgba
  def initialize(*rgba); @rgba = rgba; @rgba << 255 if @rgba.length == 3; end
end
class Bitmap
  attr_reader :width, :height, :font, :ops
  def initialize(w, h)
    @width = w; @height = h; @ops = []
    @font = OpenStruct.new(name: 'Arial', size: 14, bold: false, color: Color.new(255,255,255))
  end
  def text_size(text)
    OpenStruct.new(width: text.each_char.sum { |c| c == ' ' ? font.size * 0.28 : font.size * 0.56 }.ceil)
  end
  def fill_rect(*args); @ops << ['rect', *args[0,4], args[4].rgba]; end
  def draw_text(x,y,w,h,text,align=0)
    @ops << ['text',x,y,w,h,text,align,font.size,font.bold,font.color.rgba]
  end
  def clear; @ops.clear; end
  def dispose; @disposed = true; end
  def disposed?; !!@disposed; end
end
class Sprite
  attr_accessor :bitmap, :x, :y, :z, :visible, :opacity
  def initialize(*); @x = @y = 0; @visible = true; @opacity = 255; end
  def update; end
  def dispose; @disposed = true; end
  def disposed?; !!@disposed; end
end
module Graphics
  def self.width; 512; end
  def self.height; 384; end
  def self.update; end
end
class Scene_Map
  def update; end
end
module PEMK
  def self.self_id; 1; end
  def self.client; $client; end
  module Remotes
    def self.players; $remotes; end
  end
  module Dispatch
    def self.handle(*); :other; end
  end
end
module AZERTYControls
  def self.overworld?; false; end
end
module Input
  class << self
    attr_accessor :text_input, :events
    def gets; ''; end
    def update; @event = (events || []).shift; end
    def triggerex?(key); @event == key; end
  end
end
class Window_TextEntry_Keyboard
  attr_accessor :text, :maxlength, :opacity, :z
  attr_reader :contents
  def initialize(text, *); @text = text; @contents = Bitmap.new(300,40); end
  def update; end
  def refresh; end
  def dispose; @contents.dispose; @disposed = true; end
  def disposed?; @disposed; end
end

load ARGV.shift || File.expand_path('../../Plugins/PEMK/015_Chat/001_Chat.rb', __dir__)
PEMK::Chat.define_singleton_method(:now) { $clock }

class ChatUITest < Minitest::Test
  def setup
    $clock = 50.0; $remotes = {}
    $player = OpenStruct.new(name: 'Alex')
    $game_player = OpenStruct.new(screen_x: 256, screen_y: 210)
    $game_map = OpenStruct.new(map_id: 1)
    $game_temp = OpenStruct.new(in_battle: false, in_menu: false, message_window_showing: false)
    $scene = Scene_Map.new
    $client = OpenStruct.new(connected?: true, sent: [])
    def $client.send_message(data); sent << data; true; end
    PEMK::Chat.instance_variable_set(:@composing, false)
    PEMK::Chat.context!
  end
  def teardown; PEMK::Chat.dispose_hud; end
  def receive(text='On se retrouve devant le Centre Pokémon ?', from=2, name='Léa')
    PEMK::Chat.on_message(from: from, name: name, text: text)
  end
  def test_text_wraps_including_long_words_without_overflow
    bitmap = Bitmap.new(1,1)
    PEMK::ChatStyle.font(bitmap,14)
    ['Bonjour à tous !', 'a' * 150, 'Émeraude ' * 20].each do |text|
      lines = PEMK::ChatStyle.wrap(bitmap,text,202)
      assert lines.all? { |line| bitmap.text_size(line).width <= 202 }
      assert_equal text.gsub(/\s/,'').chars, lines.join.gsub(/\s/,'').chars
    end
  end
  def test_history_is_bounded_and_control_characters_are_removed
    85.times { receive("Salut\n\x00tout le monde #{'x'*160}") }
    assert_equal 80, PEMK::Chat.messages.length
    assert PEMK::Chat.messages.all? { |m| m[:text].length <= 150 && !m[:text].match?(/[\x00-\x1f]/) }
  end
  def test_sending_does_not_add_a_duplicate_and_offline_keeps_draft
    PEMK::Chat.instance_variable_set(:@draft,'Salut !')
    assert PEMK::Chat.submit('Salut !')
    assert_equal [{type: :chat, text: 'Salut !'}], $client.sent
    assert_empty PEMK::Chat.messages
    $client.define_singleton_method(:connected?) { false }
    PEMK::Chat.instance_variable_set(:@draft,'Toujours là ?')
    refute PEMK::Chat.submit('Toujours là ?')
    assert_equal 'Toujours là ?', PEMK::Chat.draft
    assert_includes PEMK::Chat.notice, 'Hors ligne'
  end
  def test_bubble_is_bounded_and_expires_in_real_seconds
    bubble = Sprite_SpeechBubble.new(nil,OpenStruct.new(screen_x: 3,screen_y: 4),'W'*150,'Un pseudo vraiment très long')
    assert_operator bubble.bitmap.width, :<=, 231
    assert_operator bubble.bitmap.height, :<=, 113
    assert_operator bubble.x, :>=, 6
    assert_operator bubble.y, :>=, 6
    2000.times { bubble.update }
    refute bubble.finished
    $clock += 11; bubble.update; assert bubble.finished
    bitmap=bubble.bitmap; bubble.dispose; assert bitmap.disposed?
  end
  def test_composer_sends_with_enter_and_restores_text_mode
    PEMK::Chat.instance_variable_set(:@draft,'Bonjour tout le monde')
    Input.text_input = false; Input.events = [:RETURN]
    PEMK::Chat.compose_text
    assert_equal 'Bonjour tout le monde', $client.sent.last[:text]
    refute Input.text_input
    assert_equal '', PEMK::Chat.draft
  end
  def test_composer_escape_preserves_draft_without_sending
    PEMK::Chat.instance_variable_set(:@draft,'Message à finir')
    Input.text_input = false; Input.events = [:ESCAPE]
    PEMK::Chat.compose_text
    assert_empty $client.sent
    assert_equal 'Message à finir', PEMK::Chat.draft
    refute Input.text_input
  end
  def test_map_change_and_departed_players_remove_bubbles
    $remotes[2]=OpenStruct.new(screen_x: 100,screen_y: 120)
    receive
    bubbles=PEMK::Chat.instance_variable_get(:@speech_bubbles)
    sprite=bubbles[2]; $remotes.clear; PEMK::Chat.update_speech_bubbles
    assert sprite.disposed?
    receive('Bonjour',1,'Alex')
    sprite=bubbles[:local]; $game_map.map_id=2; PEMK::Chat.context!
    assert sprite.disposed?
  end
  def test_hud_collapses_and_hides_behind_dialogues
    receive
    hud=Sprite_ChatHUD.new
    refute hud.visible
    $clock += 13; hud.update
    refute hud.visible
    $game_temp.message_window_showing=true; hud.update
    refute hud.visible
    hud.dispose
  end
  def test_preview_and_composer_fit_game_resolution
    receive('Salut ! Quelqu’un pour explorer la Route 110 ?',2,'Léa')
    receive('Oui, je te rejoins au Centre Pokémon.',1,'Alex')
    hud=Sprite_ChatHUD.new
    refute hud.visible # No idle chip, panel or notification, even after receiving a message.
    PEMK::Chat.instance_variable_set(:@composing,true)
    hud.refresh
    assert_equal 488,hud.bitmap.width
    assert_equal 294,hud.bitmap.height
    save_preview('chat-composer',hud)
    bubble=Sprite_SpeechBubble.new(nil,$game_player,'Oui, je te rejoins au Centre Pokémon.','Alex')
    $clock += 0.2; bubble.update
    save_preview('chat-bubble',bubble)
    bubble.dispose; hud.dispose
  end
  def save_preview(name,sprite)
    return unless ENV['CHAT_PREVIEW_DIR']
    data={width:512,height:384,sprites:[{x:sprite.x,y:sprite.y,width:sprite.bitmap.width,height:sprite.bitmap.height,ops:sprite.bitmap.ops}]}
    File.write(File.join(ENV['CHAT_PREVIEW_DIR'],name+'.json'),JSON.generate(data))
  end
end
