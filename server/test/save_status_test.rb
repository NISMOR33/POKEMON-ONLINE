require 'minitest/autorun'
require 'ostruct'
module PEMK
  def self.log(*); end
  module Auth
    def self.logged_in?; $online; end
  end
  module Sync
    def self.push_blob(path = SaveData::FILE_PATH, **); $push; end
  end
  module Checkpoint
    def self.commit(**)
      $observed = SaveStatus.display[0]
      raise IOError if $raise_save
      [$ok, $push]
    end
  end
end
module SaveData; FILE_PATH = 'Game.rxdata'; end
module Game
  def self.save(*)
    $observed = SaveStatus.display[0]
    raise IOError if $raise_save
    $ok
  end
  def self.auto_save; save; end
end
module Graphics
  def self.update; end
  def self.pemk_orig_update; $presented += 1; end
  def self.width; 512; end
end
class Scene_Map; end
class Color
  def initialize(*); end
end
class Bitmap
  attr_reader :font, :width, :height
  def initialize(w,h); @width=w; @height=h; @font = OpenStruct.new; end
  def clear; end
  def fill_rect(*); end
  def draw_text(*); end
  def dispose; @disposed = true; end
  def disposed?; @disposed; end
end
class Sprite
  attr_accessor :bitmap, :x, :y, :z, :visible
  def dispose; @disposed = true; end
  def disposed?; @disposed; end
end
load ARGV.shift || File.expand_path('../../Plugins/Save Status HUD/Save_Status.rb', __dir__)
def SaveStatus.now; $clock; end

class SaveStatusTest < Minitest::Test
  def setup
    $clock = 10.0; $online = false; $push = :pushed; $ok = true
    $raise_save = false; $presented = 0
    $player = OpenStruct.new(last_time_saved: nil)
    $scene = Scene_Map.new; $game_temp = OpenStruct.new(in_battle: false)
    SaveStatus.update
  end
  def test_actual_save_shows_busy_before_write_then_success_and_age
    Game.save
    assert_equal :saving, $observed
    assert_equal 1, $presented
    $clock += 1
    assert_equal :success, SaveStatus.display[0]
    $clock += 64
    assert_equal [:idle, 'Dernière sauvegarde', 'Il y a 1 min'], SaveStatus.display
  end
  def test_nested_autosave_does_not_double_present_or_remain_busy
    Game.auto_save
    assert_equal 1, $presented
    $clock += 1
    assert_equal :success, SaveStatus.display[0]
  end
  def test_failure_keeps_last_success_age
    Game.save; $clock += 20; $ok = false; Game.save
    assert_equal [:error, 'Échec de sauvegarde', 'Il y a 20 s'], SaveStatus.display
  end
  def test_exception_propagates_but_clears_saving_state
    $raise_save = true
    assert_raises(IOError) { Game.save }
    assert_equal :error, SaveStatus.display[0]
    $raise_save = false; Game.save; $clock += 1
    assert_equal :success, SaveStatus.display[0]
  end
  def test_online_local_save_waits_for_successful_deferred_push
    $online = true; $push = :offline
    PEMK::Checkpoint.commit
    $clock += 1
    assert_equal :pending, SaveStatus.display[0]
    $push = :pushed
    PEMK::Sync.push_blob('another-file')
    assert_equal :pending, SaveStatus.display[0]
    PEMK::Sync.push_blob(SaveData::FILE_PATH)
    assert_equal :success, SaveStatus.display[0]
  end
  def test_player_change_resets_status_and_scene_change_disposes_bitmap
    Game.save
    sprite = SaveStatus.instance_variable_get(:@sprite)
    $scene = Object.new; SaveStatus.update
    assert sprite.disposed?
    assert sprite.bitmap.disposed?
    $player = OpenStruct.new(last_time_saved: nil); $scene = Scene_Map.new
    SaveStatus.update
    assert_equal 'Sauvegarde auto active', SaveStatus.display[1]
  end
  def test_loaded_save_has_an_age_without_claiming_a_new_save
    $player = OpenStruct.new(last_time_saved: Time.now - 120)
    SaveStatus.update
    assert_equal :idle, SaveStatus.display[0]
    assert_equal 'Il y a 2 min', SaveStatus.display[2]
  end
end

class SaveStatusTest
  def test_compact_hud_dimensions_and_top_right_position
    sprite = SaveStatus.instance_variable_get(:@sprite)
    assert_equal 108, sprite.bitmap.width
    assert_equal 20, sprite.bitmap.height
    assert_equal Graphics.width - 114, sprite.x
    assert_equal 6, sprite.y
  end
end
