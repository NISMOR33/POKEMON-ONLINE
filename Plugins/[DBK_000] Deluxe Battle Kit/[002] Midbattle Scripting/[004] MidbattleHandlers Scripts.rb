#===============================================================================
# Hardcoded Midbattle Scripts
#===============================================================================
# You may add Midbattle Handlers here to create custom battle scripts you can
# call on. Unlike other methods of creating battle scripts, you can use these
# handlers to freely hardcode what you specifically want to happen in battle
# instead of the other methods which require specific values to be inputted.
#
# This method requires fairly solid scripting knowledge, so it isn't recommended
# for inexperienced users. As with other methods of calling midbattle scripts,
# you may do so by setting up the "midbattleScript" battle rule.
#
# 	For example:  
#   setBattleRule("midbattleScript", :demo_capture_tutorial)
#
#   *Note that the symbol entered must be the same as the symbol that appears as
#    the second argument in each of the handlers below. This may be named whatever
#    you wish.
#-------------------------------------------------------------------------------

################################################################################
# Demo scenario vs. wild Rotom that shifts forms.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_wild_rotom,
  proc { |battle, idxBattler, idxTarget, trigger|
    foe = battle.battlers[1]
    logname = _INTL("{1} ({2})", foe.pbThis(true), foe.index)
    case trigger
    #---------------------------------------------------------------------------
    # The player's Poke Balls are disabled at the start of the first round.
    when "RoundStartCommand_1_foe"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("{1} emited a powerful magnetic pulse!", foe.pbThis))
      battle.pbAnimation(:CHARGE, foe, foe)
      pbSEPlay("Anim/Paralyze3")
      battle.pbDisplayPaused(_INTL("Your Poké Balls short-circuited!\nThey cannot be used this battle!"))
      battle.disablePokeBalls = true
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # After taking Super Effective damage, the opponent changes form each round.
    when "RoundEnd_foe"
      next if !battle.pbTriggerActivated?("TargetWeakToMove_foe")
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbAnimation(:NIGHTMARE, foe.pbDirectOpposing(true), foe)
      form = battle.pbRandom(1..5)
      foe.pbSimpleFormChange(form, _INTL("{1} possessed a new appliance!", foe.pbThis))
      foe.pbRecoverHP(foe.totalhp / 4)
      foe.pbCureAttract
      foe.pbCureConfusion
      foe.pbCureStatus
      if foe.ability_id != :MOTORDRIVE
        battle.pbShowAbilitySplash(foe, true, false)
        foe.ability = :MOTORDRIVE
        battle.pbReplaceAbilitySplash(foe)
        battle.pbDisplay(_INTL("{1} acquired {2}!", foe.pbThis, foe.abilityName))
        battle.pbHideAbilitySplash(foe)
      end
      if foe.item_id != :CELLBATTERY
        foe.item = :CELLBATTERY
        battle.pbDisplay(_INTL("{1} equipped a {2} it found in the appliance!", foe.pbThis, foe.itemName))
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent gains various effects when its HP falls to 50% or lower.
    when "TargetHPHalf_foe"
      next if battle.pbTriggerActivated?(trigger)
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbAnimation(:CHARGE, foe, foe)
      if foe.effects[PBEffects::Charge] <= 0
        foe.effects[PBEffects::Charge] = 5
        battle.pbDisplay(_INTL("{1} began charging power!", foe.pbThis))
      end
      if foe.effects[PBEffects::MagnetRise] <= 0
        foe.effects[PBEffects::MagnetRise] = 5
        battle.pbDisplay(_INTL("{1} levitated with electromagnetism!", foe.pbThis))
      end
      battle.pbStartTerrain(foe, :Electric)
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent paralyzes the player's Pokemon when taking Super Effective damage.
    when "UserMoveEffective_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("{1} emited an electrical pulse out of desperation!", foe.pbThis))
      battler = battle.battlers[idxBattler]
      if battler.pbCanInflictStatus?(:PARALYSIS, foe, true)
        battler.pbInflictStatus(:PARALYSIS)
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    end
  }
)


