class_name ContentLoader
extends RefCounted
## Adaptador: lê game/content/*.json do disco e monta o ContentDB do núcleo.
## profile_id escolhe o perfil de release.json (vazio = o perfil ativo).
## A história (elenco e roteiros dos balões) vai para o StoryContent (load_story).

const DEFAULT_DIR: String = "res://content"


static func load_dir(dir_path: String = DEFAULT_DIR, profile_id: String = "") -> ContentDB:
	var docs: Dictionary = _read_all(dir_path, ContentDB.FILES)
	return null if docs.is_empty() else ContentDB.new(docs, profile_id)


static func load_story(dir_path: String = DEFAULT_DIR) -> StoryContent:
	var docs: Dictionary = _read_all(dir_path, StoryContent.FILES)
	return null if docs.is_empty() else StoryContent.new(docs)


## {nome: documento} dos arquivos pedidos; vazio se algum não abre ou não é JSON.
static func _read_all(dir_path: String, file_names: PackedStringArray) -> Dictionary:
	var docs: Dictionary = {}
	for file_name in file_names:
		var path: String = "%s/%s.json" % [dir_path, file_name]
		var text: String = FileAccess.get_file_as_string(path)
		if text.is_empty():
			push_error(
				"ContentLoader: não consegui ler %s (%s)" % [path, FileAccess.get_open_error()]
			)
			return {}
		var parsed: Variant = JSON.parse_string(text)
		if not parsed is Dictionary:
			push_error("ContentLoader: %s não é um objeto JSON válido" % path)
			return {}
		docs[file_name] = parsed
	return docs
