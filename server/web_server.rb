# frozen_string_literal: true

require "socket"
require "json"

#===============================================================================
# PEMK MMO Web Server — Live GTS & Online Players Web Dashboard
# Zero Gem Dependency — Synchronizes Live Game Listings & Connected Players
#===============================================================================

PORT = 4567
ROOT_DIR = File.expand_path("../", __dir__)

DB = begin
  require "sequel"
  env_db_url = ENV["DATABASE_URL"] || "postgres://postgres:postgres@localhost:5432/pemk_dev"
  Sequel.connect(env_db_url)
rescue LoadError
  puts "[Web Server] Note: Gem 'sequel' non disponible. Sync Fichier Actif."
  nil
rescue StandardError => e
  puts "[Web Server] Note DB: (#{e.message}). Sync Fichier Actif."
  nil
end

HTML_PAGE = <<~HTML
  <!DOCTYPE html>
  <html lang="fr">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pokémon Eternal Emerald MMO — Portail Live</title>
    <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
      body { font-family: 'Plus Jakarta Sans', sans-serif; }
      .emerald-gradient { background: linear-gradient(135deg, #059669 0%, #10b981 50%, #047857 100%); }
    </style>
  </head>
  <body class="bg-slate-950 text-slate-100 min-h-screen pb-12 antialiased">
    <header class="border-b border-slate-800 bg-slate-900/80 backdrop-blur-md sticky top-0 z-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl emerald-gradient flex items-center justify-center text-white font-bold text-xl shadow-lg">⚡</div>
          <div>
            <h1 class="font-extrabold text-lg tracking-tight text-white flex items-center gap-2">
              Pokémon Eternal Emerald <span class="px-2 py-0.5 text-xs font-semibold uppercase bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 rounded-md">MMO Live Portal</span>
            </h1>
            <p class="text-xs text-slate-400">Serveur Web Live • Synchronisé au Jeu en Temps Réel</p>
          </div>
        </div>
        <div class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-950/60 border border-emerald-500/30 text-emerald-400 text-xs font-semibold">
          <span class="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
          Serveur Web Live Port 4567
        </div>
      </div>
    </header>

    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-8">
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-5">
        <div class="p-5 rounded-2xl bg-slate-900/60 border border-slate-800 flex items-center gap-4">
          <div class="w-12 h-12 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center text-2xl">🏪</div>
          <div>
            <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Annonces GTS en Direct</p>
            <p class="text-2xl font-bold text-white mt-0.5" id="count-gts">0</p>
          </div>
        </div>
        <div class="p-5 rounded-2xl bg-slate-900/60 border border-slate-800 flex items-center gap-4">
          <div class="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center text-2xl">👥</div>
          <div>
            <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Joueurs Connectés</p>
            <p class="text-2xl font-bold text-white mt-0.5" id="count-players">0</p>
          </div>
        </div>
        <div class="p-5 rounded-2xl bg-slate-900/60 border border-slate-800 flex items-center gap-4">
          <div class="w-12 h-12 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center text-2xl">📡</div>
          <div>
            <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Statut API Live</p>
            <p class="text-2xl font-bold text-emerald-400 mt-0.5">Connecté (Sync 2s)</p>
          </div>
        </div>
      </div>

      <!-- Section 1: Joueurs Connectés -->
      <section class="space-y-4">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-bold text-white flex items-center gap-2">👥 Joueurs Connectés en Jeu</h2>
        </div>
        <div class="bg-slate-900/40 border border-slate-800 rounded-2xl overflow-hidden shadow-sm" id="players-container">
          <div class="p-6 text-center text-slate-500">Chargement des joueurs en ligne...</div>
        </div>
      </section>

      <!-- Section 2: Annonces GTS -->
      <section class="space-y-4">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-bold text-white flex items-center gap-2">🏪 Annonces du GTS (Marché Live)</h2>
          <button onclick="loadData()" class="px-3 py-1.5 rounded-lg bg-slate-900 border border-slate-800 hover:border-slate-700 text-xs font-semibold text-slate-300">🔄 Rafraîchir</button>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5" id="gts-container">
          <div class="col-span-full py-8 text-center text-slate-500">Chargement des annonces GTS...</div>
        </div>
      </section>
    </main>

    <script>
      async function loadData() {
        try {
          // 1. Charger les annonces GTS
          const resGts = await fetch('/api/gts');
          const dataGts = await resGts.json();
          document.getElementById('count-gts').textContent = dataGts.length;

          const gtsContainer = document.getElementById('gts-container');
          gtsContainer.innerHTML = '';

          if (dataGts.length === 0) {
            gtsContainer.innerHTML = '<div class="col-span-full py-12 text-center text-slate-500 bg-slate-900/40 rounded-2xl border border-slate-800"><p class="text-xl mb-2">🏪</p><p>Aucune annonce active sur le marché actuellement.</p><p class="text-xs mt-1 text-slate-600">Postez une annonce en jeu dans le GTS pour la voir apparaître ici en direct !</p></div>';
          } else {
            dataGts.forEach(item => {
              let payload = {};
              try { payload = typeof item.data_json === 'string' ? JSON.parse(item.data_json) : (item.data_json || {}); } catch(e) {}
              const isPkmn = (item.listing_type || '').includes('poke') || (item.title || '').includes('Niv.');

              const card = document.createElement('div');
              card.className = 'bg-slate-900/60 border border-slate-800 rounded-2xl p-5 relative flex flex-col justify-between shadow-sm hover:border-slate-700 transition-all';
              card.innerHTML = `
                <div>
                  <div class="flex items-start justify-between gap-3 mb-3">
                    <div class="w-12 h-12 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-center text-2xl">
                      ${isPkmn ? '🔴' : '🎒'}
                    </div>
                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full ${isPkmn ? 'bg-blue-500/10 text-blue-400 border border-blue-500/30' : 'bg-amber-500/10 text-amber-400 border border-amber-500/30'}">
                      ${isPkmn ? 'Pokémon' : 'Objet'}
                    </span>
                  </div>
                  <h3 class="font-bold text-white text-base tracking-tight mb-1">${item.title || 'Annonce'}</h3>
                  <p class="text-xs text-slate-400 mb-2">Vendeur : <span class="text-slate-200 font-medium">${item.seller_name || 'Joueur'}</span></p>
                  ${payload && payload.hp ? `<p class="text-xs text-emerald-400 mb-3">PV : ${payload.hp} / ${payload.totalhp}</p>` : ''}
                </div>
                <div class="pt-3 border-t border-slate-800 flex items-center justify-between">
                  <div>
                    <p class="text-xs text-slate-500">Prix de vente</p>
                    <p class="text-lg font-extrabold text-amber-400">${Number(item.price || 0).toLocaleString()} $</p>
                  </div>
                  <span class="text-xs font-semibold text-emerald-400 flex items-center gap-1">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span> En vente
                  </span>
                </div>
              `;
              gtsContainer.appendChild(card);
            });
          }

          // 2. Charger les Joueurs Connectés
          const resPlayers = await fetch('/api/players');
          const dataPlayers = await resPlayers.json();
          document.getElementById('count-players').textContent = dataPlayers.length;

          const pContainer = document.getElementById('players-container');
          pContainer.innerHTML = '';

          if (dataPlayers.length === 0) {
            pContainer.innerHTML = '<div class="p-6 text-center text-slate-500">Aucun joueur actuellement connecté.</div>';
          } else {
            const listDiv = document.createElement('div');
            listDiv.className = 'divide-y divide-slate-800/60';
            dataPlayers.forEach(p => {
              const row = document.createElement('div');
              row.className = 'px-6 py-4 flex items-center justify-between hover:bg-slate-900/40 transition-colors';
              row.innerHTML = `
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-center text-xl">
                    🧢
                  </div>
                  <div>
                    <div class="flex items-center gap-2">
                      <p class="font-bold text-white text-sm">${p.name || 'Dresseur'}</p>
                      <span class="px-2 py-0.5 text-[10px] font-bold rounded bg-slate-800 text-slate-300 border border-slate-700">Niv. ${p.level || 50}</span>
                    </div>
                    <p class="text-xs text-slate-400 mt-0.5">📍 ${p.location || 'Bourg-en-Vol'}</p>
                  </div>
                </div>
                <div class="flex items-center gap-4">
                  <span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 flex items-center gap-1.5">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span> En Ligne
                  </span>
                </div>
              `;
              listDiv.appendChild(row);
            });
            pContainer.appendChild(listDiv);
          }

        } catch (e) {
          console.error('Erreur API:', e);
        }
      }

      loadData();
      setInterval(loadData, 2000);
    </script>
  </body>
  </html>
HTML

server = TCPServer.new("0.0.0.0", PORT)

puts "================================================================="
puts "  🌐 Serveur Web PEMK MMO Démarré avec succès !"
puts "  👉 URL du Site Web : http://localhost:#{PORT}"
puts "  👉 Endpoint GTS API  : http://localhost:#{PORT}/api/gts"
puts "  👉 Endpoint Joueurs  : http://localhost:#{PORT}/api/players"
puts "================================================================="

loop do
  begin
    client = server.accept
    request_line = client.gets
    next unless request_line

    path = request_line.split(" ")[1] rescue "/"

    if path.start_with?("/api/gts")
      items = []
      if DB && DB.table_exists?(:gts_listings)
        begin
          items = DB[:gts_listings].where(status: "active").order(Sequel.desc(:id)).map do |row|
            {
              id:           row[:id],
              listing_uid:  row[:listing_uid],
              seller_name:  row[:seller_name],
              listing_type: row[:listing_type],
              category:     row[:category] || "all",
              title:        row[:title],
              data_json:    row[:data_json],
              price_type:   row[:price_type],
              price:        row[:price],
              current_bid:  row[:current_bid],
              expires_at:   row[:expires_at].to_s
            }
          end
        rescue => e
        end
      end

      # Fallback to local file if DB empty or unavailable
      if items.empty?
        [
          File.join(ROOT_DIR, "gts_listings.json"),
          File.join(ROOT_DIR, "server", "gts_listings.json"),
          File.expand_path("gts_listings.json", __dir__)
        ].each do |f|
          if File.exist?(f)
            begin
              parsed = JSON.parse(File.read(f))
              items = parsed if parsed.is_a?(Array) && !parsed.empty?
              break if !items.empty?
            rescue => e
            end
          end
        end
      end

      json_body = items.to_json
      client.print "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{json_body.bytesize}\r\nConnection: close\r\n\r\n#{json_body}"

    elsif path.start_with?("/api/players")
      players = []
      if DB && DB.table_exists?(:characters)
        begin
          players = DB[:characters].limit(50).map do |row|
            {
              name:     row[:name],
              level:    row[:level] || 50,
              location: row[:last_location] || "Bourg-en-Vol",
              online:   row[:online] || false
            }
          end
        rescue => e
        end
      end

      # Fallback to local player file if DB empty or unavailable
      if players.empty?
        [
          File.join(ROOT_DIR, "online_players.json"),
          File.join(ROOT_DIR, "server", "online_players.json"),
          File.expand_path("online_players.json", __dir__)
        ].each do |f|
          if File.exist?(f)
            begin
              parsed = JSON.parse(File.read(f))
              players = parsed if parsed.is_a?(Array) && !parsed.empty?
              break if !players.empty?
            rescue => e
            end
          end
        end
      end

      json_body = players.to_json
      client.print "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{json_body.bytesize}\r\nConnection: close\r\n\r\n#{json_body}"

    else
      client.print "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: #{HTML_PAGE.bytesize}\r\nConnection: close\r\n\r\n#{HTML_PAGE}"
    end
  rescue StandardError => e
    puts "[Web Server Error] #{e.message}"
  ensure
    client.close rescue nil
  end
end