################################################################################
# Demo scenario vs. Rocket Grunt in a collapsing cave.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_collapsing_cave,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Introduction text explaining the event.
    when "RoundStartCommand_1_foe"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("The cave ceiling begins to crumble down all around you!"))
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("I am not letting you escape!"))
      battle.pbDisplayPaused(_INTL("I don't care if this whole cave collapses down on the both of us...haha!"))
      scene.pbForceEndSpeech
      battle.pbDisplayPaused(_INTL("Defeat your opponent before time runs out!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Repeated end-of-round text.
    when "RoundEnd_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("The cave continues to collapse all around you!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Player's Pokemon is struck by falling rock, dealing damage & causing confusion.
    when "RoundEnd_2_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("{1} was struck on the head by a falling rock!", battler.pbThis))
      battle.pbAnimation(:ROCKSMASH, battler.pbDirectOpposing(true), battler)
      old_hp = battler.hp
      battler.hp -= (battler.totalhp / 4).round
      scene.pbHitAndHPLossAnimation([[battler, old_hp, 0]])
      if battler.fainted?
        battler.pbFaint(true)
      elsif battler.pbCanConfuse?(battler, false)
        battler.pbConfuse
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Warning message.
    when "RoundEnd_3_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("You're running out of time!"))
      battle.pbDisplayPaused(_INTL("You need to escape immediately!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Player runs out of time and is forced to forfeit.
    when "RoundEnd_4_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("You failed to defeat your opponent in time!"))
      scene.pbRecall(idxBattler)
      battle.pbDisplayPaused(_INTL("You were forced to flee the battle!"))
      pbSEPlay("Battle flee")
      battle.decision = 3
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent's Pokemon stands its ground when its HP is low.
    when "LastTargetHPLow_foe"
      next if battle.pbTriggerActivated?(trigger)
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("My {1} will never give up!", battler.name))
      scene.pbForceEndSpeech
      battle.pbAnimation(:BULKUP, battler, battler)
      battler.displayPokemon.play_cry
      battler.pbRecoverHP(battler.totalhp / 2)
      battle.pbDisplayPaused(_INTL("{1} is standing its ground!", battler.pbThis))
      showAnim = true
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStage(stat, 2, battler, showAnim)
        showAnim = false
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent mocks the player when forfeiting the match.
    when "BattleEndForfeit"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Haha...you'll never make it out alive!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    end
  }
)


#===============================================================================
# Global Midbattle Scripts
#===============================================================================
# Global midbattle scripts are always active and will affect all battles as long
# as the conditions for the scripts are met. These are not set in a battle rule,
# and are instead triggered passively in any battle.
#-------------------------------------------------------------------------------

################################################################################
# Used for wild Mega battles.
################################################################################

MidbattleHandlers.add(:midbattle_global, :wild_mega_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle?
    next if battle.wildBattleMode != :mega
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    #---------------------------------------------------------------------------
    # Mega Evolves wild battler immediately at the start of the first round.
    when "RoundStartCommand_1_foe"
      if battle.pbCanMegaEvolve?(foe.index)
	    PBDebug.log("[Midbattle Global] #{logname} will Mega Evolve")
        battle.pbMegaEvolve(foe.index)
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 20
      else
        battle.wildBattleMode = nil
      end
    #---------------------------------------------------------------------------
    # Un-Mega Evolves wild battler once damage cap is reached.
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached")
      foe.unMega
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("{1}'s Mega Evolution faded!\nIt may now be captured!", foe.pbThis))
    #---------------------------------------------------------------------------
    # Tracks player's win count.
    when "BattleEndWin"
      if battle.wildBattleMode == :mega
        $stats.wild_mega_battles_won += 1
      end
    end
  }
)


################################################################################
# Plays low HP music when the player's Pokemon reach critical health.
################################################################################

