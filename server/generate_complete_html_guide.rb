# frozen_string_literal: true

require "json"
require "fileutils"

puts "================================================="
puts "📊 Génération du Guide d'Obtention HTML Noir & Blanc"
puts "================================================="

# Create target directories
FileUtils.mkdir_p("web")
FileUtils.mkdir_p("docs")

# Read PBS pokemon.txt
pokemon_data = []

if File.exist?("PBS/pokemon.txt")
  content = File.read("PBS/pokemon.txt", encoding: "UTF-8") rescue ""
  entries = content.split(/^#-------------------------------$/)

  entries.each_with_index do |entry, idx|
    next if entry.strip.empty?

    id_match = entry.match(/InternalName\s*=\s*(.+)/)
    name_match = entry.match(/Name\s*=\s*(.+)/)
    evo_match = entry.match(/Evolutions\s*=\s*(.+)/)
    types_match = entry.scan(/Type\d*\s*=\s*(.+)/).flatten

    next unless name_match

    int_name = id_match ? id_match[1].strip : "PKM_#{idx}"
    name = name_match[1].strip
    evos = evo_match ? evo_match[1].strip : ""
    types = types_match.compact.map(&:strip)

    dex_num = idx + 1

    pokemon_data << {
      num: dex_num,
      id: int_name,
      name: name,
      types: types,
      evos: evos
    }
  end
end

puts "Chargé #{pokemon_data.size} Pokémon depuis PBS/pokemon.txt."

# Generate HTML file content
html_content = <<~HTML
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guide d'Obtention de A à Z — Pokémon Eternal Emerald</title>
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: #111827;
            --border-color: #1f2937;
            --text-color: #f9fafb;
            --text-muted: #9ca3af;
            --accent: #ffffff;
            --accent-bg: #1f2937;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        }

        body {
            background-color: var(--bg-color);
            color: var(--text-color);
            padding: 2rem 1rem;
            line-height: 1.5;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        header {
            text-align: center;
            margin-bottom: 2.5rem;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 1.5rem;
        }

        h1 {
            font-size: 2.2rem;
            font-weight: 800;
            letter-spacing: -0.025em;
            text-transform: uppercase;
            margin-bottom: 0.5rem;
        }

        p.subtitle {
            color: var(--text-muted);
            font-size: 1rem;
        }

        .controls {
            display: flex;
            gap: 1rem;
            margin-bottom: 2rem;
            flex-wrap: wrap;
        }

        input[type="text"] {
            flex: 1;
            min-width: 280px;
            padding: 0.8rem 1.2rem;
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            color: var(--text-color);
            font-size: 1rem;
            outline: none;
            transition: border-color 0.2s;
        }

        input[type="text"]:focus {
            border-color: var(--accent);
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
            gap: 1.25rem;
        }

        .card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 1.25rem;
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            transition: transform 0.15s ease, border-color 0.15s ease;
        }

        .card:hover {
            border-color: var(--accent);
            transform: translateY(-2px);
        }

        .card-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 0.75rem;
        }

        .sprite {
            width: 64px;
            height: 64px;
            object-fit: contain;
            background-color: rgba(255, 255, 255, 0.03);
            border-radius: 8px;
            padding: 4px;
            border: 1px solid var(--border-color);
        }

        .card-title {
            flex: 1;
        }

        .card-title h3 {
            font-size: 1.2rem;
            font-weight: 700;
        }

        .card-title .dex-num {
            font-size: 0.85rem;
            color: var(--text-muted);
            font-weight: 600;
        }

        .badge-list {
            display: flex;
            gap: 0.4rem;
            margin-top: 0.25rem;
        }

        .badge {
            font-size: 0.75rem;
            padding: 0.15rem 0.5rem;
            background-color: var(--accent-bg);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .guide-section {
            font-size: 0.9rem;
        }

        .guide-section h4 {
            font-size: 0.8rem;
            text-transform: uppercase;
            color: var(--text-muted);
            letter-spacing: 0.05em;
            margin-bottom: 0.35rem;
        }

        .guide-chain {
            background-color: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 0.6rem 0.8rem;
            font-size: 0.85rem;
        }

        .step {
            margin-bottom: 0.35rem;
            display: flex;
            align-items: flex-start;
            gap: 0.4rem;
        }

        .step:last-child {
            margin-bottom: 0;
        }

        .step-num {
            font-weight: 700;
            color: var(--text-muted);
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Guide d'Obtention de A à Z</h1>
            <p class="subtitle">Pokémon Eternal Emerald Online — Mode d'obtention détaillé pour chaque Pokémon</p>
        </header>

        <div class="controls">
            <input type="text" id="searchInput" placeholder="Rechercher un Pokémon par nom ou numéro..." oninput="filterPokemon()">
        </div>

        <div class="grid" id="pokemonGrid">
            <!-- Dynamically populated -->
        </div>
    </div>

    <script>
        const pokemonList = #{pokemon_data.to_json};

        function getObtentionGuide(mon) {
            const name = mon.name;
            const id = mon.id;

            // Known legendary & special chains
            if (id === "LUNALA") {
                return [
                    "1. Obtenir Cosmog au 1er étage du Centre Spatial d'Algatia (post-Ligue) ou sur les hautes herbes du Pilier Céleste.",
                    "2. Faire évoluer Cosmog en Cosmoem au Niveau 43.",
                    "3. Faire évoluer Cosmoem en Lunala au Niveau 53 pendant la NUIT (entre 20h00 et 06h00).",
                    "Alternative : Échange via le PNJ Form Trader ou l'Hôtel des Ventes GTS."
                ];
            } else if (id === "SOLGALEO") {
                return [
                    "1. Obtenir Cosmog au Centre Spatial d'Algatia ou au Pilier Céleste.",
                    "2. Faire évoluer Cosmog en Cosmoem au Niveau 43.",
                    "3. Faire évoluer Cosmoem en Solgaleo au Niveau 53 pendant le JOUR (entre 06h00 et 20h00).",
                    "Alternative : Échange via le PNJ Form Trader ou le GTS."
                ];
            } else if (id === "COSMOEM") {
                return [
                    "1. Obtenir Cosmog au Centre Spatial d'Algatia ou au Pilier Céleste.",
                    "2. Monter au Niveau 43 pour évoluer en Cosmoem."
                ];
            } else if (id === "COSMOG") {
                return [
                    "1. Centre Spatial d'Algatia (1er étage, parlez au chercheur post-Ligue).",
                    "2. Rencontre sauvage très rare au sommet du Pilier Céleste.",
                    "3. Échange PNJ Form Trader contre une Ultra-Chimère."
                ];
            } else if (mon.evos && mon.evos.length > 0) {
                return [
                    "Forme de base ou évolution : " + mon.evos,
                    "Également capturable en sauvage ou disponible via reproduction à la Pension."
                ];
            } else {
                return [
                    "1. Rencontre directe en hautes herbes, eau ou grottes dans la région de Hoenn.",
                    "2. Reproduction à la Pension Pokémon (Route 117).",
                    "3. Disponible sur l'Hôtel des Ventes GTS."
                ];
            }
        }

        function renderGrid(list) {
            const grid = document.getElementById('pokemonGrid');
            grid.innerHTML = '';

            list.forEach(mon => {
                const guideSteps = getObtentionGuide(mon);
                
                const card = document.createElement('div');
                card.className = 'card';

                const spriteUrl = `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${mon.num}.png`;

                let stepsHtml = guideSteps.map((step, idx) => `
                    <div class="step">
                        <span class="step-num">${idx + 1}.</span>
                        <span>${step.replace(/^\\d+\\.\\s*/, '')}</span>
                    </div>
                `).join('');

                card.innerHTML = `
                    <div class="card-header">
                        <img src="${spriteUrl}" class="sprite" alt="${mon.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
                        <div class="card-title">
                            <span class="dex-num">#${String(mon.num).padStart(4, '0')}</span>
                            <h3>${mon.name}</h3>
                            <div class="badge-list">
                                ${mon.types.map(t => `<span class="badge">${t}</span>`).join('')}
                            </div>
                        </div>
                    </div>
                    <div class="guide-section">
                        <h4>Procédure d'Obtention de A à Z :</h4>
                        <div class="guide-chain">
                            ${stepsHtml}
                        </div>
                    </div>
                `;

                grid.appendChild(card);
            });
        }

        function filterPokemon() {
            const query = document.getElementById('searchInput').value.toLowerCase().trim();
            const filtered = pokemonList.filter(mon => 
                mon.name.toLowerCase().includes(query) || 
                String(mon.num).includes(query) ||
                mon.id.toLowerCase().includes(query)
            );
            renderGrid(filtered);
        }

        // Initial render
        renderGrid(pokemonList);
    </script>
</body>
</html>
HTML

File.write("web/pokemon_guide.html", html_content)
File.write("docs/GUIDE_OBTENTION_COMPLETE.html", html_content)

puts "✅ Fichiers HTML générés dans web/pokemon_guide.html et docs/GUIDE_OBTENTION_COMPLETE.html !"
puts "================================================="

