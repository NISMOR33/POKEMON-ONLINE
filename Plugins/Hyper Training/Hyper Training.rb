#===============================================================================
#  Hyper Training Script
#  Credit to Jonas930
#===============================================================================
#  How to Use:
#     pbMrHyper(ITEM1,ITEM2)
#         ITEM1 => the item that you want player use with boosting ONE stats into MAX
#         ITEM2 => the item that you want player use with boosting ALL stats into MAX
#  Example: pbMrHyper(:STARDUST,:STARPIECE)
#===============================================================================

def pbMrHyper(item1, item2)
  @nameitem = [GameData::Item.get(item1).name, GameData::Item.get(item2).name]
  @hasitem  = [$bag.has?(item1), $bag.has?(item2)]
  stat_name = []; stat_id = []
  GameData::Stat.each_main { |s| stat_name.push(s.name_brief); stat_id.push(s.id) }
  pbMessage(_INTL("The name's Mr. Hyper!\nI can help Pokemon do Hyper Training!"))
  if pbConfirmMessage(_INTL("Want to try some of my Hyper Training to boost your Pokemon's stats?"))
    if @hasitem.include?(true)
      if @hasitem == [true, true]
        item = pbMessage(_INTL("Which item would you want to use on Hyper Training?"),[@nameitem[0],@nameitem[1]])
      else
        item = 0 if @hasitem == [true, false]
        item = 1 if @hasitem == [false, true]
      end
      itemuse = (item == 0 ? @nameitem[0] : @nameitem[1])
      if pbConfirmMessage(_INTL("Are you gonna use one \\c[1]{1}\\c[0] for Hyper Training?",itemuse))
        pbMessage(_INTL("Which one of your Pokemon do you want to do some Hyper Training on?"))
        pbChoosePokemon(1,2)
        pokemon = $player.party[pbGet(1)]
        if pbGet(1) < 0
        elsif pokemon.egg?
          pbMessage(_INTL("An Egg?!\nI understand why you're hyped to have one,\nbut I can't train that thing yet!"))
       # elsif pokemon.level != 100
         # pbMessage(_INTL("Oh no...\nNo, no, no!"))
         # pbMessage(_INTL("That Pokemon hasn't leveled up enough to be ready for my amazing Hyper Training!"))
       #   pbMessage(_INTL("Only Lv. 100 Pokemon can handle the hype!"))
        else
          if item == 0
            stat = pbMessage(_INTL("Which one of {1}'s stats do you want to do some Hyper Training on?",pokemon.name),stat_name)
            if pokemon.ivMaxed[stat_id[stat]] == true
              pbMessage(_INTL("But that Pokemon is already so awesome that it doesn't need any training!"))
            else
              pokemon.ivMaxed[stat_id[stat]] = true
              $bag.remove(item1)
              pbMessage(_INTL("Then get hype!"))
              pbMessage(_INTL("Because I'm about to do some real Hyper Training on {1} here!",pokemon.name))
              pbMessage(_INTL("All right!\n{1} got even stronger thanks to my Hyper Training!",pokemon.name))
            end
          elsif item == 1
            if pokemon.ivMaxed.length == 6
              pbMessage(_INTL("But that Pokemon is already so awesome that it doesn't need any training!"))
            else
              stat_id.each { |i| pokemon.ivMaxed[i] = true }
              $bag.remove(item2)
              pbMessage(_INTL("Then get hype!"))
              pbMessage(_INTL("Because I'm about to do some real Hyper Training on {1} here!",pokemon.name))
              pbMessage(_INTL("All right!\n{1} got even stronger thanks to my Hyper Training!",pokemon.name))
            end
          end
        end
      end
    else
      pbMessage(_INTL("Oh no...\nNo, no, no!"))
      pbMessage(_INTL("You don't have any {1} or {2}!\nNot even one!",@nameitem[0],@nameitem[1]))
    end
  end
  pbMessage(_INTL("Then come back anytime!\nMr. Hyper will always be hyped up to see you!"))
end