MidbattleHandlers.add(:midbattle_global, :low_hp_music,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !Settings::PLAY_LOW_HP_MUSIC
    battler = battle.battlers[idxBattler]
    next if !battler || !battler.pbOwnedByPlayer?
    track = battle.pbGetBattleLowHealthBGM
    next if !track.is_a?(RPG::AudioFile)
    playingBGM = battle.playing_bgm
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "BattlerHPRecovered_player"
      next if playingBGM != track.name
      next if battle.pbAnyBattlerLowHP?(idxBattler)
      battle.pbResumeBattleBGM
      PBDebug.log("[Midbattle Global] low HP music ended")
    #---------------------------------------------------------------------------
    # Restores original BGM when battler is fainted.
    when "BattlerHPReduced_player"
      next if playingBGM != track.name
      next if battle.pbAnyBattlerLowHP?(idxBattler)
      next if !battler.fainted?
      battle.pbResumeBattleBGM
      PBDebug.log("[Midbattle Global] low HP music ended")
    #---------------------------------------------------------------------------
    # Plays low HP music when HP is critical.
    when "BattlerHPCritical_player"
      next if playingBGM == track.name
      battle.pbPauseAndPlayBGM(track)
      PBDebug.log("[Midbattle Global] low HP music begins")
    #---------------------------------------------------------------------------
    # Restores original BGM when sending out a healthy Pokemon.
    # Plays low HP music when sending out a Pokemon with critical HP.
    when "AfterSendOut_player"
      if battle.pbAnyBattlerLowHP?(idxBattler)
        next if playingBGM == track.name
        battle.pbPauseAndPlayBGM(track)
        PBDebug.log("[Midbattle Global] low HP music begins")
      elsif playingBGM == track.name
        battle.pbResumeBattleBGM
        PBDebug.log("[Midbattle Global] low HP music ended")
      end
    end
  }
)

################################################################################
# Universal midbattle script that plays "Victory Lies Before You!"
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :roxanne_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro: only once, round 1 -------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_rox_intro_done) && battle.instance_variable_get(:@_rox_intro_done)
        battle.instance_variable_set(:@_rox_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I'll show you what I learned from the Pokémon Trainer's School!"))
        scene.pbForceEndSpeech
      end

    # --- First foe faint only (not player faint), only once -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?   # ignore player-side faints
      # mark that a foe faint happened in this battle
      battle.instance_variable_set(:@_rox_foe_fainted_any, true)

      unless battle.instance_variable_defined?(:@_rox_first_faint_done) && battle.instance_variable_get(:@_rox_first_faint_done)
        battle.instance_variable_set(:@_rox_first_faint_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("You're skilled, that's for sure. But I ain't done yet!"))
        scene.pbForceEndSpeech
      end

    # --- Before last Pokémon: play BGM + line, only once ----------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_rox_foe_fainted_any)

      # guard 2: only when foe actually has exactly 1 able mon left
      foe_party = battle.pbParty(1)                # foe side party (single battle)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_rox_last_msg_done) && battle.instance_variable_get(:@_rox_last_msg_done)
        battle.instance_variable_set(:@_rox_last_msg_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("You've backed me and my team into a corner, but it's not over just yet!"))
        scene.pbForceEndSpeech
      end

    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("You may challenge me again. Anytime!"))
      scene.pbForceEndSpeech
    end
  }
)


