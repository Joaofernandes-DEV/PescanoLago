class_name StoryContent
extends RefCounted
## Elenco (characters.json) e roteiros dos balões (dialogues.json) da campanha
## dos dias 1 a 8 (P-33), em memória e só para leitura (Fase 7, Bloco B). Quem lê
## os arquivos é o adaptador ContentLoader; os documentos já chegam validados.

const FILES: PackedStringArray = ["characters", "dialogues"]

var _characters: Dictionary = {}
var _dialogues: Dictionary = {}
var _dialogue_order: PackedStringArray = []


func _init(docs: Dictionary) -> void:
	for file_name in FILES:
		assert(docs.has(file_name), "StoryContent: falta o documento '%s'" % file_name)
	for entry: Dictionary in docs["characters"]["characters"]:
		_characters[entry["id"]] = entry
	for entry_dialogue: Dictionary in docs["dialogues"]["dialogues"]:
		_dialogues[entry_dialogue["id"]] = entry_dialogue
		_dialogue_order.append(String(entry_dialogue["id"]))


func has_character(character_id: String) -> bool:
	return _characters.has(character_id)


func character(character_id: String) -> Dictionary:
	assert(_characters.has(character_id), "Personagem desconhecido: %s" % character_id)
	return _characters[character_id]


## Nome no balão ("Avô", "Dona Cleusa").
func character_name(character_id: String) -> String:
	return String(character(character_id)["name"])


## Modelo do Blender (char_<modelo>.glb); quem ainda não tem o próprio usa o de
## outro personagem (stand_in).
func model_of(character_id: String) -> String:
	return String(character(character_id)["model"])


## Som da voz curta ("" = sem voz).
func voice_of(character_id: String) -> String:
	return String(character(character_id).get("voice", ""))


func has_dialogue(dialogue_id: String) -> bool:
	return _dialogues.has(dialogue_id)


func dialogue(dialogue_id: String) -> Dictionary:
	assert(_dialogues.has(dialogue_id), "Diálogo desconhecido: %s" % dialogue_id)
	return _dialogues[dialogue_id]


## Ids dos diálogos na ordem do arquivo; com day, só os desse dia.
func dialogue_ids(day: int = 0) -> PackedStringArray:
	var ids: PackedStringArray = []
	for dialogue_id in _dialogue_order:
		if day == 0 or int(_dialogues[dialogue_id]["day"]) == day:
			ids.append(dialogue_id)
	return ids


## Quem fala no diálogo, na ordem da primeira fala de cada um.
func speakers(dialogue_id: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for line: Dictionary in dialogue(dialogue_id)["lines"]:
		if not result.has(String(line["speaker"])):
			result.append(String(line["speaker"]))
	return result
