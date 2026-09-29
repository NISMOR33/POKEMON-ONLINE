# Standalone input regression suite: ruby server/test/azerty_controls_test.rb
require 'ostruct'
require 'zlib'

module Input
  DOWN = 2; LEFT = 4; RIGHT = 6; UP = 8
  ACTION = A = 11; BACK = B = 12; USE = C = 13
  JUMPUP = X = 14; JUMPDOWN = Y = 15; SPECIAL = Z = 16
  AUX1 = L = 17; AUX2 = R = 18; F8 = 28
  class << self
    attr_accessor :keys, :native, :text_input, :mouse_in_window, :steps
    def update; self.steps = (steps || 0) + 1; end
    def pressex?(key); (keys || []).include?(key); end
    def press?(key); (native || []).include?(key); end
    alias trigger? press?
    alias repeat? press?
    alias release? press?
  end
end
class EventScene; end
class ButtonEventScene < EventScene; end
class Scene_Map
  def update; end
end
class Game_Player
  def moving?; false; end
  def jumping?; false; end
  def pbTerrainTag; $terrain; end
end
def pbMapInterpreterRunning?; $interpreter; end
module PEMK
  module Autopilot
    def self.active?; true; end
    module VInput
      class << self
        attr_accessor :held
        def press?(key); (held || []).include?(key); end
        alias trigger? press?
        alias repeat? press?
        def release?(_key); false; end
      end
    end
  end
end

root = File.expand_path('../..', __dir__)
profile = ARGV[0] || File.join(root, 'Plugins/AZERTY_ZQSD_Controls/AZERTY_ZQSD_Controls.rb')
load profile
module AZERTYControls
  class << self
    attr_accessor :test_focus, :test_time
    def focused?; test_focus; end
    def now; test_time; end
  end
end

$checks = 0
def check(name)
  Input.keys = []; Input.native = []; Input.text_input = false
  Input.mouse_in_window = true
  PEMK::Autopilot::VInput.held = []
  AZERTYControls.test_focus = true; AZERTYControls.test_time = 100.0
  AZERTYControls.instance_variables.each do |var|
    next if [:test_focus, :test_time].map { |n| "@#{n}".to_sym }.include?(var)
    AZERTYControls.remove_instance_variable(var)
  end
  $scene = Scene_Map.new; $game_player = Game_Player.new
  $game_temp = OpenStruct.new(in_menu: false, in_battle: false,
                             message_window_showing: false, in_mini_update: false)
  $PokemonGlobal = OpenStruct.new(diving: false, surfing: false, bicycle: false)
  def $PokemonGlobal.forced_movement?; false; end
  $player = OpenStruct.new(has_running_shoes: true)
  $PokemonSystem = OpenStruct.new(runstyle: 0)
  $terrain = OpenStruct.new(must_walk: false); $interpreter = false
  yield
  $checks += 1
  puts "PASS #{name}"
end
def assert(value, message = 'Assertion failed'); raise message unless value; end
def frame(*keys)
  Input.keys = keys
  AZERTYControls.test_time += 0.016
  Input.update
end

check('AZERTY physical Z/Q/S/D produce only movement') do
  { W: Input::UP, A: Input::LEFT, S: Input::DOWN, D: Input::RIGHT }.each do |key, action|
    frame; frame(key)
    assert(Input.dir4 == action)
    [Input::ACTION, Input::SPECIAL, Input::JUMPUP, Input::JUMPDOWN, :chat].each do |other|
      assert(!AZERTYControls.state(:trigger?, other))
    end
  end
end
check('legacy native bindings cannot leak into actions') do
  Input.native = [Input::ACTION, Input::SPECIAL, Input::JUMPUP]
  frame(:W)
  assert(!Input.trigger?(Input::ACTION) && !Input.press?(Input::SPECIAL))
end
check('all secondary keys are available without collisions') do
  { TAB: Input::ACTION, F: Input::SPECIAL, Q: Input::JUMPUP,
    R: Input::JUMPDOWN, F4: Input::AUX1, V: Input::AUX2,
    T: :chat, F1: :help }.each do |key, action|
    frame; frame(key)
    assert(AZERTYControls.state(:trigger?, action))
    assert(Input.dir4 == 0)
  end
end
check('every confirmation alias works') do
  [:E, :RETURN, :SPACE, :C, 1].each do |key|
    frame; frame(key); assert(Input.trigger?(Input::USE))
  end
end
check('right click / Escape open menu only on the overworld') do
  [2, :ESCAPE, :X].each do |key|
    frame; frame(key)
    assert(Input.trigger?(Input::ACTION) && Input.trigger?(Input::BACK))
    $game_temp.in_menu = true
    assert(!Input.trigger?(Input::ACTION) && Input.trigger?(Input::BACK))
    $game_temp.in_menu = false
  end