MidbattleHandlers.add(:midbattle_scripts, :brawly_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro: only once, round 1 -------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_braw_intro_done) && battle.instance_variable_get(:@_braw_intro_done)
        battle.instance_variable_set(:@_braw_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I hope your ready, because I'm going to surf my way to victory!"))
        scene.pbForceEndSpeech
      end

    # --- First foe faint only (not player faint), only once -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?   # ignore player-side faints
      # mark that a foe faint has happened this battle
      battle.instance_variable_set(:@_braw_foe_fainted_any, true)

      unless battle.instance_variable_defined?(:@_braw_first_faint_done) && battle.instance_variable_get(:@_braw_first_faint_done)
        battle.instance_variable_set(:@_braw_first_faint_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Whoa, wow! Your making a much bigger splash than I expected!"))
        scene.pbForceEndSpeech
      end

    # --- Before last Pokémon: play BGM + line, only once ----------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe has fainted
      next unless battle.instance_variable_get(:@_braw_foe_fainted_any)

      # Guard 2: only when foe actually has exactly 1 able Pokémon left
      foe_party = battle.pbParty(1)                       # foe side (single battle)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_braw_last_msg_done) && battle.instance_variable_get(:@_braw_last_msg_done)
        battle.instance_variable_set(:@_braw_last_msg_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("The world awaits me as the next big wave! I can't lose here!"))
        scene.pbForceEndSpeech
      end

    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("The one making a big wave is me! I'm going to keep on riding that wave!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :wattson_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]   # who triggered this

    case trigger
    # --- Intro: only once, round 1 -------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_watt_intro_done) && battle.instance_variable_get(:@_watt_intro_done)
        battle.instance_variable_set(:@_watt_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("One must never throw a match. Even I must not."))
        scene.pbForceEndSpeech
        # Set Electric Terrain at the start (like your :terrain => :Electric)
        battle.pbStartTerrain(battle.battlers[1], :Electric)
      end

    # --- Track that at least one foe has fainted (for last-mon gating) -------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_watt_foe_fainted_any, true)

    # --- Final Pokémon moment: BGM + line + +2 DEF / +2 SP.DEF ---------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted (prevents firing at start)
      next unless battle.instance_variable_get(:@_watt_foe_fainted_any)

      # Guard 2: only when foe truly has exactly 1 able Pokémon left
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_watt_last_done) && battle.instance_variable_get(:@_watt_last_done)
        battle.instance_variable_set(:@_watt_last_done, true)
        # Music
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        # Line
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Get shocked by the electricity of my final Pokémon!"))
        scene.pbForceEndSpeech
        # Buff the current foe battler (active slot 1)
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("You got electrified!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :flannery_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro speech --------------------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_flannery_intro_done) && battle.instance_variable_get(:@_flannery_intro_done)
        battle.instance_variable_set(:@_flannery_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("With skills inherited from my grandfather, who was once one of the Elite Four, I'm going to demonstrate the hot moves I honed close to a volcano!"))
        scene.pbForceEndSpeech
      end

    # --- Track that at least one foe has fainted -----------------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_flannery_foe_fainted_any, true)

    # --- Final Pokémon cue ---------------------------------------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: must have lost at least one Pokémon already
      next unless battle.instance_variable_get(:@_flannery_foe_fainted_any)
      # Guard 2: ensure it's really the final Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_flannery_last_done) && battle.instance_variable_get(:@_flannery_last_done)
        battle.instance_variable_set(:@_flannery_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Haiyaaaaaaaaa!"))
        scene.pbForceEndSpeech
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss dialogue -------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("I... I won! I guess my well-honed moves worked!"))
      scene.pbForceEndSpeech
    end
  }
)


#Norman
MidbattleHandlers.add(:midbattle_scripts, :norman_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_norman_intro_done) && battle.instance_variable_get(:@_norman_intro_done)
        battle.instance_variable_set(:@_norman_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I will do everything in my power as a Trainer to win. You'd better give it your best shot, too!"))
        scene.pbForceEndSpeech
      end

    # --- Track that at least one foe has fainted ------------------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_norman_foe_fainted_any, true)

    # --- Final Pokémon cue: BGM + line (only once, true last-mon) ------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: must have lost at least one Pokémon already
      next unless battle.instance_variable_get(:@_norman_foe_fainted_any)
      # Guard 2: ensure it's really the final Pokémon
      foe_party = battle.pbParty(1)                         # foe side party (single battle)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_norman_last_done) && battle.instance_variable_get(:@_norman_last_done)
        battle.instance_variable_set(:@_norman_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Show me your power one final time!"))
        scene.pbForceEndSpeech
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("I am truly dissapointed in you."))
      scene.pbForceEndSpeech
    end
  }
)


#Winona
MidbattleHandlers.add(:midbattle_scripts, :winona_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_winona_intro_done) && battle.instance_variable_get(:@_winona_intro_done)
        battle.instance_variable_set(:@_winona_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Witness the elegant choreography of my Pokémon and I!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_winona_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_winona_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_winona_last_done) && battle.instance_variable_get(:@_winona_last_done)
        battle.instance_variable_set(:@_winona_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Our elegant dance is not finished yet!"))
        scene.pbForceEndSpeech
        # +2 DEF / +2 Sp.Def to Winona's active battler
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("..."))
      scene.pbForceEndSpeech
    end
  }
)

#Juan
MidbattleHandlers.add(:midbattle_scripts, :juan_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_juan_intro_done) && battle.instance_variable_get(:@_juan_intro_done)
        battle.instance_variable_set(:@_juan_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Please, you shall bear witness to our artistry. A grand illusion of water sculpted by Pokémon and myself!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_juan_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_juan_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_juan_last_done) && battle.instance_variable_get(:@_juan_last_done)
        battle.instance_variable_set(:@_juan_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("We aren't done yet!"))
        scene.pbForceEndSpeech
        # +2 DEF / +2 Sp.Def to Juan's active battler
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("..."))
      scene.pbForceEndSpeech
    end
  }
)

