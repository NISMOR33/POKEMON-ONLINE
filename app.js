// Professional Leaflet Map Engine & Pokémon Master Catalog
document.addEventListener('DOMContentLoaded', () => {
  const data = window.PRO_MAP_DATA;
  if (!data) {
    console.error("PRO_MAP_DATA is missing!");
    return;
  }

  // --- 1. LEAFLET MAP INITIALIZATION ---
  const mapWidth = data.imageWidth || 480;
  const mapHeight = data.imageHeight || 320;
  const bounds = [[0, 0], [mapHeight, mapWidth]];

  const map = L.map('leafletMap', {
    crs: L.CRS.Simple,
    minZoom: -1,
    maxZoom: 4,
    zoomSnap: 0.25,
    attributionControl: false
  });

  // Image Overlay
  L.imageOverlay(data.mapBase64, bounds).addTo(map);
  map.fitBounds(bounds);

  // Layer groups for markers and polygons
  const markersGroup = L.layerGroup().addTo(map);
  const highlightedGroup = L.layerGroup().addTo(map);

  // Store map layers mapping
  const mapLayers = {};

  // Tile sizes (30 cols, 20 rows) -> 16px per grid unit
  const tileW = mapWidth / data.gridCols; // 16px
  const tileH = mapHeight / data.gridRows; // 16px

  // Draw Leaflet Interactive Rectangles / Markers for all Town Map Points
  data.points.forEach(pt => {
    // Leaflet Simple CRS coordinates: [y, x] where (0,0) is bottom-left
    const y1 = mapHeight - (pt.y + 1) * tileH;
    const y2 = mapHeight - pt.y * tileH;
    const x1 = pt.x * tileW;
    const x2 = (pt.x + 1) * tileW;

    const rectBounds = [[y1, x1], [y2, x2]];

    // SVG Polygon / Rectangle for route
    const rect = L.rectangle(rectBounds, {
      color: pt.map_id ? '#00ff99' : '#06b6d4',
      weight: 1,
      fillColor: pt.map_id ? '#00ff99' : '#06b6d4',
      fillOpacity: 0.25
    });

    // Tooltip popup
    const popupContent = `
      <div style="text-align: center; padding: 4px;">
        <strong style="font-size: 0.95rem; color: #fff;">${pt.name}</strong><br>
        <span style="font-size: 0.75rem; color: #00ff99;">${pt.poi ? pt.poi : (pt.map_id ? `Map #${pt.map_id}` : 'Ville')}</span>
      </div>
    `;

    rect.bindTooltip(popupContent, { sticky: true });

    rect.on('mouseover', function () {
      this.setStyle({ fillOpacity: 0.6, weight: 2.5, color: '#ffffff' });
    });

    rect.on('mouseout', function () {
      this.setStyle({ fillOpacity: 0.25, weight: 1, color: pt.map_id ? '#00ff99' : '#06b6d4' });
    });

    rect.on('click', function () {
      openInfoPanel(pt);
      map.flyToBounds(rectBounds, { duration: 0.6, maxZoom: 2 });
    });

    rect.addTo(markersGroup);

    if (pt.map_id) {
      mapLayers[pt.map_id] ||= [];
      mapLayers[pt.map_id].push({ rect, bounds: rectBounds, point: pt });
    }
  });

  // --- 2. CONTROL PANEL & SEARCH LOGIC ---
  const searchInput = document.getElementById('searchInput');
  const panelList = document.getElementById('panelList');
  const infoPanel = document.getElementById('infoPanel');
  const btnCloseInfo = document.getElementById('btnCloseInfo');
  const infoTitle = document.getElementById('infoTitle');
  const infoSubtitle = document.getElementById('infoSubtitle');
  const envTabsContainer = document.getElementById('envTabsContainer');
  const infoBody = document.getElementById('infoBody');

  // Populate Left Panel Location List
  function renderControlPanelList(filterQuery = '') {
    panelList.innerHTML = '';

    // Group maps by name
    const mapEntries = Object.values(data.encountersByMap);
    const filtered = mapEntries.filter(m => m.name.toLowerCase().includes(filterQuery.toLowerCase()));

    filtered.forEach(m => {
      const card = document.createElement('div');
      card.className = 'map-item-card';

      // count species
      let speciesCount = 0;
      Object.values(m.types).forEach(list => speciesCount += list.length);

      card.innerHTML = `
        <span class="map-item-name">${m.name}</span>
        <span class="map-item-count">${speciesCount} Pokémon</span>
      `;

      card.addEventListener('click', () => {
        // find point
        const pt = data.points.find(p => p.map_id === m.id) || { map_id: m.id, name: m.name };
        openInfoPanel(pt);

        // Zoom Leaflet to location if layers exist
        if (mapLayers[m.id] && mapLayers[m.id][0]) {
          map.flyToBounds(mapLayers[m.id][0].bounds, { duration: 0.6, maxZoom: 2 });
        }
      });

      panelList.appendChild(card);
    });
  }

  renderControlPanelList();

  searchInput.addEventListener('input', (e) => {
    renderControlPanelList(e.target.value.trim());
  });

  // Filter Chips in Control Panel
  document.querySelectorAll('.filter-chips .chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.filter-chips .chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    });
  });

  // --- 3. RIGHT INFO PANEL DRAWER ---
  function openInfoPanel(point) {
    infoPanel.classList.remove('hidden');
    infoTitle.innerText = point.name;
    infoSubtitle.innerText = point.poi ? point.poi : (point.map_id ? `Carte #${point.map_id}` : 'Zone Urbaine');

    envTabsContainer.innerHTML = '';
    infoBody.innerHTML = '';

    const encounters = point.map_id && data.encountersByMap[point.map_id] ? data.encountersByMap[point.map_id].types : null;

    if (!encounters || Object.keys(encounters).length === 0) {
      infoBody.innerHTML = `
        <div style="padding: 30px; text-align: center; color: var(--text-muted);">
          <i class="fa-solid fa-house-chimney" style="font-size: 2.5rem; color: var(--cyan); margin-bottom: 12px;"></i>
          <p style="font-size: 1rem; color: #fff; font-weight: 600;">Zone Sûre / Pas de Pokémon Sauvages</p>
          <p style="font-size: 0.8rem; margin-top: 6px;">Aucune rencontre sauvage n'est configurée sur cette carte.</p>
        </div>
      `;
      return;
    }

    const types = Object.keys(encounters);
    let activeType = types[0];

    types.forEach((tKey, idx) => {
      const tab = document.createElement('button');
      tab.className = `env-tab ${idx === 0 ? 'active' : ''}`;
      tab.innerText = getEnvLabel(tKey);

      tab.addEventListener('click', () => {
        document.querySelectorAll('.env-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        renderEncounterCards(encounters[tKey]);
      });

      envTabsContainer.appendChild(tab);
    });

    renderEncounterCards(encounters[activeType]);
  }

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

  function renderEncounterCards(list) {
    infoBody.innerHTML = '';

    list.forEach(item => {
      const card = document.createElement('div');
      card.className = 'pkmn-encounter-card';

      let rateClass = 'rate-common';
      if (item.chance < 15) rateClass = 'rate-rare';
      else if (item.chance < 35) rateClass = 'rate-uncommon';

      const spriteUrl = getPokemonSprite(item.species);
      const typesHtml = item.types.map(t => `<span class="type-pill">${t}</span>`).join('');

      card.innerHTML = `
        <div class="sprite-box">
          <img class="sprite-img" src="${spriteUrl}" alt="${item.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
        </div>
        <div class="pkmn-details">
          <div class="pkmn-header-line">
            <span class="pkmn-name">${item.name}</span>
            <span class="badge-gen ${item.gen === 9 ? 'gen-9' : ''}">Gen ${item.gen}</span>
          </div>
          <div class="types-row">${typesHtml}</div>
          <div class="rate-line">
            <span class="rate-badge ${rateClass}">${item.chance}% de chance</span>
            <span>${item.min_lvl ? (item.min_lvl === item.max_lvl ? `Niv. ${item.min_lvl}` : `Niv. ${item.min_lvl}-${item.max_lvl}`) : ''}</span>
          </div>
        </div>
      `;

      // Clicking an encounter card opens its reverse locations popover!
      card.addEventListener('click', () => {
        const fullSp = data.pokemonCatalog.find(s => s.id === item.species);
        if (fullSp) openSpawnLocationsModal(fullSp);
      });

      infoBody.appendChild(card);
    });
  }

  btnCloseInfo.addEventListener('click', () => {
    infoPanel.classList.add('hidden');
  });

  // --- 4. MASTER POKEMON CATALOG & REVERSE SEARCH MODAL ---
  const btnCatalog = document.getElementById('btnCatalog');
  const catalogModal = document.getElementById('catalogModal');
  const btnCloseCatalog = document.getElementById('btnCloseCatalog');
  const catalogGrid = document.getElementById('catalogGrid');
  const catalogSearchInput = document.getElementById('catalogSearchInput');

  let selectedGenFilter = 'ALL';

  btnCatalog.addEventListener('click', () => {
    catalogModal.style.display = 'flex';
    renderCatalogGrid();
  });

  btnCloseCatalog.addEventListener('click', () => {
    catalogModal.style.display = 'none';
  });

  // Catalog Gen Filter Chips
  document.querySelectorAll('.gen-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.gen-filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      selectedGenFilter = chip.getAttribute('data-gen');
      renderCatalogGrid();
    });
  });

  catalogSearchInput.addEventListener('input', () => {
    renderCatalogGrid();
  });

  function renderCatalogGrid() {
    catalogGrid.innerHTML = '';

    const query = catalogSearchInput.value.trim().toLowerCase();

    let filtered = data.pokemonCatalog.filter(sp => {
      const matchName = sp.name.toLowerCase().includes(query) || sp.id.toLowerCase().includes(query) || sp.dex.toString().includes(query);
      const matchGen = selectedGenFilter === 'ALL' || sp.gen.toString() === selectedGenFilter;
      return matchName && matchGen;
    });

    filtered.forEach(sp => {
      const card = document.createElement('div');
      card.className = 'catalog-card';

      const spriteUrl = getPokemonSprite(sp.id);
      const locCount = sp.locations ? sp.locations.length : 0;
      const typesHtml = sp.types.map(t => `<span class="type-pill">${t}</span>`).join('');

      card.innerHTML = `
        <div class="sprite-box">
          <img class="sprite-img" src="${spriteUrl}" alt="${sp.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
        </div>
        <div style="flex: 1;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 2px;">
            <strong style="font-family: var(--font-heading); font-size: 0.95rem; color: #fff;">${sp.name}</strong>
            <span class="badge-gen ${sp.gen === 9 ? 'gen-9' : ''}">Gen ${sp.gen}</span>
          </div>
          <div class="types-row" style="margin-bottom: 4px;">${typesHtml}</div>
          <div class="loc-count">📍 ${locCount} Zone(s) d'apparition</div>
        </div>
      `;

      card.addEventListener('click', () => {
        openSpawnLocationsModal(sp);
      });

      catalogGrid.appendChild(card);
    });
  }

  // --- 5. POKEMON SPAWN LOCATIONS POPOVER MODAL ---
  const spawnModal = document.getElementById('spawnModal');
  const spawnModalHeader = document.getElementById('spawnModalHeader');
  const spawnModalBody = document.getElementById('spawnModalBody');
  const btnCloseSpawnModal = document.getElementById('btnCloseSpawnModal');

  function openSpawnLocationsModal(sp) {
    spawnModal.style.display = 'flex';
    const spriteUrl = getPokemonSprite(sp.id);

    spawnModalHeader.innerHTML = `
      <div style="display: flex; align-items: center; gap: 14px;">
        <div class="sprite-box" style="width: 48px; height: 48px;">
          <img class="sprite-img" src="${spriteUrl}" alt="${sp.name}">
        </div>
        <div>
          <h3 style="font-family: var(--font-heading); font-size: 1.2rem; color: #fff;">${sp.name}</h3>
          <span style="font-size: 0.78rem; color: var(--emerald);">Génération ${sp.gen} • ${sp.locations ? sp.locations.length : 0} Zone(s) d'apparition</span>
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
        <div style="padding: 20px; text-align: center; color: var(--text-muted);">
          <p>Aucune rencontre sauvage directe enregistrée (Évolution, Cadeau Mystère, Échange ou Événement MQS).</p>
        </div>
      `;
      return;
    }

    sp.locations.forEach(loc => {
      const row = document.createElement('div');
      row.className = 'pkmn-encounter-card';
      row.style.justifyConstraint = 'space-between';

      let rateClass = 'rate-common';
      if (loc.chance < 15) rateClass = 'rate-rare';
      else if (loc.chance < 35) rateClass = 'rate-uncommon';

      row.innerHTML = `
        <div style="flex: 1;">
          <strong style="font-family: var(--font-heading); font-size: 0.95rem; color: #fff;">${loc.map_name}</strong>
          <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 2px;">
            ${getEnvLabel(loc.method)} ${loc.min_lvl ? `• Niv. ${loc.min_lvl}-${loc.max_lvl}` : ''}
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 10px;">
          <span class="rate-badge ${rateClass}">${loc.chance}%</span>
          <button class="btn-nav btn-locate" style="padding: 6px 12px; font-size: 0.75rem;">
            <i class="fa-solid fa-crosshairs"></i> Localiser
          </button>
        </div>
      `;

      row.querySelector('.btn-locate').addEventListener('click', () => {
        spawnModal.style.display = 'none';
        catalogModal.style.display = 'none';

        // Find point and zoom Leaflet to bounds!
        const pt = data.points.find(p => p.map_id === loc.map_id) || { map_id: loc.map_id, name: loc.map_name };
        openInfoPanel(pt);

        if (mapLayers[loc.map_id] && mapLayers[loc.map_id][0]) {
          const l = mapLayers[loc.map_id][0];
          map.flyToBounds(l.bounds, { duration: 0.8, maxZoom: 2.5 });
          l.rect.setStyle({ fillOpacity: 0.8, color: '#ff0055', weight: 3 });
        }
      });

      spawnModalBody.appendChild(row);
    });
  }

  btnCloseSpawnModal.addEventListener('click', () => {
    spawnModal.style.display = 'none';
  });

  // Helper function for Pokemon Sprite URL
  function getPokemonSprite(speciesId) {
    const clean = speciesId.toLowerCase().replace(/[^a-z0-9]/g, '');
    return `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;
  }
});