end
check('Shift runs, cancel does not run, autorun reverses Shift') do
  frame(:LSHIFT); assert($game_player.can_run?)
  assert(!Input.trigger?(Input::ACTION))
  frame(:X); assert(!$game_player.can_run?)
  $PokemonSystem.runstyle = 1
  frame; assert($game_player.can_run?)
  frame(:RSHIFT); assert(!$game_player.can_run?)
end
check('running respects shoes, terrain and event restrictions') do
  frame(:LSHIFT)
  $player.has_running_shoes = false; assert(!$game_player.can_run?)
  $player.has_running_shoes = true; $terrain.must_walk = true; assert(!$game_player.can_run?)
  $terrain.must_walk = false; $interpreter = true; assert(!$game_player.can_run?)
end
check('text input suppresses shortcuts including confirmation and chat') do
  Input.text_input = true; frame(:W, :D, :E, :SPACE, :T, :F, :F4)
  assert(Input.dir4 == 0 && !Input.trigger?(Input::USE))
  assert(!AZERTYControls.state(:trigger?, :chat) && !Input.trigger?(Input::AUX1))
  Input.text_input = false; frame(:W, :E)
  assert(Input.dir4 == 0 && !Input.trigger?(Input::USE))
  frame; frame(:W, :E); assert(Input.dir4 == 8 && Input.trigger?(Input::USE))
end
check('unfocused windows ignore input and require release after refocus') do
  AZERTYControls.test_focus = false; frame(:W, 1)
  assert(Input.dir4 == 0 && !Input.trigger?(Input::USE))
  AZERTYControls.test_focus = true; frame(:W, 1)
  assert(Input.dir4 == 0 && !Input.trigger?(Input::USE))
  frame; frame(:W); assert(Input.dir4 == 8)
end
check('clicks outside the window cannot validate on reentry') do
  Input.mouse_in_window = false; frame(1, 2)
  assert(!Input.trigger?(Input::USE) && !Input.trigger?(Input::BACK))
  Input.mouse_in_window = true; frame(1)
  assert(!Input.trigger?(Input::USE))
  frame; frame(1); assert(Input.trigger?(Input::USE))
end
check('Alt+Enter does not confirm; Ctrl shortcuts do not act') do
  frame(:LALT, :RETURN); assert(!Input.trigger?(Input::USE))
  frame(:RETURN); assert(!Input.trigger?(Input::USE))
  frame; frame(:LCTRL, :E); assert(!Input.trigger?(Input::USE))
end
check('opposite directions cancel and diagonals use newest direction') do
  frame(:W, :S); assert(Input.dir4 == 0 && Input.dir8 == 0)
  frame; frame(:W); frame(:W, :D)
  assert(Input.dir4 == 6 && Input.dir8 == 9)
  frame(:W, :D, :S); assert(Input.dir4 == 6 && Input.dir8 == 6)
end
check('mixed arrow and AZERTY directions share one state') do
  frame(:W, :DOWN); assert(Input.dir4 == 0)
  frame(:W, :RIGHT); assert(Input.dir8 == 9)
end
check('release occurs only after the last alias releases') do
  frame(:E, 1); frame(1)
  assert(Input.press?(Input::USE) && !Input.release?(Input::USE))
  frame; assert(Input.release?(Input::USE))
end
check('repeat uses real time, not accelerated frame count') do
  frame(:S); assert(Input.repeat?(Input::DOWN))
  10.times { frame(:S); assert(!Input.repeat?(Input::DOWN)) }
  AZERTYControls.test_time += 0.4; frame(:S); assert(Input.repeat?(Input::DOWN))
end
check('modal exit consumes held validation key') do
  frame(:E)
  AZERTYControls.modal { assert(!AZERTYControls.overworld?) }
  frame(:E); assert(!Input.trigger?(Input::USE))
  frame; frame(:E); assert(Input.trigger?(Input::USE))
end
check('chat/help are excluded from events, menus, battles and text entry') do
  assert(AZERTYControls.overworld?)
  [:in_menu, :in_battle, :message_window_showing, :in_mini_update].each do |field|
    $game_temp[field] = true; assert(!AZERTYControls.overworld?); $game_temp[field] = false
  end
  $interpreter = true; assert(!AZERTYControls.overworld?)
end
check('virtual input remains usable without physical window focus') do
  AZERTYControls.test_focus = false
  PEMK::Autopilot::VInput.held = [Input::USE, Input::RIGHT]
  frame; assert(Input.trigger?(Input::USE) && Input.dir4 == 6)
end
check('native function keys and update chain are preserved') do
  Input.native = [Input::F8]; before = Input.steps
  frame; assert(Input.trigger?(Input::F8) && Input.steps == before + 1)
end
check('help has four pages and can close without legacy key images') do
  help = ButtonEventScene.allocate
  help.instance_variable_set(:@current_screen, 4)
  scene = OpenStruct.new(disposed: false)
  def scene.dispose; self.disposed = true; end
  help.pbOnScreenEnd(scene)
  assert(scene.disposed && AZERTYControls::HELP.length == 4)
end
puts "#{$checks} regression checks passed."
