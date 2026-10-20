class_name Album
extends RefCounted
## Álbum de peixes (GDD: "17 espécies + variantes, com ficha educativa"; P-28).
## Cada espécie e cada variante (albina, dourada) é um item do álbum. A ficha de
## uma espécie aparece quando ela é pescada pela primeira vez.


## Espécies na ordem de species.json.
static func species_ids(db: ContentDB) -> PackedStringArray:
	return db.species_ids()


## Regiões ligadas onde a espécie aparece nesta versão (vazia: ainda não dá
## para pescá-la). No MVP, as incomuns aparecem na Margem Rasa (P-01).
static func regions_of(db: ContentDB, species_id: String) -> Array[String]:
	var result: Array[String] = []
	for region_id: String in db.release["enabled_regions"]:
		for spawn: Dictionary in db.region(region_id)["spawns"]:
			if spawn["species"] != species_id:
				continue
			if spawn.get("mvp_only", false) and not db.is_mvp():
				continue
			result.append(region_id)
			break
	return result


static func catchable(db: ContentDB, species_id: String) -> bool:
	return not regions_of(db, species_id).is_empty()


## Variantes desta versão que a espécie pode ter (pela raridade).
static func variants_for(db: ContentDB, species_id: String) -> Array[String]:
	var result: Array[String] = []
	var config: Dictionary = db.economy["variants"]
	var eligible: Array = config["eligible_rarities"]
	if not eligible.has(db.species(species_id)["rarity"]):
		return result
	for variant_type: Dictionary in config["types"]:
		if db.is_enabled("variants", variant_type["id"]):
			result.append(variant_type["id"])
	return result


## Quantos itens do álbum o jogador já tem e quantos existem nesta versão:
## {"found", "total", "species_found", "species_total"}.
static func progress(db: ContentDB, state: PlayerState) -> Dictionary:
	var found: int = 0
	var total: int = 0
	var species_found: int = 0
	for species_id in species_ids(db):
		var variants: Array[String] = variants_for(db, species_id)
		total += 1 + variants.size()
		if not state.album.has(species_id):
			continue
		species_found += 1
		found += 1
		var seen: Array = state.album[species_id]["variants"]
		for variant in variants:
			if seen.has(variant):
				found += 1
	return {
		"found": found,
		"total": total,
		"species_found": species_found,
		"species_total": species_ids(db).size(),
	}
