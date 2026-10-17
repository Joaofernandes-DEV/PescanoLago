class_name SaveService
extends RefCounted
## Adaptador: grava e lê o save em arquivo (briefing, seção 3.4).
##
## O formato e as migrações são do núcleo (SaveCodec); aqui só há disco:
## - escrita atômica: grava slot_N.json.tmp, guarda o save anterior como
##   slot_N.json.bak e só então troca o .tmp pelo arquivo do slot;
## - leitura com recuperação: se o arquivo do slot faltar ou estiver corrompido,
##   carrega a cópia de segurança.

enum Source { NONE, SLOT, BACKUP }

const DEFAULT_DIR: String = "user://saves"
const VERSION_SETTING: String = "application/config/version"

var dir_path: String
var slot: int
## De onde veio o último load_state() (SLOT, BACKUP ou NONE).
var loaded_from: Source = Source.NONE
## Motivo da última falha de leitura ou escrita ("" se não houve).
var last_error: String = ""


func _init(p_dir_path: String = DEFAULT_DIR, p_slot: int = 1) -> void:
	dir_path = p_dir_path
	slot = p_slot


func path() -> String:
	return "%s/slot_%d.json" % [dir_path, slot]


func backup_path() -> String:
	return path() + ".bak"


func temp_path() -> String:
	return path() + ".tmp"


func has_save() -> bool:
	return FileAccess.file_exists(path()) or FileAccess.file_exists(backup_path())


static func game_version() -> String:
	return String(ProjectSettings.get_setting(VERSION_SETTING, ""))


func save(state: PlayerState) -> bool:
	last_error = ""
	var made: Error = DirAccess.make_dir_recursive_absolute(dir_path)
	if made != OK:
		return _fail("não consegui criar a pasta %s (%s)" % [dir_path, error_string(made)])
	var text: String = JSON.stringify(SaveCodec.encode(state, game_version()), "  ")
	var file := FileAccess.open(temp_path(), FileAccess.WRITE)
	if file == null:
		return _fail(
			"não consegui gravar %s (%s)" % [temp_path(), error_string(FileAccess.get_open_error())]
		)
	file.store_string(text)
	file.close()
	if FileAccess.file_exists(path()):
		if FileAccess.file_exists(backup_path()):
			DirAccess.remove_absolute(backup_path())
		var backed_up: Error = DirAccess.rename_absolute(path(), backup_path())
		if backed_up != OK:
			return _fail("não consegui guardar a cópia de segurança (%s)" % error_string(backed_up))
	var moved: Error = DirAccess.rename_absolute(temp_path(), path())
	if moved != OK:
		return _fail("não consegui trocar o save pelo novo (%s)" % error_string(moved))
	return true


## PlayerState do slot (ou da cópia de segurança), ou null se não houver save válido.
func load_state() -> PlayerState:
	last_error = ""
	loaded_from = Source.NONE
	var state: PlayerState = _read(path())
	if state != null:
		loaded_from = Source.SLOT
		return state
	var slot_error: String = last_error
	state = _read(backup_path())
	if state != null:
		loaded_from = Source.BACKUP
		last_error = slot_error
		return state
	if not slot_error.is_empty():
		last_error = slot_error
	return null


## Apaga o slot e a cópia de segurança (novo jogo).
func erase() -> void:
	for file_path: String in [path(), backup_path(), temp_path()]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)


func _read(file_path: String) -> PlayerState:
	if not FileAccess.file_exists(file_path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if not parsed is Dictionary:
		last_error = "%s não é um JSON válido" % file_path
		return null
	var problem: String = SaveCodec.validate(parsed)
	if not problem.is_empty():
		last_error = "%s: %s" % [file_path, problem]
		return null
	var state: PlayerState = SaveCodec.decode(parsed)
	if state == null:
		last_error = "%s: faltam campos do progresso" % file_path
	return state


func _fail(message: String) -> bool:
	last_error = message
	push_warning("SaveService: " + message)
	return false
