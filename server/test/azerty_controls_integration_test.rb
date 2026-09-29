require 'zlib'
require 'ostruct'
root = File.expand_path(ARGV[0] || '../..', __dir__)
module Input
  DOWN=2; LEFT=4; RIGHT=6; UP=8
  A=11; B=12; C=13; X=14; Y=15; Z=16; L=17; R=18
  ACTION=A; BACK=B; USE=C; JUMPUP=X; JUMPDOWN=Y; SPECIAL=Z; AUX1=L; AUX2=R
  SHIFT=21; CTRL=22; ALT=23; F8=28
  class << self
    attr_accessor :keys, :text_input, :mouse_in_window, :steps
    def update; self.steps = (steps || 0) + 1; end
    def press?(_); false; end
    alias trigger? press?
    alias repeat? press?
    alias release? press?
    def dir4; 0; end
    def dir8; 0; end
    def pressex?(key); (keys || []).include?(key); end
  end
end
module PEMK
  def self.client; nil; end
  module Autopilot
    def self.active?; true; end
  end
end
module System
  def self.adjust_multiplier(*); end
end
class EventScene; end
class ButtonEventScene < EventScene; end
class Scene_Map
  def update; end
end
class Game_Player
  def moving?; false; end
end
def pbMapInterpreterRunning?; false; end
def _INTL(s); s; end
def assert(v, name); raise name unless v; puts "PASS #{name}"; end

# Real virtual input, then real speed hook, then real profile: production order.
load File.join(root, 'Plugins/PEMK/011_Autopilot/002_VirtualInput.rb')
speed = File.read(File.join(root, 'Plugins/Delta Speed Up/_Main_Script.rb'))
input_section = speed[/module Input\n.*?(?=\n#={10,})/m]
raise 'Speed input section missing' unless input_section
eval(input_section, TOPLEVEL_BINDING, 'Delta Speed Up Input')
SPEEDUP_STAGES = [1, 1.5, 2]
$GameSpeed=0; $CanToggle=true
load File.join(root, 'Plugins/AZERTY_ZQSD_Controls/AZERTY_ZQSD_Controls.rb')
def AZERTYControls.focused?; true; end
Input.mouse_in_window=true
$PokemonSystem=OpenStruct.new(only_speedup_battles: 0)
Input.keys=[:F4]; Input.update
assert($GameSpeed == 1, 'F4 changes speed in the same frame')
Input.update
assert($GameSpeed == 1, 'holding F4 does not repeatedly toggle')
Input.keys=[]; Input.update
PEMK::Autopilot::VInput.tap(Input::USE); Input.update
assert(Input.trigger?(Input::USE), 'real virtual input advances through the speed/profile chain')
Input.update
assert(!Input.press?(Input::USE), 'virtual tap releases after one frame')
assert(Input.steps == 5, 'native update runs exactly once per frame')

# Chat rendering, composer and sending are covered by chat_ui_test.rb.
cache = Marshal.load(File.binread(File.join(root, 'Data/PluginScripts.rxdata')))
{ 'AZERTY ZQSD Controls' => 'AZERTY_ZQSD_Controls',
  'PEMK' => 'PEMK', 'Delta Speed Up' => 'Delta Speed Up' }.each do |name, dir|
  entry = cache.find { |p| p[0] == name }
  assert(!entry.nil?, "cache contains #{name}")
  entry[2].each do |path, compressed|
    next unless path.match?(/AZERTY|015_Chat|_Main_Script/)
    actual = Zlib::Inflate.inflate(compressed)
    assert(actual == File.binread(File.join(root, 'Plugins', dir, path)), "cache matches #{path}")
    RubyVM::InstructionSequence.compile(actual.force_encoding('UTF-8'), path)
  end
end
puts 'Integration and compiled-cache checks passed.'
