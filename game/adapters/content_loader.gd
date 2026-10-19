class_name ContentLoader
extends RefCounted
## Adaptador: lê game/content/*.json do disco e monta o ContentDB do núcleo.
## profile_id escolhe o perfil de release.json (vazio = o perfil ativo).

const DEFAULT_DIR: String = "res://content"


static func load_dir(dir_path: String = DEFAULT_DIR, profile_id: String = "") -> ContentDB:
	var docs: Dictionary = {}
	for file_name in ContentDB.FILES:
		var path: String = "%s/%s.json" % [dir_path, file_name]
		var text: String = FileAccess.get_file_as_string(path)
		if text.is_empty():
			push_error(
				"ContentLoader: não consegui ler %s (%s)" % [path, FileAccess.get_open_error()]
			)
			return null
		var parsed: Variant = JSON.parse_string(text)
		if not parsed is Dictionary:
			push_error("ContentLoader: %s não é um objeto JSON válido" % path)
			return null
		docs[file_name] = parsed
	return ContentDB.new(docs, profile_id)
