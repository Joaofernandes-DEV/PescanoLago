class_name CoolerPanel
extends PanelContainer
## Vista de dentro da caixa de isopor (Fase 7, P-37): com a tampa aberta e a
## câmera em cima da caixa, este cartão lista os peixes guardados, com o nome e o
## peso, do mais recente ao mais antigo. A lista tem todos os peixes do viveiro,
## mesmo os que a caixa não desenha (CoolerBox mostra só alguns, para ficar leve).
## A lista vai em colunas de até ROWS_PER_COLUMN linhas, para o viveiro maior
## (25 peixes) caber na tela.

const VARIANT_NAMES: Dictionary = {"albino": "albino", "golden": "dourado"}
const ROWS_PER_COLUMN: int = 13

var title_label: Label
var close_hint: ControlHints
var _columns: HBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiTheme.panel_box(18))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(340, 0)
	add_child(box)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	box.add_child(title_label)
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 28)
	box.add_child(_columns)
	close_hint = ControlHints.new()
	box.add_child(close_hint)
	visible = false


## Abre a vista com os peixes (do mais antigo ao mais recente) e a capacidade.
func open(fish: Array[FishCatch], capacity: int, db: ContentDB, touch: bool = false) -> void:
	title_label.text = "Caixa de isopor: %d de %d peixes" % [fish.size(), capacity]
	var rows := PackedStringArray()
	if fish.is_empty():
		rows.append("Nenhum peixe ainda.")
	for i in range(fish.size() - 1, -1, -1):
		var item: FishCatch = fish[i]
		var species_name: String = db.species(item.species_id)["common_name"]
		var variant: String = String(VARIANT_NAMES.get(item.variant, ""))
		if not variant.is_empty():
			species_name += " %s" % variant
		rows.append("%s - %s" % [species_name, DayController.weight_text(item.weight_kg)])
	for child in _columns.get_children():
		_columns.remove_child(child)
		child.queue_free()
	for start in range(0, rows.size(), ROWS_PER_COLUMN):
		var column := Label.new()
		column.add_theme_font_size_override("font_size", 19)
		column.add_theme_constant_override("line_spacing", 4)
		column.text = "\n".join(rows.slice(start, start + ROWS_PER_COLUMN))
		_columns.add_child(column)
	close_hint.show_hint("cooler_close", touch)
	visible = true


func close() -> void:
	visible = false


## Quantas colunas a lista ocupa.
func column_count() -> int:
	return _columns.get_child_count()


## Linhas da lista, como aparecem (para os testes).
func lines() -> PackedStringArray:
	var result := PackedStringArray()
	for column in _columns.get_children():
		result.append_array((column as Label).text.split("\n"))
	return result
