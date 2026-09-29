# Two-minute offline autosaves. Online sessions use PEMK::Checkpoint exclusively.
module PeriodicAutosave
  INTERVAL = 120.0
  RETRY_INTERVAL = 60.0
  class << self
    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def writing?; !!@writing; end

    def saved!
      @player = $player
      @due = now + INTERVAL
    end

    def tick
      return if @writing || !$player
      if PEMK::Auth.logged_in?
        @player = nil
        @due = nil
        return
      end
      saved! unless @player.equal?($player)
      return if now < @due
      return unless PEMK::Checkpoint.safe_frame?
      return if Input.respond_to?(:text_input) && Input.text_input
      begin
        @writing = true
        if Game.auto_save
          saved!
          PEMK.log('autosave: local rotating save completed')
        else
          @due = now + RETRY_INTERVAL
          PEMK.log('autosave: local save failed; retry in 60s')
        end
      rescue StandardError => e
        @due = now + RETRY_INTERVAL
        PEMK.log("autosave: #{e.class}: #{e.message}; retry in 60s")
      ensure
        @writing = false
      end
    end
  end

  module SaveAccounting
    def save(*args, **kwargs)
      ok = super
      PeriodicAutosave.saved! if ok && !PEMK::Auth.logged_in?
      ok
    end
  end

  module AtomicWrite
    def save_to_file(path)
      return super unless PeriodicAutosave.writing?
      temporary = path + '.autosave.tmp'
      begin
        super(temporary)
        File.open(temporary, 'rb+') { |file| file.fsync }
        File.rename(temporary, path)
      ensure
        File.delete(temporary) if File.file?(temporary)
      end
    end
  end
end

Game.singleton_class.prepend(PeriodicAutosave::SaveAccounting)
SaveData.singleton_class.prepend(PeriodicAutosave::AtomicWrite)
EventHandlers.add(:on_frame_update, :periodic_offline_autosave,
                  proc { PeriodicAutosave.tick })
