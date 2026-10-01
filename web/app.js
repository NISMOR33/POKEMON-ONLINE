// Professional Multi-View Web App & Leaflet Engine
document.addEventListener('DOMContentLoaded', () => {
  const masterData = window.PRO_MAP_DATA;
  if (!masterData) {
    console.error("PRO_MAP_DATA is missing!");
    return;
  }

  // --- 1. PAGE NAVIGATION TAB SWITCHING ---
  const navButtons = document.querySelectorAll('.nav-tab-btn');
  const pageViews = document.querySelectorAll('.page-view');

  navButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-target');

      navButtons.forEach(b => b.classList.remove('active'));
      pageViews.forEach(v => v.classList.remove('active'));

      btn.classList.add('active');
      document.getElementById(targetId).classList.add('active');

      if (targetId === 'viewMap' && map) {
        setTimeout(() => map.invalidateSize(), 100);
      } else if (targetId === 'viewCatalog') {
        renderCatalogGrid();
      } else if (targetId === 'viewUnobtainable') {
        renderUnobtainableGrid();
      } else if (targetId === 'viewDocs') {
        renderDocsSection('stats');
      }
    });
  });

  // --- 2. LEAFLET MAP ENGINE INITIALIZATION ---
  const tileBounds = L.latLngBounds(L.latLng(-95.7421875, 0), L.latLng(0, 199.9921875));

  const map = L.map('map', {
    crs: L.CRS.Simple,
    minZoom: 3,
    maxZoom: 7,
    zoomSnap: 0.25,
    attributionControl: false,
    maxBounds: tileBounds
  });

  let currentShortname = "OverworldTrainers";
  let tileLayer = L.tileLayer(`https://pkmnmap.com/Maps/Emerald/Content/Tilesets/${currentShortname}/{z}/{x}/{y}.png`, {
    minZoom: 3,
    maxZoom: 7,
    tileSize: 256,
    bounds: tileBounds
  }).addTo(map);

  map.setView([-47.87, 100], 4);

  // Scope Switch (Monde Normal vs Sous l'Eau)
  document.querySelectorAll('.scope-button').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.scope-button').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const targetMap = btn.getAttribute('data-map');
      currentShortname = targetMap === 'Underwater' ? 'Underwater' : 'OverworldTrainers';
      map.removeLayer(tileLayer);
      tileLayer = L.tileLayer(`https://pkmnmap.com/Maps/Emerald/Content/Tilesets/${currentShortname}/{z}/{x}/{y}.png`, {
        minZoom: 3,
        maxZoom: 7,
        tileSize: 256,
        bounds: tileBounds
      }).addTo(map);
    });
  });

  // --- 3. GEOJSON VECTOR ROUTE OVERLAYS ---
  const vectorLayersByName = {};

  if (window.OverworldVector) {
    L.geoJson(window.OverworldVector, {
      style: function () {
        return {
          color: '#00ff99',
          weight: 1.5,
          fillColor: '#00ff99',
          fillOpacity: 0.15
        };
      },
      onEachFeature: function (feature, layer) {
        const props = feature.properties;
        if (!props || !props.name) return;

        vectorLayersByName[props.name.toLowerCase()] ||= [];
        vectorLayersByName[props.name.toLowerCase()].push({ layer, props });

        layer.bindTooltip(`<strong>${props.name}</strong>`, { sticky: true });

        layer.on('mouseover', function () {
          this.setStyle({ fillOpacity: 0.55, weight: 2.5, color: '#ffffff' });
        });

        layer.on('mouseout', function () {
          this.setStyle({ fillOpacity: 0.15, weight: 1.5, color: '#00ff99' });
        });

        layer.on('click', function () {
          openInfoPanel(props);
          map.fitBounds(layer.getBounds(), { maxZoom: 6, animate: true, duration: 0.5 });
        });
      }
    }).addTo(map);
  }

  // --- 4. LEFT CONTROL PANEL (LOCATION SEARCH) ---
  const searchInput = document.getElementById('searchInput');
  const panelList = document.getElementById('panelList');

  function renderControlPanel(query = '') {
    panelList.innerHTML = '';
    const mapEntries = Object.values(masterData.encountersByMap);

    const filtered = mapEntries.filter(m => m.name.toLowerCase().includes(query.toLowerCase()));

    filtered.forEach(m => {
      const card = document.createElement('div');
      card.className = 'map-card-item';

      let speciesCount = 0;
      Object.values(m.types).forEach(list => speciesCount += list.length);

      card.innerHTML = `
        <span class="map-card-title">${m.name}</span>
        <span class="map-card-badge">${speciesCount} Pokémon</span>
      `;

      card.addEventListener('click', () => {
        const matches = vectorLayersByName[m.name.toLowerCase()];
        if (matches && matches[0]) {
          openInfoPanel(matches[0].props);
          map.fitBounds(matches[0].layer.getBounds(), { maxZoom: 6, animate: true, duration: 0.5 });
        } else {
          openInfoPanelFromPBS(m);
        }
      });

      panelList.appendChild(card);
    });
  }

  renderControlPanel();

  searchInput.addEventListener('input', (e) => {
    renderControlPanel(e.target.value.trim());
  });

  // --- 5. RIGHT INFO PANEL (EXACT PKMNMAP TABLE LAYOUT) ---
  const infoPanel = document.getElementById('infoPanel');
  const btnCloseInfo = document.getElementById('btnCloseInfo');
  const infoTitle = document.getElementById('infoTitle');
  const infoBody = document.getElementById('infoBody');

  function openInfoPanel(props) {
    infoPanel.classList.remove('hidden');
    infoTitle.innerText = props.name;

    let encounters = props["Pokemon"] || props["Pokémon"];
    if (!encounters || Object.keys(encounters).length === 0) {
      const pbsMatch = Object.values(masterData.encountersByMap).find(m => m.name.toLowerCase() === props.name.toLowerCase());
      if (pbsMatch) {
        openInfoPanelFromPBS(pbsMatch);
        return;
      }
    }

    renderEncounterTableFromVectorProps(encounters);
  }

  function openInfoPanelFromPBS(pbsMatch) {
    infoPanel.classList.remove('hidden');
    infoTitle.innerText = pbsMatch.name;
    infoBody.innerHTML = '';

    const types = pbsMatch.types;
    if (!types || Object.keys(types).length === 0) {
      infoBody.innerHTML = `<div style="padding: 24px; text-align: center; color: var(--text-muted);">Aucun Pokémon sauvage configuré sur cette zone.</div>`;
      return;
    }

    let tableHtml = `
      <table class="pkmn-table">
        <thead>
          <tr>
            <th>Icon</th>
            <th>Name</th>
            <th>Method</th>
            <th>Levels</th>
            <th>Rate</th>
          </tr>
        </thead>
        <tbody>
    `;

    Object.keys(types).forEach(method => {
      tableHtml += `<tr class="section-row"><td colspan="5">${getEnvLabel(method)}</td></tr>`;
      types[method].forEach(item => {
        const clean = item.species.toLowerCase().replace(/[^a-z0-9]/g, '');
        const spriteUrl = `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;
        let rateClass = item.chance >= 35 ? 'rate-high' : (item.chance >= 15 ? 'rate-mid' : 'rate-low');

        tableHtml += `
          <tr style="cursor: pointer;" onclick="window.openPokemonCatalogModalFor('${item.species}')">
            <td class="pkmn-cell-icon"><img src="${spriteUrl}" alt="${item.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'"></td>
            <td style="font-weight: 700; color: #fff;">${item.name} <span class="badge-gen ${item.gen === 9 ? 'gen-9' : ''}">G${item.gen}</span></td>
            <td style="color: var(--cyan);">${getEnvLabel(method)}</td>
            <td>${item.min_lvl ? (item.min_lvl === item.max_lvl ? `Niv. ${item.min_lvl}` : `Niv. ${item.min_lvl}-${item.max_lvl}`) : ''}</td>
            <td><span class="rate-badge ${rateClass}">${item.chance}%</span></td>
          </tr>
        `;
      });
    });

    tableHtml += `</tbody></table>`;
    infoBody.innerHTML = tableHtml;
  }

  function renderEncounterTableFromVectorProps(encounters) {
    infoBody.innerHTML = '';

    if (!encounters || Object.keys(encounters).length === 0) {
      infoBody.innerHTML = `<div style="padding: 24px; text-align: center; color: var(--text-muted);">Aucune rencontre disponible.</div>`;
      return;
    }

    let tableHtml = `
      <table class="pkmn-table">
        <thead>
          <tr>
            <th>Icon</th>
            <th>Name</th>
            <th>Method</th>
            <th>Levels</th>
            <th>Rate</th>
          </tr>
        </thead>
        <tbody>
    `;

    Object.keys(encounters).forEach(area => {
      tableHtml += `<tr class="section-row"><td colspan="5">${area}</td></tr>`;
      encounters[area].forEach(e => {
        const clean = e.name.toLowerCase().replace(/[^a-z0-9]/g, '');
        const spriteUrl = `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;
        let rateVal = parseInt(e.rate) || 0;
        let rateClass = rateVal >= 35 ? 'rate-high' : (rateVal >= 15 ? 'rate-mid' : 'rate-low');

        tableHtml += `
          <tr style="cursor: pointer;" onclick="window.openPokemonCatalogModalFor('${e.name}')">
            <td class="pkmn-cell-icon"><img src="${spriteUrl}" alt="${e.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'"></td>
            <td style="font-weight: 700; color: #fff;">${e.name}</td>
            <td style="color: var(--cyan);">${e.area || area}</td>
            <td>Niv. ${e.levels || ''}</td>
            <td><span class="rate-badge ${rateClass}">${e.rate}</span></td>
          </tr>
        `;
      });
    });

    tableHtml += `</tbody></table>`;
    infoBody.innerHTML = tableHtml;
  }

  btnCloseInfo.addEventListener('click', () => {
    infoPanel.classList.add('hidden');
  });

  function getEnvLabel(tKey) {
    switch (tKey) {
      case 'Land': return '🍃 Herbes (Jour)';
      case 'LandNight': return '🌙 Herbes (Nuit)';
      case 'LandMorning': return '🌅 Herbes (Matin)';
      case 'Water': return '🌊 Eau / Surf';
      case 'Cave': return '🪨 Grotte';
      case 'OldRod': return '🎣 Canne';
      case 'GoodRod': return '🎣 Super Canne';
      case 'SuperRod': return '🎣 Méga Canne';
      case 'HeadbuttLow': return '🌳 Coup de Boule';
      case 'HeadbuttHigh': return '🌳 Coup de Boule Rare';
      case 'BugContest': return '🦋 Concours';
      default: return tKey;
    }
  }

  // --- 6. MASTER POKEMON CATALOG VIEW ---
  const catalogGrid = document.getElementById('catalogGrid');
  const catalogSearchInput = document.getElementById('catalogSearchInput');
  let catalogGenFilter = 'ALL';

  document.querySelectorAll('.catalog-gen-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.catalog-gen-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      catalogGenFilter = chip.getAttribute('data-gen');
      renderCatalogGrid();
    });
  });

  catalogSearchInput.addEventListener('input', () => {
    renderCatalogGrid();
  });

  function renderCatalogGrid() {
    catalogGrid.innerHTML = '';
    const query = catalogSearchInput.value.trim().toLowerCase();

    const filtered = masterData.pokemonCatalog.filter(sp => {
      const matchQuery = sp.name.toLowerCase().includes(query) || sp.id.toLowerCase().includes(query) || sp.dex.toString().includes(query);
      const matchGen = catalogGenFilter === 'ALL' || sp.gen.toString() === catalogGenFilter;
      return matchQuery && matchGen;
    });

    filtered.forEach(sp => {
      const card = document.createElement('div');
      card.className = 'pro-card';

      const clean = sp.id.toLowerCase().replace(/[^a-z0-9]/g, '');
      const spriteUrl = `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;
      const locCount = sp.locations ? sp.locations.length : 0;

      const locBadge = sp.isWild 
        ? `<div style="font-size: 0.75rem; color: var(--emerald); font-weight: 700;">📍 ${locCount} Zone(s) d'apparition</div>`
        : `<div style="font-size: 0.72rem; color: var(--amber); font-weight: 700;">🚫 Non Obtenable Sauvage</div>`;

      card.innerHTML = `
        <div class="animated-sprite-box">
          <img src="${spriteUrl}" alt="${sp.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
        </div>
        <div class="pro-card-content">
          <div class="pro-card-title">
            <strong>${sp.name}</strong>
            <span class="badge-gen ${sp.gen === 9 ? 'gen-9' : ''}">Gen ${sp.gen}</span>
          </div>
          ${locBadge}
        </div>
      `;

      card.addEventListener('click', () => {
        openSpawnModal(sp);
      });

      catalogGrid.appendChild(card);
    });
  }

  // --- 7. UNOBTAINABLE POKEMON VIEW ---
  const unobtainableGrid = document.getElementById('unobtainableGrid');
  const unobtainableSearchInput = document.getElementById('unobtainableSearchInput');
  let unobGenFilter = 'ALL';

  document.querySelectorAll('.unob-gen-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.unob-gen-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      unobGenFilter = chip.getAttribute('data-gen');
      renderUnobtainableGrid();
    });
  });

  unobtainableSearchInput.addEventListener('input', () => {
    renderUnobtainableGrid();
  });

  function renderUnobtainableGrid() {
    unobtainableGrid.innerHTML = '';
    const query = unobtainableSearchInput.value.trim().toLowerCase();

    const filtered = masterData.pokemonCatalog.filter(sp => {
      if (sp.isWild) return false;
      const matchQuery = sp.name.toLowerCase().includes(query) || sp.id.toLowerCase().includes(query) || sp.dex.toString().includes(query);
      const matchGen = unobGenFilter === 'ALL' || sp.gen.toString() === unobGenFilter;
      return matchQuery && matchGen;
    });

    filtered.forEach(sp => {
      const card = document.createElement('div');
      card.className = 'pro-card unobtainable-card';

      const clean = sp.id.toLowerCase().replace(/[^a-z0-9]/g, '');
      const spriteUrl = `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;

      card.innerHTML = `
        <div class="animated-sprite-box">
          <img src="${spriteUrl}" alt="${sp.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
        </div>
        <div class="pro-card-content">
          <div class="pro-card-title">
            <strong>${sp.name}</strong>
            <span class="badge-gen ${sp.gen === 9 ? 'gen-9' : ''}">Gen ${sp.gen}</span>
          </div>
          <div style="font-size: 0.72rem; color: var(--amber); font-weight: 700;">🚫 Non Obtenable Sauvage</div>
          <div style="font-size: 0.68rem; color: var(--text-muted); margin-top: 2px;">Évol. / MQS / Form Trader</div>
        </div>
      `;

      card.addEventListener('click', () => {
        openSpawnModal(sp);
      });

      unobtainableGrid.appendChild(card);
    });
  }

  // --- 8. MODPACK DOCUMENTATION VIEW ---
  const docsContentArea = document.getElementById('docsContentArea');

  document.querySelectorAll('.docs-nav-item').forEach(item => {
    item.addEventListener('click', () => {
      document.querySelectorAll('.docs-nav-item').forEach(i => i.classList.remove('active'));
      item.classList.add('active');
      renderDocsSection(item.getAttribute('data-doc'));
    });
  });

  function renderDocsSection(docKey) {
    switch (docKey) {
      case 'stats':
        docsContentArea.innerHTML = `
          <h3>📊 Vue d'Ensemble & Statistiques du Modpack</h3>
          <p><strong>Pokémon Eternal Emerald MMO</strong> combine Pokémon Essentials v21.1 / MKXP-Z avec le moteur réseau synchrone PEMK, l'extension Légendes Z et Deluxe Battle Kit.</p>
          <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; margin: 20px 0;">
            <div style="background: rgba(255,255,255,0.05); padding: 16px; border-radius: 12px; border: 1px solid var(--border-color);">
              <div style="font-size: 1.5rem; font-weight: 900; color: var(--emerald);">1 026 Pokémon</div>
              <div style="font-size: 0.8rem; color: var(--text-muted);">Gen 1 à Gen 9 (Paldea complet)</div>
            </div>
            <div style="background: rgba(255,255,255,0.05); padding: 16px; border-radius: 12px; border: 1px solid var(--border-color);">
              <div style="font-size: 1.5rem; font-weight: 900; color: var(--cyan);">100+ Méga-Évolutions</div>
              <div style="font-size: 0.8rem; color: var(--text-muted);">Mégas officielles + Légendes Z</div>
            </div>
            <div style="background: rgba(255,255,255,0.05); padding: 16px; border-radius: 12px; border: 1px solid var(--border-color);">
              <div style="font-size: 1.5rem; font-weight: 900; color: var(--amber);">47+ Plugins</div>
              <div style="font-size: 0.8rem; color: var(--text-muted);">DBK, MUI, Housing, MQS</div>
            </div>
            <div style="background: rgba(255,255,255,0.05); padding: 16px; border-radius: 12px; border: 1px solid var(--border-color);">
              <div style="font-size: 1.5rem; font-weight: 900; color: var(--purple);">1 046 Objets</div>
              <div style="font-size: 0.8rem; color: var(--text-muted);">Capsules, Cristaux Z, Meubles</div>
            </div>
          </div>
        `;
        break;

      case 'plugins':
        docsContentArea.innerHTML = `
          <h3>🧩 Catalogue des 47+ Plugins & Mods Installés</h3>
          <p>Le projet est composé d'une suite modulaire complète d'extensions :</p>
          <ul style="margin-left: 20px; line-height: 1.8; color: #cbd5e1;">
            <li><strong>Deluxe Battle Kit (DBK_000 à 010) :</strong> Animations de combat, jauges, SOS Battles, Z-Power, Intros animées.</li>
            <li><strong>Modular UI Scenes (MUI_000 à 004) :** Pokédex augmenté, résumé détaillé IV/EV, raccourci des capacités de terrain.</li>
            <li><strong>PEMK & PEMK Housing :** Serveur MMO multijoueur synchrone, maison joueur et peinture de sol procédurale.</li>
            <li><strong>Génération 9 Pack :** Intégration complète de Paldea, Téracristallisation, talents et capacités Gen 9.</li>
            <li><strong>Following Pokemon EX :** Pokémon suiveur interactif sur la carte.</li>
            <li><strong>MQS (Modern Quest System) :** Journal de quêtes principales et secondaires avec suivi des objectifs.</li>
          </ul>
        `;
        break;

      case 'legendes-z':
        docsContentArea.innerHTML = `
          <h3>🐉 Extension Légendes Z & Méga-Évolutions Exclusives</h3>
          <p>Récoltez les 100 Cellules Zygarde avec le <strong>Cube Zygarde</strong> pour débloquer les formes 10%, 50%, Parfaite 100% et la forme mythique <strong>Méga-Zygarde (\`ZYGARDITE\`)</strong> !</p>
          <p>Profitez également des Méga-Évolutions exclusives : Méga-Raichu X/Y, Méga-Greninja X/Y, Méga-Lucario Z, Méga-Garchomp Z, Méga-Absol Z, Méga-Dragonite, Méga-Flygon, Méga-Éternatos, Méga-Darkrai, etc.</p>
        `;
        break;

      case 'housing':
        docsContentArea.innerHTML = `
          <h3>🏡 Guide Ultime du Housing & Peinture de Sol</h3>
          <p>Téléportez-vous dans votre maison via le PNJ Réceptionniste (Map 927).</p>
          <p>Appuyez sur <strong>\`D\`</strong> pour entrer en Mode Décoration, placez vos meubles ou utilisez l'outil de Peinture de Sol en 2 étapes (Sélection du motif puis rectangle de sélection) !</p>
        `;
        break;

      case 'controls':
        docsContentArea.innerHTML = `
          <h3>🎮 Commandes Clavier & Raccourcis</h3>
          <table class="pkmn-table" style="max-width: 600px;">
            <thead><tr><th>Touche</th><th>Action</th></tr></thead>
            <tbody>
              <tr><td><strong>Z / Q / S / D</strong></td><td>Déplacement du personnage (AZERTY natif)</td></tr>
              <tr><td><strong>Entrée / C</strong></td><td>Interagir / Valider</td></tr>
              <tr><td><strong>D</strong></td><td>Activer / Quitter le mode Décoration Housing</td></tr>
              <tr><td><strong>Tab</strong></td><td>Changer le motif de sol en mode peinture</td></tr>
              <tr><td><strong>F / Turbo</strong></td><td>Vitesse accélérée de combat et déplacement</td></tr>
              <tr><td><strong>T</strong></td><td>Fenêtre de Chat Multijoueur MMO</td></tr>
            </tbody>
          </table>
        `;
        break;
    }
  }

  // --- 9. SPAWN LOCATIONS POPOVER MODAL ---
  const spawnModal = document.getElementById('spawnModal');
  const spawnModalHeader = document.getElementById('spawnModalHeader');
  const spawnModalBody = document.getElementById('spawnModalBody');
  const btnCloseSpawnModal = document.getElementById('btnCloseSpawnModal');

  window.openPokemonCatalogModalFor = function (speciesQuery) {
    const sp = masterData.pokemonCatalog.find(s => s.id.toUpperCase() === speciesQuery.toUpperCase() || s.name.toLowerCase() === speciesQuery.toLowerCase());
    if (sp) openSpawnModal(sp);
  };

  function openSpawnModal(sp) {
    spawnModal.style.display = 'flex';
    const clean = sp.id.toLowerCase().replace(/[^a-z0-9]/g, '');
    const spriteUrl = `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;

    spawnModalHeader.innerHTML = `
      <div style="display: flex; align-items: center; gap: 12px;">
        <img src="${spriteUrl}" style="width: 44px; height: 44px; object-fit: contain;">
        <div>
          <h3 style="font-family: var(--font-heading); font-size: 1.15rem; color: #fff;">${sp.name}</h3>
          <span style="font-size: 0.78rem; color: var(--emerald);">Génération ${sp.gen} • ${sp.isWild ? `${sp.locations.length} Zone(s) d'apparition` : 'Pokémon Non Obtenable Sauvage'}</span>
        </div>
      </div>
      <button id="btnCloseSpawnModalInner" class="btn-close"><i class="fa-solid fa-xmark"></i></button>
    `;

    document.getElementById('btnCloseSpawnModalInner').addEventListener('click', () => {
      spawnModal.style.display = 'none';
    });

    spawnModalBody.innerHTML = '';

    if (!sp.locations || sp.locations.length === 0) {
      spawnModalBody.innerHTML = `
        <div style="padding: 24px; text-align: center; color: var(--text-muted);">
          <i class="fa-solid fa-ban" style="font-size: 2.5rem; color: var(--amber); margin-bottom: 10px;"></i>
          <p style="font-size: 1rem; color: #fff; font-weight: 700; margin-bottom: 6px;">Pokémon Non Obtenable en Rencontre Sauvage</p>
          <p style="font-size: 0.82rem;">Ce Pokémon ne s'attrape pas dans l'herbe/eau de manière sauvage. Il s'obtient via :</p>
          <ul style="text-align: left; max-width: 380px; margin: 12px auto 0; font-size: 0.8rem; line-height: 1.6; color: var(--emerald);">
            <li>• Évolutions / Reproduction</li>
            <li>• Quêtes scénarisées dans le journal MQS</li>
            <li>• PNJ Form Trader (Échanges de Formes)</li>
            <li>• Événements & Codes Cadeau Mystère</li>
          </ul>
        </div>
      `;
      return;
    }

    sp.locations.forEach(loc => {
      const row = document.createElement('div');
      row.className = 'map-card-item';

      let rateClass = loc.chance >= 35 ? 'rate-high' : (loc.chance >= 15 ? 'rate-mid' : 'rate-low');

      row.innerHTML = `
        <div>
          <strong style="color: #fff; font-size: 0.9rem;">${loc.map_name}</strong>
          <div style="font-size: 0.75rem; color: var(--text-muted);">${getEnvLabel(loc.method)} ${loc.min_lvl ? `• Niv. ${loc.min_lvl}-${loc.max_lvl}` : ''}</div>
        </div>
        <div style="display: flex; align-items: center; gap: 10px;">
          <span class="rate-badge ${rateClass}">${loc.chance}%</span>
          <button class="btn-nav btn-locate" style="padding: 4px 10px; font-size: 0.75rem;"><i class="fa-solid fa-crosshairs"></i> Localiser</button>
        </div>
      `;

      row.querySelector('.btn-locate').addEventListener('click', () => {
        spawnModal.style.display = 'none';

        // Switch to Map View Tab!
        document.getElementById('btnNavMap').click();

        const matches = vectorLayersByName[loc.map_name.toLowerCase()];
        if (matches && matches[0]) {
          openInfoPanel(matches[0].props);
          map.fitBounds(matches[0].layer.getBounds(), { maxZoom: 6, animate: true, duration: 0.6 });
          matches[0].layer.setStyle({ fillOpacity: 0.8, color: '#ff0055', weight: 3 });
        }
      });

      spawnModalBody.appendChild(row);
    });
  }

  btnCloseSpawnModal.addEventListener('click', () => {
    spawnModal.style.display = 'none';
  });
});
