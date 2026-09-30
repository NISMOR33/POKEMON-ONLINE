from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, shutil, zipfile

ROOT = Path(__file__).resolve().parents[1]
TILES = ROOT / "Graphics" / "Tilesets"
OUT = ROOT / "exports" / "Housing-Furniture-Pack"
SPRITES = OUT / "Graphics" / "Pictures" / "Housing"
SOURCES = OUT / "sources"

# key, French name, category, source, x, y, width, height, footprint w/h,
# price, interaction. Coordinates are native pixels in the RMXP tilesets.
ITEMS = [
    ("bookcase_green_low", "Bibliothèque verte basse", "decor", "Interior general.png", 0, 4384, 64, 64, 2, 1, 420, None),
    ("bookcase_brown_large", "Grande bibliothèque", "decor", "Interior general.png", 64, 4384, 96, 64, 3, 1, 650, None),
    ("display_cabinet_green", "Vitrine verte", "decor", "Interior general.png", 32, 4448, 64, 64, 2, 1, 520, None),
    ("display_cabinet_yellow", "Vitrine jaune", "decor", "Interior general.png", 96, 4448, 64, 64, 2, 1, 520, None),
    ("display_cabinet_blue", "Vitrine bleue", "decor", "Interior general.png", 160, 4448, 64, 64, 2, 1, 520, None),
    ("kitchen_sink_blue", "Évier bleu", "functional", "Interior general.png", 64, 4480, 64, 64, 2, 1, 550, None),
    ("kitchen_sink_white", "Évier blanc", "functional", "Interior general.png", 128, 4480, 64, 64, 2, 1, 550, None),
    ("bed_single_green", "Lit simple vert", "functional", "Interior general.png", 0, 4544, 32, 64, 1, 2, 700, "bed"),
    ("bed_double_green", "Lit double vert", "functional", "Interior general.png", 64, 4544, 64, 64, 2, 2, 900, "bed"),
    ("bed_single_purple", "Lit simple violet", "functional", "Interior general.png", 0, 4608, 32, 64, 1, 2, 700, "bed"),
    ("bed_double_purple", "Lit double violet", "functional", "Interior general.png", 64, 4608, 64, 64, 2, 2, 900, "bed"),
    ("sofa_blue_long", "Grand canapé bleu", "decor", "Interior general.png", 0, 4704, 96, 64, 3, 1, 750, None),
    ("sofa_orange_long", "Grand canapé orange", "decor", "Interior general.png", 128, 4704, 96, 64, 3, 1, 750, None),
    ("armchair_wood", "Fauteuil en bois", "decor", "Interior general.png", 64, 4736, 32, 64, 1, 1, 260, None),
    ("chair_pink", "Chaise rose", "decor", "Interior general.png", 96, 4736, 32, 64, 1, 1, 160, None),
    ("chair_blue_square", "Chaise bleue carrée", "decor", "Interior general.png", 128, 4736, 32, 64, 1, 1, 160, None),
    ("terminal_tall", "Terminal haut", "functional", "Interior general.png", 224, 4800, 32, 64, 1, 1, 600, None),
    ("statue_stone", "Statue de pierre", "decor", "Interior general.png", 0, 4800, 32, 64, 1, 1, 450, None),
    ("statue_cat", "Statue Pokémon", "decor", "Interior general.png", 32, 4800, 32, 64, 1, 1, 500, None),
    ("plant_round", "Plante ronde", "decor", "Interior general.png", 96, 4992, 32, 64, 1, 1, 280, None),
    ("plant_flower_pink", "Plante fleurie rose", "decor", "Interior general.png", 128, 4992, 32, 64, 1, 1, 320, None),
    ("plant_flower_blue", "Plante fleurie bleue", "decor", "Interior general.png", 160, 4992, 32, 64, 1, 1, 320, None),
    ("plant_topiary", "Topiaire", "decor", "Interior general.png", 192, 4992, 32, 64, 1, 1, 350, None),
    ("healing_station_large", "Grande machine de soin", "functional", "Interior general.png", 0, 5056, 64, 96, 2, 2, 2200, "heal"),
    ("hifi_wall_orange", "Chaîne hi-fi orange", "functional", "Interior general.png", 128, 5056, 64, 64, 2, 1, 900, "jukebox"),
    ("lab_tube_green", "Cuve de laboratoire", "decor", "Interior general.png", 96, 5120, 96, 128, 3, 3, 1800, None),
    ("bed_orange_lab", "Lit orange", "functional", "Weather Institute.png", 128, 96, 64, 64, 2, 2, 800, "bed"),
    ("sofa_blue_vertical", "Canapé bleu vertical", "decor", "Weather Institute.png", 0, 96, 64, 96, 1, 3, 650, None),
    ("desk_white_long", "Grande table blanche", "decor", "Weather Institute.png", 96, 256, 96, 64, 3, 1, 480, None),
    ("bookcase_lab", "Bibliothèque de laboratoire", "decor", "Weather Institute.png", 0, 320, 64, 64, 2, 1, 450, None),
    ("office_desk_blue", "Bureau bleu", "functional", "Ranger Guild Indoors.png", 96, 160, 64, 64, 2, 1, 650, "pc"),
    ("office_desk_white", "Bureau blanc", "functional", "Ranger Guild Indoors.png", 160, 160, 64, 64, 2, 1, 650, "pc"),
    ("conference_table", "Table de conférence", "decor", "Ranger Guild Indoors.png", 128, 384, 96, 64, 3, 2, 800, None),
    ("chair_green_office", "Chaise de bureau verte", "decor", "Ranger Guild Indoors.png", 64, 384, 32, 64, 1, 1, 180, None),
    ("plant_guild_a", "Plante de guilde", "decor", "Ranger Guild Indoors.png", 0, 640, 32, 64, 1, 1, 300, None),
    ("plant_guild_b", "Grande plante de guilde", "decor", "Ranger Guild Indoors.png", 32, 640, 32, 64, 1, 1, 320, None),
    ("flower_display_white", "Présentoir de fleurs blanches", "decor", "Flower Shop.png", 96, 128, 64, 64, 2, 1, 380, None),
    ("flower_display_red", "Présentoir de fleurs rouges", "decor", "Flower Shop.png", 128, 128, 64, 64, 2, 1, 380, None),
    ("flower_tower", "Colonne de plantes", "decor", "Flower Shop.png", 160, 64, 32, 96, 1, 2, 420, None),
    ("stool_wood", "Tabouret en bois", "decor", "Flower Shop.png", 160, 160, 32, 64, 1, 1, 120, None),
    ("museum_fossil_case", "Vitrine fossile", "decor", "Museum interior.png", 0, 320, 128, 160, 4, 3, 1600, None),
    ("museum_plant_light", "Plante de musée claire", "decor", "Museum interior.png", 192, 320, 32, 64, 1, 1, 330, None),
    ("museum_plant_dark", "Plante de musée sombre", "decor", "Museum interior.png", 224, 320, 32, 64, 1, 1, 330, None),
    ("museum_sofa_yellow", "Canapé jaune", "decor", "Museum interior.png", 160, 544, 96, 96, 3, 1, 760, None),
    ("museum_display_round", "Présentoir rond", "decor", "Museum interior.png", 64, 672, 32, 32, 1, 1, 260, None),
]