#Tate and Liza
MidbattleHandlers.add(:midbattle_scripts, :twins_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_twins_intro_done) && battle.instance_variable_get(:@_twins_intro_done)
        battle.instance_variable_set(:@_twins_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Heh heh heh... Are you ready to face the fearsome power of us twins?"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for gating) ----------------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_twins_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line (only once) --------------------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"
      next unless battle.instance_variable_get(:@_twins_foe_fainted_any)
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_twins_last_done) && battle.instance_variable_get(:@_twins_last_done)
        battle.instance_variable_set(:@_twins_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("It can't be helped. This is it!"))
        scene.pbForceEndSpeech
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("That's our twin power!"))
      scene.pbForceEndSpeech
    end
  }
)


#Zinnia
MidbattleHandlers.add(:midbattle_scripts, :zinnia_1_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro: only once, at round start ------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_zinnia_intro_done) && battle.instance_variable_get(:@_zinnia_intro_done)
        battle.instance_variable_set(:@_zinnia_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Let's see who deserves the shard!"))
        scene.pbForceEndSpeech
      end

    # --- Track first foe faint ------------------------------------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_zinnia_foe_fainted_any, true)

    # --- Final Pokémon trigger: BGM + line + +2 DEF/SP.DEF --------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"
      next unless battle.instance_variable_get(:@_zinnia_foe_fainted_any)
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_zinnia_last_done) && battle.instance_variable_get(:@_zinnia_last_done)
        battle.instance_variable_set(:@_zinnia_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I still have one final chance to prove myself worthy. It's not over yet!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def for her last Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("..."))
      scene.pbForceEndSpeech
    end
  }
)

#Zinnia Final postgame fight
MidbattleHandlers.add(:midbattle_scripts, :zinnia_final_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_zinniaf_intro_done) && battle.instance_variable_get(:@_zinniaf_intro_done)
        battle.instance_variable_set(:@_zinniaf_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Show me what it means to be a successor!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_zinniaf_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + (optional) +2 DEF/SP.DEF -----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_zinniaf_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_zinniaf_last_done) && battle.instance_variable_get(:@_zinniaf_last_done)
        battle.instance_variable_set(:@_zinniaf_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("This is my last dance!"))
        scene.pbForceEndSpeech

        # (Optional) buff Zinnia's last Pokémon like other leaders
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line (optional) -------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("..."))
      scene.pbForceEndSpeech
    end
  }
)


#Zinnia Sky Pillar
MidbattleHandlers.add(:midbattle_scripts, :zinnia_2_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_zinnia2_intro_done) && battle.instance_variable_get(:@_zinnia2_intro_done)
        battle.instance_variable_set(:@_zinnia2_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I will show RAYQUAZA why I am it's master!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_zinnia2_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_zinnia2_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_zinnia2_last_done) && battle.instance_variable_get(:@_zinnia2_last_done)
        battle.instance_variable_set(:@_zinnia2_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I still have one final chance to prove myself worthy. It's not over yet!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Zinnia's active battler
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("As I thought. I am the chosen one!"))
      scene.pbForceEndSpeech
    end
  }
)


