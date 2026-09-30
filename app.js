// JavaScript Application logic for Interactive Emerald MMO Map
document.addEventListener('DOMContentLoaded', () => {
  const data = window.MAP_DATA;
  if (!data) {
    console.error("MAP_DATA not loaded!");
    return;
  }

  // Elements
  const mapViewport = document.getElementById('mapViewport');
  const mapContainer = document.getElementById('mapContainer');
  const mapImage = document.getElementById('mapImage');
  const mapPinsOverlay = document.getElementById('mapPinsOverlay');
  const detailSidebar = document.getElementById('detailSidebar');
  const sidebarTitle = document.getElementById('sidebarTitle');
  const sidebarSubtitle = document.getElementById('sidebarSubtitle');
  const sidebarBody = document.getElementById('sidebarBody');
  const closeSidebarBtn = document.getElementById('closeSidebarBtn');
  const searchInput = document.getElementById('searchInput');
  const encTabsContainer = document.getElementById('encTabsContainer');

  // Zoom / Pan State
  let scale = 1.8;
  let panX = -200;
  let panY = -150;
  let isDragging = false;
  let startX, startY;
  let activePin = null;

  // Set Map Image
  if (data.mapImageBase64) {
    mapImage.src = data.mapImageBase64;
  }

  function updateTransform() {
    mapContainer.style.transform = `translate(${panX}px, ${panY}px) scale(${scale})`;
  }

  updateTransform();

  // Mouse Drag Pan
  mapViewport.addEventListener('mousedown', (e) => {
    if (e.target.closest('.map-pin')) return;
    isDragging = true;
    startX = e.clientX - panX;
    startY = e.clientY - panY;
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    panX = e.clientX - startX;
    panY = e.clientY - startY;
    updateTransform();
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  // Wheel Zoom
  mapViewport.addEventListener('wheel', (e) => {
    e.preventDefault();
    const zoomFactor = e.deltaY < 0 ? 1.15 : 0.85;
    const newScale = Math.min(Math.max(scale * zoomFactor, 0.8), 5.0);

    // Zoom towards cursor
    const rect = mapViewport.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

    panX = mouseX - (mouseX - panX) * (newScale / scale);
    panY = mouseY - (mouseY - panY) * (newScale / scale);
    scale = newScale;

    updateTransform();
  }, { passive: false });

  // Map Controls
  document.getElementById('zoomInBtn').addEventListener('click', () => {
    scale = Math.min(scale * 1.3, 5.0);
    updateTransform();
  });

  document.getElementById('zoomOutBtn').addEventListener('click', () => {
    scale = Math.max(scale * 0.7, 0.8);
    updateTransform();
  });

  document.getElementById('resetZoomBtn').addEventListener('click', () => {
    scale = 1.8;
    panX = -200;
    panY = -150;
    updateTransform();
  });

  // Map Width/Height in Grid coordinates (32x24 for mapRegion1)
  const gridW = data.gridWidth || 32;
  const gridH = data.gridHeight || 24;

  // Render Map Pins
  function renderPins(highlightSpeciesId = null) {
    mapPinsOverlay.innerHTML = '';

    // Calculate tile percentage size
    const tileWPercent = 100 / gridW;
    const tileHPercent = 100 / gridH;

    data.points.forEach((pt, idx) => {
      // Create Pin
      const pin = document.createElement('div');
      pin.className = 'map-pin';
      
      // Position pin based on grid X,Y
      const posX = (pt.x + 0.5) * tileWPercent;
      const posY = (pt.y + 0.5) * tileHPercent;
      pin.style.left = `${posX}%`;
      pin.style.top = `${posY}%`;

      const dot = document.createElement('div');
      dot.className = 'pin-dot';
      if (!pt.map_id) dot.classList.add('town');

      // Check if this map contains the highlighted species
      let hasHighlightedSpecies = false;
      if (highlightSpeciesId && pt.encounters) {
        Object.values(pt.encounters).forEach(list => {
          list.forEach(e => {
            if (e.species.toUpperCase() === highlightSpeciesId.toUpperCase()) {
              hasHighlightedSpecies = true;
            }
          });
        });
      }

      if (hasHighlightedSpecies) {
        dot.classList.add('highlighted');
      }

      pin.appendChild(dot);

      // Tooltip
      const tooltip = document.createElement('div');
      tooltip.className = 'pin-tooltip';
      tooltip.innerText = pt.name + (pt.poi ? ` (${pt.poi})` : '');
      pin.appendChild(tooltip);

      // Click event
      pin.addEventListener('click', (e) => {
        e.stopPropagation();
        openSidebar(pt);
      });

      mapPinsOverlay.appendChild(pin);
    });
  }

  renderPins();

  // Sidebar Logic
  function openSidebar(point) {
    detailSidebar.classList.remove('closed');
    sidebarTitle.innerText = point.name;
    sidebarSubtitle.innerText = point.poi ? point.poi : (point.map_id ? `Map ID: ${point.map_id}` : 'Ville / Lieu principal');

    encTabsContainer.innerHTML = '';
    sidebarBody.innerHTML = '';

    if (!point.map_id || !point.encounters) {
      sidebarBody.innerHTML = `<div style="padding: 20px; text-align: center; color: var(--text-muted);">
        <p style="font-size: 1.1rem; margin-bottom: 8px;">🏠 Zone Urbaine / Sûre</p>
        <p>Aucun Pokémon sauvage n'apparaît directement dans cette zone.</p>
      </div>`;
      return;
    }

    const encounters = point.encounters;
    const types = Object.keys(encounters);

    if (types.length === 0) {
      sidebarBody.innerHTML = `<div style="padding: 20px; text-align: center; color: var(--text-muted);">
        <p>Aucune rencontre disponible sur cette carte.</p>
      </div>`;
      return;
    }

    // Render Tabs for Encounter Types
    let activeType = types[0];

    types.forEach((typeKey, idx) => {
      const tab = document.createElement('button');
      tab.className = `enc-tab ${idx === 0 ? 'active' : ''}`;
      
      const typeLabel = getTypeLabel(typeKey);
      tab.innerText = typeLabel;

      tab.addEventListener('click', () => {
        document.querySelectorAll('.enc-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        renderEncounterCards(encounters[typeKey]);
      });

      encTabsContainer.appendChild(tab);
    });

    renderEncounterCards(encounters[activeType]);
  }

  function getTypeLabel(typeKey) {
    switch (typeKey) {
      case 'Land': return '🍃 Herbes (Jour)';
      case 'LandNight': return '🌙 Herbes (Nuit)';
      case 'LandMorning': return '🌅 Herbes (Matin)';
      case 'Water': return '🌊 Eau / Surf';
      case 'Cave': return '🪨 Grotte';
      case 'OldRod': return '🎣 Canne à Pêche';
      case 'GoodRod': return '🎣 Super Canne';
      case 'SuperRod': return '🎣 Méga Canne';
      case 'HeadbuttLow': return '🌳 Coup de Boule';
      case 'HeadbuttHigh': return '🌳 Coup de Boule Rare';
      case 'BugContest': return '🦋 Concours Capture';
      default: return typeKey;
    }
  }

  function renderEncounterCards(list) {
    sidebarBody.innerHTML = '';
    const container = document.createElement('div');
    container.className = 'enc-cards-list';

    list.forEach(item => {
      const card = document.createElement('div');
      card.className = 'pkmn-card';

      // Determine chance color badge
      let chanceClass = 'chance-high';
      if (item.chance < 15) chanceClass = 'chance-rare';
      else if (item.chance < 35) chanceClass = 'chance-medium';

      const spriteUrl = getPokemonSprite(item.species, item.name);

      card.innerHTML = `
        <div class="pkmn-sprite-wrapper">
          <img class="pkmn-sprite" src="${spriteUrl}" alt="${item.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
        </div>
        <div class="pkmn-info">
          <div class="pkmn-name-row">
            <span class="pkmn-name">${item.name}</span>
            <span class="gen-badge ${item.gen === 9 ? 'gen-9' : ''}">Gen ${item.gen}</span>
          </div>
          <div class="pkmn-details-row">
            <span class="chance-badge ${chanceClass}">${item.chance}%</span>
            <span>${item.min_lvl ? (item.min_lvl === item.max_lvl ? `Niv. ${item.min_lvl}` : `Niv. ${item.min_lvl}-${item.max_lvl}`) : ''}</span>
          </div>
        </div>
      `;

      // Click card to search this species across the map
      card.addEventListener('click', () => {
        highlightSpeciesOnMap(item.species, item.name);
      });

      container.appendChild(card);
    });

    sidebarBody.appendChild(container);
  }

  function getPokemonSprite(speciesId, name) {
    // Standard lowercased formatted species name for PokeAPI or Showdown
    const clean = speciesId.toLowerCase().replace(/[^a-z0-9]/g, '');
    return `https://play.pokemonshowdown.com/sprites/gen5/${clean}.png`;
  }

  function highlightSpeciesOnMap(speciesId, speciesName) {
    renderPins(speciesId);
    sidebarSubtitle.innerText = `Recherche : TOUTES les cartes avec ${speciesName}`;
  }

  closeSidebarBtn.addEventListener('click', () => {
    detailSidebar.classList.add('closed');
  });

  // Search Bar Real-Time Filter
  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.trim().toLowerCase();
    if (!query) {
      renderPins();
      return;
    }

    // Search species in species index
    let matchedSpeciesId = null;
    let matchedSpeciesName = null;

    Object.values(data.speciesIndex).forEach(sp => {
      if (sp.name.toLowerCase().includes(query) || sp.id.toLowerCase().includes(query)) {
        matchedSpeciesId = sp.id;
        matchedSpeciesName = sp.name;
      }
    });

    if (matchedSpeciesId) {
      highlightSpeciesOnMap(matchedSpeciesId, matchedSpeciesName);
    } else {
      renderPins();
    }
  });

  // Global Finder View Modal
  const openFinderBtn = document.getElementById('openFinderBtn');
  const finderModal = document.getElementById('finderModal');
  const closeFinderBtn = document.getElementById('closeFinderBtn');
  const finderGrid = document.getElementById('finderGrid');

  openFinderBtn.addEventListener('click', () => {
    finderModal.style.display = 'flex';
    renderFinderGrid();
  });

  closeFinderBtn.addEventListener('click', () => {
    finderModal.style.display = 'none';
  });

  function renderFinderGrid() {
    finderGrid.innerHTML = '';
    const speciesList = Object.values(data.speciesIndex);

    speciesList.slice(0, 150).forEach(sp => {
      const card = document.createElement('div');
      card.className = 'pkmn-card';
      card.style.cursor = 'pointer';

      const spriteUrl = getPokemonSprite(sp.id, sp.name);
      const locCount = sp.locations ? sp.locations.length : 0;

      card.innerHTML = `
        <div class="pkmn-sprite-wrapper">
          <img class="pkmn-sprite" src="${spriteUrl}" alt="${sp.name}" onerror="this.src='https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png'">
        </div>
        <div class="pkmn-info">
          <div class="pkmn-name-row">
            <span class="pkmn-name">${sp.name}</span>
            <span class="gen-badge">Gen ${sp.gen}</span>
          </div>
          <div class="pkmn-details-row">
            <span>📍 ${locCount} Zone(s) d'apparition</span>
          </div>
        </div>
      `;

      card.addEventListener('click', () => {
        finderModal.style.display = 'none';
        highlightSpeciesOnMap(sp.id, sp.name);
      });

      finderGrid.appendChild(card);
    });
  }
});
