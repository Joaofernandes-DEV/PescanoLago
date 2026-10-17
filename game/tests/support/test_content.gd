class_name TestContent
extends RefCounted
## Apoio aos testes: conteúdo real de game/content, lido uma vez por execução.

static var _cached: ContentDB


## ContentDB compartilhado (não alterar: use docs() para montar variações).
static func db() -> ContentDB:
	if _cached == null:
		_cached = ContentLoader.load_dir()
	return _cached


## Cópia nova dos documentos JSON, para testes que precisam mudar algum valor.
static func docs() -> Dictionary:
	var result: Dictionary = {}
	for file_name in ContentDB.FILES:
		var text: String = FileAccess.get_file_as_string("res://content/%s.json" % file_name)
		result[file_name] = JSON.parse_string(text)
	return result