#Wallace
MidbattleHandlers.add(:midbattle_scripts, :wallace_gym_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_wallace_intro_done) && battle.instance_variable_get(:@_wallace_intro_done)
        battle.instance_variable_set(:@_wallace_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("You have overcome challenges and made it this far because you worked as one with your Pokémon. Show me that strength here and now!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_wallace_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_wallace_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_wallace_last_done) && battle.instance_variable_get(:@_wallace_last_done)
        battle.instance_variable_set(:@_wallace_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("This is our last chance. Let's do this!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Wallace's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("..."))
      scene.pbForceEndSpeech
    end
  }
)

#Sidney
MidbattleHandlers.add(:midbattle_scripts, :sidney_elite_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_sidney_intro_done) && battle.instance_variable_get(:@_sidney_intro_done)
        battle.instance_variable_set(:@_sidney_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("With the strength you've gained, we can battle with no holds barred! !"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_sidney_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_sidney_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_sidney_last_done) && battle.instance_variable_get(:@_sidney_last_done)
        battle.instance_variable_set(:@_sidney_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I knew you were strong. Show me more!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Sidney's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Challenge us again anytime!"))
      scene.pbForceEndSpeech
    end
  }
)

#Phoebe
MidbattleHandlers.add(:midbattle_scripts, :phoebe_elite_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_phoebe_intro_done) && battle.instance_variable_get(:@_phoebe_intro_done)
        battle.instance_variable_set(:@_phoebe_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Ahaha! I've been waiting for you! I'm bringing a little something new to the table this time! Prepare yourself and bring it on!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_phoebe_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_phoebe_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_phoebe_last_done) && battle.instance_variable_get(:@_phoebe_last_done)
        battle.instance_variable_set(:@_phoebe_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Hmmp. No way! My final Pokémon?"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Phoebe's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Hmmp, what a shame. You lost."))
      scene.pbForceEndSpeech
    end
  }
)

#Glacia
MidbattleHandlers.add(:midbattle_scripts, :glacia_elite_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_glacia_intro_done) && battle.instance_variable_get(:@_glacia_intro_done)
        battle.instance_variable_set(:@_glacia_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Welcome. Now let's get started!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_glacia_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_glacia_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_glacia_last_done) && battle.instance_variable_get(:@_glacia_last_done)
        battle.instance_variable_set(:@_glacia_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("You and your Pokémon... How fiercely your spirits burn!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Glacia's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Hmmph... I won this time."))
      scene.pbForceEndSpeech
    end
  }
)

#Drake
MidbattleHandlers.add(:midbattle_scripts, :drake_elite_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Opening line ---------------------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_drake_intro_done) && battle.instance_variable_get(:@_drake_intro_done)
        battle.instance_variable_set(:@_drake_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("I am the strongest of the Pokémon League Elite Four. Show me what you've got!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint -----------------------------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_drake_foe_fainted_any, true)

    # --- Final Pokémon event --------------------------------------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Require at least one faint
      next unless battle.instance_variable_get(:@_drake_foe_fainted_any)

      # Check if truly on last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      # Only run once
      unless battle.instance_variable_defined?(:@_drake_last_done) && battle.instance_variable_get(:@_drake_last_done)
        battle.instance_variable_set(:@_drake_last_done, true)

        battle.pbPauseAndPlayBGM("Victory Lies Before You!")

        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("You deserve every credit for coming this far as a Pokémon Trainer. Try to finish me off!"))
        scene.pbForceEndSpeech

        # Apply +2 DEF / +2 Sp.Def to Drake’s final Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Drake wins / "loss" from player's perspective ------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Superb, but I still won today!"))
      scene.pbForceEndSpeech
    end
  }
)


