class_name AlbumPanel
extends VBoxContainer
## Aba do álbum em Porto Manso (P-28): uma ficha por espécie, com o nome
## científico, onde vive, uma curiosidade, o maior peso pescado e as variantes
## vistas. Espécie ainda não pescada aparece como "???", com a região onde
## procurar; espécie que esta versão ainda não tem fica marcada.

const RARITY_NAMES: Dictionary = {
	"common": "Comum",
	"uncommon": "Incomum",
	"rare": "Raro",
	"epic": "Épico",
	"legendary": "Lendário",
	"unique_legendary": "Lendário único",
}
const VARIANT_NAMES: Dictionary = {"albino": "albina", "golden": "dourada"}

var summary_label: Label


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)


## Redesenha o álbum a partir do estado.
func fill(db: ContentDB, state: PlayerState) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var progress: Dictionary = Album.progress(db, state)
	summary_label = Label.new()
	summary_label.add_theme_font_size_override("font_size", 20)
	summary_label.text = (
		"Álbum: %d de %d (espécies: %d de %d)"
		% [
			int(progress["found"]),
			int(progress["total"]),
			int(progress["species_found"]),
			int(progress["species_total"]),
		]
	)
	add_child(summary_label)
	for species_id in Album.species_ids(db):
		add_child(_card(db, state, species_id))


func _card(db: ContentDB, state: PlayerState, species_id: String) -> PanelContainer:
	var species: Dictionary = db.species(species_id)
	var panel := PanelContainer.new()
	panel.name = "Card_%s" % species_id
	var box := VBoxContainer.new()
	panel.add_child(box)
	var caught: bool = state.album.has(species_id)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 19)
	title.text = (
		"%s — %s" % [species["common_name"], RARITY_NAMES[species["rarity"]]]
		if caught
		else "??? — %s" % RARITY_NAMES[species["rarity"]]
	)
	box.add_child(title)
	box.add_child(_text(_details(db, state, species_id, caught)))
	return panel


func _details(db: ContentDB, state: PlayerState, species_id: String, caught: bool) -> String:
	var species: Dictionary = db.species(species_id)
	if not caught:
		if not Album.catchable(db, species_id):
			return "Ainda não aparece nesta versão do jogo."
		return "Ainda não pescado. Onde procurar: %s." % _regions(db, species_id)
	var lines := PackedStringArray()
	var scientific: String = species["scientific_name"]
	if species.get("fictional", false):
		scientific = "espécie fictícia"
	elif species["introduced_in_brazil"]:
		scientific += " — espécie introduzida no Brasil"
	lines.append(scientific)
	lines.append("Onde vive: %s" % species["card"]["habitat"])
	lines.append("Curiosidade: %s" % species["card"]["curiosity"])
	var entry: Dictionary = state.album[species_id]
	var record := (
		"Pescados: %d   Maior: %s"
		% [int(entry["caught"]), DayController.weight_text(float(entry["best_weight_kg"]))]
	)
	var variants: Array[String] = Album.variants_for(db, species_id)
	if not variants.is_empty():
		var seen := PackedStringArray()
		for variant in variants:
			var mark: String = "sim" if (entry["variants"] as Array).has(variant) else "não"
			seen.append("%s: %s" % [VARIANT_NAMES.get(variant, variant), mark])
		record += "   Variantes — " + ", ".join(seen)
	lines.append(record)
	return "\n".join(lines)


func _regions(db: ContentDB, species_id: String) -> String:
	var names := PackedStringArray()
	for region_id: String in Album.regions_of(db, species_id):
		names.append(db.region(region_id)["name"])
	return ", ".join(names)


func _text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	return label
