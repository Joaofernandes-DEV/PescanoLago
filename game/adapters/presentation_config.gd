class_name PresentationConfig
extends RefCounted
## Adaptador: parâmetros de apresentação (game/content/presentation.json):
## lago, navegação, cardumes, câmera, lançamento, luz por período e água.

const DEFAULT_PATH: String = "res://content/presentation.json"

var data: Dictionary


static func load_default() -> PresentationConfig:
	var config := PresentationConfig.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_PATH))
	if not parsed is Dictionary:
		push_error("PresentationConfig: não consegui ler %s" % DEFAULT_PATH)
		return null
	config.data = parsed
	return config


func section(section_name: String) -> Dictionary:
	return data[section_name]


func number(section_name: String, key: String) -> float:
	return float(section(section_name)[key])


static func color(hex: String) -> Color:
	return Color.html(hex)