#Battle Frontier Bosses
#Cynthia
MidbattleHandlers.add(:midbattle_scripts, :cynthia_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_cynthia_intro_done) && battle.instance_variable_get(:@_cynthia_intro_done)
        battle.instance_variable_set(:@_cynthia_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Let's see if Aiden was right about you..."))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_cynthia_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_cynthia_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_cynthia_last_done) && battle.instance_variable_get(:@_cynthia_last_done)
        battle.instance_variable_set(:@_cynthia_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("This is it! I won't go down easy though!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Cynthia's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line ------------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("To bad... I guess Aiden was wrong about you after all..."))
      scene.pbForceEndSpeech
    end
  }
)



#Leon
MidbattleHandlers.add(:midbattle_scripts, :leon_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_leon_intro_done) && battle.instance_variable_get(:@_leon_intro_done)
        battle.instance_variable_set(:@_leon_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Let's see if you have the makings of a champion!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_leon_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Guard 1: only after at least one foe fainted
      next unless battle.instance_variable_get(:@_leon_foe_fainted_any)
      # Guard 2: foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_leon_last_done) && battle.instance_variable_get(:@_leon_last_done)
        battle.instance_variable_set(:@_leon_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("This is it. I can feel my heart racing!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Leon's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Loss line (player loses) ---------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("You're getting there. Just a bit more training!"))
      scene.pbForceEndSpeech
    end
  }
)


#Wally Frontier battle
MidbattleHandlers.add(:midbattle_scripts, :pokemon_master_wally_1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_pmw1_intro_done) && battle.instance_variable_get(:@_pmw1_intro_done)
        battle.instance_variable_set(:@_pmw1_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Are you ready? It's time for you to face my Ultimate Team!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon logic) --------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_pmw1_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + stat boosts ------------------------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Only after at least one faint
      next unless battle.instance_variable_get(:@_pmw1_foe_fainted_any)

      # Foe truly down to last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_pmw1_last_done) && battle.instance_variable_get(:@_pmw1_last_done)
        battle.instance_variable_set(:@_pmw1_last_done, true)

        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("It's not over just yet. Watch and you will see!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def for Wally's last Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Player loses ---------------------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("I did it? I actually beat you!"))
      scene.pbForceEndSpeech
    end
  }
)

#Gladion
MidbattleHandlers.add(:midbattle_scripts, :gladion_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_gladion_intro_done) && battle.instance_variable_get(:@_gladion_intro_done)
        battle.instance_variable_set(:@_gladion_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Silvally, let's win this together!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_gladion_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Only once we've actually KO'd something
      next unless battle.instance_variable_get(:@_gladion_foe_fainted_any)

      # Make sure he’s really on his last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_gladion_last_done) && battle.instance_variable_get(:@_gladion_last_done)
        battle.instance_variable_set(:@_gladion_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("You have shown how strong you are, but it's not over just yet!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Gladion's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Player loses (Gladion wins) ------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("You were WEAKER than I could have imagined. Don't talk to me again!"))
      scene.pbForceEndSpeech
    end
  }
)

#Brandon
MidbattleHandlers.add(:midbattle_scripts, :brandon_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene   = battle.scene
    battler = battle.battlers[idxBattler]

    case trigger
    # --- Intro (once, round 1) -----------------------------------------------
    when "RoundStartCommand_1_foe"
      unless battle.instance_variable_defined?(:@_brandon_intro_done) && battle.instance_variable_get(:@_brandon_intro_done)
        battle.instance_variable_set(:@_brandon_intro_done, true)
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Show me your power, young explorer!"))
        scene.pbForceEndSpeech
      end

    # --- Track at least one foe faint (for last-mon gating) -------------------
    when "BattlerFainted", "BattlerFainted_foe"
      next if !battler || battler.pbOwnedByPlayer?
      battle.instance_variable_set(:@_brandon_foe_fainted_any, true)

    # --- Final Pokémon: BGM + line + +2 DEF/SP.DEF (only once) ----------------
    when "BeforeLastSwitchIn", "BeforeLastSwitchIn_foe",
         "AfterLastSwitchIn",  "AfterLastSwitchIn_foe",
         "AfterLastSendOut",   "AfterLastSendOut_foe"

      # Only after at least one foe fainted
      next unless battle.instance_variable_get(:@_brandon_foe_fainted_any)

      # Make sure he's really on his last Pokémon
      foe_party = battle.pbParty(1)
      alive_foe = foe_party.count { |p| p && p.able? }
      next unless alive_foe == 1

      unless battle.instance_variable_defined?(:@_brandon_last_done) && battle.instance_variable_get(:@_brandon_last_done)
        battle.instance_variable_set(:@_brandon_last_done, true)
        battle.pbPauseAndPlayBGM("Victory Lies Before You!")
        scene.pbStartSpeech(1)
        battle.pbDisplayPaused(_INTL("Hahahah! Remarkable! Yes, it's grand, indeed!"))
        scene.pbForceEndSpeech

        # +2 DEF / +2 Sp.Def to Brandon's active Pokémon
        foe_battler = battle.battlers[1]
        if foe_battler && !foe_battler.fainted?
          showAnim = true
          [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
            if foe_battler.pbCanRaiseStatStage?(stat, foe_battler)
              foe_battler.pbRaiseStatStage(stat, 2, foe_battler, showAnim)
              showAnim = false
            end
          end
        end
      end

    # --- Player loses (Brandon wins) ------------------------------------------
    when "BattleEndLoss"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Hey! Don't give up now! Get up! Don't lose faith in yourself!"))
      scene.pbForceEndSpeech
    end
  }
)




