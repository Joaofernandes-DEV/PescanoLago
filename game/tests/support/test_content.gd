class_name TestContent
extends RefCounted
## Apoio aos testes: conteúdo real de game/content, lido uma vez por execução.

static var _cached: ContentDB
static var _cached_full: ContentDB


## ContentDB compartilhado (não alterar: use docs() para montar variações).
static func db() -> ContentDB:
	if _cached == null:
		_cached = ContentLoader.load_dir()
	return _cached


## ContentDB do lago inteiro (perfil "full" de release.json, Fase 6), compartilhado.
static func full_db() -> ContentDB:
	if _cached_full == null:
		_cached_full = ContentLoader.load_dir(ContentLoader.DEFAULT_DIR, "full")
	return _cached_full


## Cópia nova dos documentos JSON, para testes que precisam mudar algum valor.
static func docs() -> Dictionary:
	var result: Dictionary = {}
	for file_name in ContentDB.FILES:
		var text: String = FileAccess.get_file_as_string("res://content/%s.json" % file_name)
		result[file_name] = JSON.parse_string(text)
	return result