SOURCE_TILESETS = [
    "Interior general.png", "Rustboro Inside.png", "Fortree City Homes.png",
    "bases.png", "Trick House.png", "SS Tidal.png", "Flower Shop.png",
    "Weather Institute.png", "Ranger Guild Indoors.png", "Museum interior.png",
    "Lilycove Museum.png", "Boat.png", "Game Corner interior.png",
    "Department store interior.png", "Poke Centre interior.png",
    "Mart interior.png", "Mauville Bike Shop.png", "Outfit Store.png",
    "Daycare.png", "Mansion interior.png", "Lilycove Department Store.png"
]

def clean_image(source, box):
    original = Image.open(TILES / source)
    image = original.convert("RGBA").crop(box)
    # Indexed tilesets normally carry their own transparency. A few older sheets
    # instead use pure black as the transparent colour.
    if "transparency" not in original.info and original.mode == "P":
        pixels = list(image.getdata())
        image.putdata([(r, g, b, 0 if (r, g, b) == (0, 0, 0) else a)
                       for r, g, b, a in pixels])
    return image

def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    SPRITES.mkdir(parents=True)
    SOURCES.mkdir(parents=True)
    catalog = []
    previews = []
    for key, name, category, source, x, y, w, h, fw, fh, price, interaction in ITEMS:
        image = clean_image(source, (x, y, x + w, y + h))
        image.save(SPRITES / f"{key}.png")
        previews.append((key, name, image.copy()))
        catalog.append({
            "key": key, "name": name, "category": category,
            "footprint_w": fw, "footprint_h": fh,
            "blocking": category != "floor", "price": price,
            "currency": "money", "interactive_type": interaction,
            "rotatable": False, "min_tier": 1, "tradable": True,
            "sprite": f"Graphics/Pictures/Housing/{key}",
            "image_w": w, "image_h": h, "source_tileset": source
        })
    for source in SOURCE_TILESETS:
        shutil.copy2(TILES / source, SOURCES / source)
    (OUT / "housing_catalog.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    (OUT / "README.txt").write_text(
        "Pack de meubles pour Pokemon MMO Eternal Emerald\n"
        f"{len(catalog)} sprites PNG individuels + {len(SOURCE_TILESETS)} tilesets sources.\n"
        "Copier Graphics/Pictures/Housing dans le projet puis fusionner housing_catalog.json avec le catalogue du mode amenagement.\n",
        encoding="utf-8")

    cell_w, cell_h, cols = 180, 150, 5
    rows = (len(previews) + cols - 1) // cols
    sheet = Image.new("RGB", (cell_w * cols, cell_h * rows), "white")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for i, (key, name, image) in enumerate(previews):
        cx, cy = (i % cols) * cell_w, (i // cols) * cell_h
        scale = min(1, 112 / image.width, 92 / image.height)
        shown = image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.Resampling.NEAREST)
        sheet.paste(shown, (cx + (cell_w-shown.width)//2, cy + 4), shown)
        draw.text((cx + 5, cy + 102), key, fill="black", font=font)
        draw.text((cx + 5, cy + 119), name, fill=(50, 50, 50), font=font)
    sheet.save(OUT / "preview.png")

    zip_path = OUT.parent / "Housing-Furniture-Pack.zip"
    if zip_path.exists(): zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in OUT.rglob("*"):
            if path.is_file(): archive.write(path, path.relative_to(OUT))
    print(json.dumps({"items": len(catalog), "sources": len(SOURCE_TILESETS),
                      "folder": str(OUT), "zip": str(zip_path)}, ensure_ascii=False))

if __name__ == "__main__":
    main()
