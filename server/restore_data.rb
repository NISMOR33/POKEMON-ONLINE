# frozen_string_literal: true

puts "================================================="
puts "🔄 Restauration immédiate des fichiers Data du jeu (Git)..."
puts "================================================="

res1 = system('git checkout -- "Data/"')
res2 = system('git checkout -- Game.rxdata')

puts "✅ Restauration terminée ! Résultat Data: #{res1}, Game: #{res2}"

