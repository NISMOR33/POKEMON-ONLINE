require 'minitest/autorun'
require 'tmpdir'
module PEMK
  def self.log(*); end
  module Auth
    def self.logged_in?; $online; end
  end
  module Checkpoint
    def self.safe_frame?; $safe; end
  end
end
module Input
  def self.text_input; $text; end
end
module EventHandlers
  def self.add(*); end
end
module SaveData
  def self.save_to_file(path)
    File.binwrite(path, 'new-save')
    raise IOError, 'simulated disk failure' if $fail
  end
end
module Game
  def self.save(*, **)
    SaveData.save_to_file($save_path)
    true
  end
  def self.auto_save
    $attempts += 1
    save('Auto 1', true)
  end
end
load ARGV.shift || File.expand_path('../../Plugins/Periodic Autosave/Periodic_Autosave.rb', __dir__)
def PeriodicAutosave.now; $clock; end

class PeriodicAutosaveTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir('autosave-test')
    $save_path = File.join(@directory, 'Auto 1.rxdata')
    $player = Object.new
    $clock = 0.0; $online = false; $safe = true; $text = false; $fail = false; $attempts = 0
    PeriodicAutosave.tick
  end
  def teardown
    FileUtils.remove_entry(@directory)
  end
  def test_saves_at_two_minutes_even_without_movement
    $clock = 119; PeriodicAutosave.tick; assert_equal 0, $attempts
    $clock = 120; PeriodicAutosave.tick; assert_equal 1, $attempts
    assert_equal 'new-save', File.binread($save_path)
    100.times { PeriodicAutosave.tick }; assert_equal 1, $attempts
    $clock = 240; PeriodicAutosave.tick; assert_equal 2, $attempts
  end
  def test_defers_unsafe_states_and_text_entry
    $safe = false; $clock = 125; PeriodicAutosave.tick; assert_equal 0, $attempts
    $safe = true; $text = true; PeriodicAutosave.tick; assert_equal 0, $attempts
    $text = false; PeriodicAutosave.tick; assert_equal 1, $attempts
  end
  def test_online_uses_checkpoint_instead_of_local_slots
    $online = true; $clock = 300; PeriodicAutosave.tick; assert_equal 0, $attempts
    $online = false; PeriodicAutosave.tick; assert_equal 0, $attempts
    $clock = 420; PeriodicAutosave.tick; assert_equal 1, $attempts
  end
  def test_failure_keeps_old_save_and_retries_after_cooldown
    File.binwrite($save_path, 'old-save')
    $fail = true; $clock = 120; PeriodicAutosave.tick
    assert_equal 'old-save', File.binread($save_path)
    refute File.exist?($save_path + '.autosave.tmp')
    refute PeriodicAutosave.writing?
    $fail = false; $clock = 179; PeriodicAutosave.tick; assert_equal 1, $attempts
    $clock = 180; PeriodicAutosave.tick; assert_equal 2, $attempts
    assert_equal 'new-save', File.binread($save_path)
  end
  def test_manual_save_postpones_automatic_save
    $clock = 100; Game.save('File A')
    $clock = 120; PeriodicAutosave.tick; assert_equal 0, $attempts
    $clock = 220; PeriodicAutosave.tick; assert_equal 1, $attempts
  end
  def test_new_player_gets_a_fresh_timer
    $clock = 119; $player = Object.new; PeriodicAutosave.tick
    $clock = 120; PeriodicAutosave.tick; assert_equal 0, $attempts
    $clock = 239; PeriodicAutosave.tick; assert_equal 1, $attempts
  end
end
