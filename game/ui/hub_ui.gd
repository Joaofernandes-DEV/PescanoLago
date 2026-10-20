class_name HubUi
extends CanvasLayer
## Interface de Porto Manso (P-23): mapa dos dias com estrelas, região, meta e o
## que falta para liberar cada dia (P-26); oficina do Tio Zeca (melhorias do
## barco); Armazém da Marô (varas, peças extras, iscas naturais e artificiais) e
## o álbum com as fichas (P-28). Só lê o estado e emite pedidos; quem compra é o
## HubController, pelo Shop.

signal day_selected(day_number: int)
signal play_pressed
signal upgrade_requested(upgrade_id: String)
signal rod_requested(rod_id: String)
signal rod_equip_requested(rod_id: String)
signal bait_requested(bait_id: String)
signal bait_equip_requested(bait_id: String)
signal artificial_bait_requested(bait_id: String)
signal part_requested(part_id: String)
signal part_install_requested(part_id: String)
signal part_remove_requested(part_id: String)

const STAR_PX: float = 24.0
const TAB_DAYS: int = 0
const TAB_WORKSHOP: int = 1
const TAB_STORE: int = 2
const TAB_ALBUM: int = 3
## Textos do que falta para liberar um dia (Progression.missing_for_day).
const UPGRADE_SHORT: Dictionary = {
	"motor": "motor",
	"hull": "casco",
	"livewell": "viveiro",
	"sonar": "sonar",
	"lights": "farol",
	"comfort": "conforto",
}

var status_label: Label
var message_label: Label
var tabs: TabContainer
var days_box: VBoxContainer
var goal_label: Label
var workshop_box: VBoxContainer
var store_box: VBoxContainer
var album_panel: AlbumPanel
var play_button: Button
## Estrela 3D desenhada uma vez; as estrelas do mapa usam a mesma imagem. (Os glifos
## ★ e ☆ não existem na fonte da build web.)
var star_icon: HudIcon

var _db: ContentDB
var _state: PlayerState
var _shop: Shop
var _selected_day: int = 1


func setup(db: ContentDB, state: PlayerState, shop: Shop) -> void:
	_db = db
	_state = state
	_shop = shop


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.build()
	add_child(root)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(16, 16)
	root.add_child(status_panel)
	var status_box := VBoxContainer.new()
	status_panel.add_child(status_box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	status_box.add_child(title_row)
	title_row.add_child(HudIcon.create("coin", 40.0))
	var title := Label.new()
	title.text = "Porto Manso"
	title.add_theme_font_size_override("font_size", 28)
	title_row.add_child(title)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	status_box.add_child(status_label)

	star_icon = HudIcon.create("star", 1.0)
	star_icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root.add_child(star_icon)

	tabs = TabContainer.new()
	tabs.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	tabs.offset_left = -560
	tabs.offset_right = -16
	tabs.offset_top = 16
	tabs.offset_bottom = -110
	root.add_child(tabs)
	days_box = _add_tab("Mapa dos dias")
	workshop_box = _add_tab("Oficina do Tio Zeca")
	store_box = _add_tab("Armazém da Marô")
	var album_scroll := ScrollContainer.new()
	album_scroll.name = "Álbum"
	album_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(album_scroll)
	album_panel = AlbumPanel.new()
	album_scroll.add_child(album_panel)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -100
	bottom.offset_bottom = -16
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	message_label.add_theme_constant_override("outline_size", 6)
	bottom.add_child(message_label)
	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.custom_minimum_size = Vector2(320, 48)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.pressed.connect(_on_play_pressed)
	bottom.add_child(play_button)
	refresh()


func _add_tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	return box


func set_selected_day(day_number: int) -> void:
	_selected_day = day_number
	refresh()


func set_message(text: String) -> void:
	message_label.text = text


## Redesenha tudo a partir do estado (depois de cada compra ou troca).
func refresh() -> void:
	if status_label == null:
		return
	status_label.text = (
		"\n"
		. join(
			PackedStringArray(
				[
					"Moedas: %d" % _state.coins,
					"Vendas totais: %d moedas" % _state.total_sales,
					"Barco: nível %d" % _state.boat_level(),
					"Vara: %s" % _db.rod(_state.equipped_rod)["name"],
					(
						"Isca: %s (%d)"
						% [
							_db.bait(_state.equipped_bait)["name"],
							_state.bait_count(_state.equipped_bait)
						]
					),
				]
			)
		)
	)
	_fill_days()
	_fill_workshop()
	_fill_store()
	album_panel.fill(_db, _state)
	play_button.text = "Pescar — dia %d" % _selected_day


func _clear(box: Container) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _heading(box: Container, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	box.add_child(label)


func _row(box: Container, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	return row


func _button(row: Container, button_name: String, text: String, enabled: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.disabled = not enabled
	row.add_child(button)
	return button


func _fill_days() -> void:
	_clear(days_box)
	var count: int = _db.day_count()
	for day_number in range(1, count + 1):
		var unlocked: bool = Progression.can_play(_db, _state, day_number)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		days_box.add_child(row)
		var region: String = _db.region(_db.day(day_number)["region"])["name"]
		var text: String = "Dia %d — %s" % [day_number, region]
		var missing := Progression.missing_for_day(_db, _state, day_number)
		# O próximo dia a liberar diz o que falta numa linha própria; os outros, só "bloqueado".
		var next_to_unlock: bool = (
			not unlocked and (day_number == 1 or _state.stars_of(day_number - 1) > 0)
		)
		if not unlocked and not next_to_unlock:
			text += "   (bloqueado)"
		var button := _button(row, "Day_%d" % day_number, text, unlocked)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if next_to_unlock:
			var need := Label.new()
			need.name = "Missing_%d" % day_number
			need.text = "      " + missing_text(missing)
			need.add_theme_font_size_override("font_size", 16)
			need.add_theme_color_override("font_color", Color("ffd27a"))
			days_box.add_child(need)
		button.toggle_mode = true
		button.button_pressed = day_number == _selected_day
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_day_pressed.bind(day_number))
		if unlocked:
			var stars := _star_row(_state.stars_of(day_number))
			stars.name = "Stars_%d" % day_number
			row.add_child(stars)
	var day_def: Dictionary = _db.day(_selected_day)
	var seconds: int = int(day_def["duration_s"])
	goal_label = Label.new()
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.text = (
		"Dia %d — meta: %s\nTempo: %d:%02d   Pontuação-alvo: %d (2 e 3 estrelas pedem mais)"
		% [
			_selected_day,
			GoalText.describe(day_def["goal"], _db),
			seconds / 60,
			seconds % 60,
			int(day_def["target_score"]),
		]
	)
	days_box.add_child(goal_label)


## O que falta para jogar o dia, em português ("falta: barco nível 2, sonar 2").
func missing_text(missing: Array[Dictionary]) -> String:
	var parts := PackedStringArray()
	for need in missing:
		match String(need["type"]):
			"stars":
				return "falta 1 estrela no dia %d" % int(need["day"])
			"day":
				parts.append("a partir do dia %d" % int(need["day"]))
			"boat_level":
				parts.append("barco nível %d" % int(need["level"]))
			"upgrade":
				parts.append(
					"%s %d" % [UPGRADE_SHORT.get(need["id"], need["id"]), int(need["level"])]
				)
	return "falta: " + ", ".join(parts)


func _fill_workshop() -> void:
	_clear(workshop_box)
	_heading(workshop_box, "Melhorias do Esperança")
	for upgrade_id in _db.upgrade_ids():
		if not _db.is_enabled("upgrades", upgrade_id):
			continue
		var upgrade: Dictionary = _db.upgrade(upgrade_id)
		var level: int = _state.level_of(upgrade_id)
		var max_level: int = _db.upgrade_max_level(upgrade_id)
		var current: Dictionary = _db.upgrade_level(upgrade_id, level)
		var text: String = (
			"%s — nível %d/%d: %s\n%s"
			% [upgrade["name"], level, max_level, current["name"], upgrade["purpose"]]
		)
		var price: int = _shop.upgrade_price(_state, upgrade_id)
		if price == Shop.NO_PRICE:
			_button(_row(workshop_box, text), "Upgrade_%s" % upgrade_id, "Nível máximo", false)
			continue
		var next_name: String = _db.upgrade_level(upgrade_id, level + 1)["name"]
		var row := _row(workshop_box, text + "\nPróximo: %s" % next_name)
		var button := _button(
			row, "Upgrade_%s" % upgrade_id, "Comprar (%d)" % price, _state.coins >= price
		)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))


func _fill_store() -> void:
	_clear(store_box)
	_heading(store_box, "Varas")
	for rod_id: String in _db.release["enabled_rods"]:
		var rod: Dictionary = _db.rod(rod_id)
		var text: String = (
			"%s — alcance %d m, linha %d kg"
			% [rod["name"], int(rod["range_m"]), int(rod["line_strength_kg"])]
		)
		var mounted := PackedStringArray()
		for part_id: String in _state.parts_on(rod_id):
			mounted.append(_db.rod_parts[part_id]["name"])
		if not mounted.is_empty():
			text += "\nPeças: " + ", ".join(mounted)
		var row := _row(store_box, text)
		if _state.equipped_rod == rod_id:
			_button(row, "Rod_%s" % rod_id, "Equipada", false)
		elif _state.owned_rods.has(rod_id):
			var equip := _button(row, "Rod_%s" % rod_id, "Equipar", true)
			equip.pressed.connect(_on_rod_equip_pressed.bind(rod_id))
		else:
			var price: int = int(rod["cost"])
			var buy := _button(
				row, "Rod_%s" % rod_id, "Comprar (%d)" % price, _state.coins >= price
			)
			buy.pressed.connect(_on_rod_pressed.bind(rod_id))
	_heading(store_box, "Iscas (lote de %d)" % _db.lot_size())
	for bait_id: String in _db.release["enabled_baits"]:
		if not _db.is_natural_bait(bait_id):
			continue
		var bait: Dictionary = _db.bait(bait_id)
		var row := _row(
			store_box, "%s — %d no estoque" % [bait["name"], _state.bait_count(bait_id)]
		)
		var price: int = _shop.bait_lot_price(bait_id)
		var buy := _button(
			row, "Bait_%s" % bait_id, "Comprar lote (%d)" % price, _state.coins >= price
		)
		buy.pressed.connect(_on_bait_pressed.bind(bait_id))
		if _state.equipped_bait == bait_id:
			_button(row, "EquipBait_%s" % bait_id, "Equipada", false)
		else:
			var equip := _button(
				row, "EquipBait_%s" % bait_id, "Equipar", _state.bait_count(bait_id) > 0
			)
			equip.pressed.connect(_on_bait_equip_pressed.bind(bait_id))
	_fill_artificial_baits()
	_fill_parts()


## Iscas artificiais: compra o nível 1 e sobe até o 3; não acabam (GDD p. 7).
func _fill_artificial_baits() -> void:
	var any: bool = false
	for bait_id: String in _db.release["enabled_baits"]:
		if _db.bait(bait_id)["type"] != "artificial":
			continue
		if not any:
			_heading(store_box, "Iscas artificiais (não acabam; 3 níveis)")
			any = true
		var level: int = _state.artificial_level(bait_id)
		var row := _row(store_box, "%s — nível %d/3" % [_db.bait(bait_id)["name"], level])
		var price: int = _shop.artificial_bait_price(_state, bait_id)
		if price == Shop.NO_PRICE:
			_button(row, "Lure_%s" % bait_id, "Nível máximo", false)
		else:
			var label: String = (
				"Comprar (%d)" % price if level == 0 else "Nível %d (%d)" % [level + 1, price]
			)
			var buy := _button(row, "Lure_%s" % bait_id, label, _state.coins >= price)
			buy.pressed.connect(_on_artificial_bait_pressed.bind(bait_id))
		if _state.equipped_bait == bait_id:
			_button(row, "EquipBait_%s" % bait_id, "Equipada", false)
		else:
			var equip := _button(row, "EquipBait_%s" % bait_id, "Equipar", level > 0)
			equip.pressed.connect(_on_bait_equip_pressed.bind(bait_id))


## Peças extras: cada uma é comprada uma vez e vai na vara equipada (até 2 por vara).
func _fill_parts() -> void:
	var parts: Array = _db.release.get("enabled_rod_parts", [])
	if parts.is_empty():
		return
	_heading(store_box, "Peças extras da vara (até %d por vara)" % _db.part_slots)
	var on_rod: Array = _state.parts_on(_state.equipped_rod)
	for part_id: String in parts:
		var part: Dictionary = _db.rod_parts[part_id]
		var row := _row(store_box, String(part["name"]))
		if not _state.owned_rod_parts.has(part_id):
			var price: int = int(part["cost"])
			var buy := _button(
				row, "Part_%s" % part_id, "Comprar (%d)" % price, _state.coins >= price
			)
			buy.pressed.connect(_on_part_pressed.bind(part_id))
		elif on_rod.has(part_id):
			var remove := _button(row, "Part_%s" % part_id, "Tirar da vara", true)
			remove.pressed.connect(_on_part_remove_pressed.bind(part_id))
		else:
			var free: bool = on_rod.size() < _db.part_slots
			var install := _button(row, "Part_%s" % part_id, "Montar na vara", free)
			install.pressed.connect(_on_part_install_pressed.bind(part_id))


## Três estrelas: acesas até `lit`, as outras apagadas.
func _star_row(lit: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for i in 3:
		var star := TextureRect.new()
		star.texture = star_icon.texture
		star.custom_minimum_size = Vector2(STAR_PX, STAR_PX)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.modulate = UiTheme.STAR_ON if i < lit else UiTheme.STAR_OFF
		row.add_child(star)
	return row


## Quantas estrelas acesas o mapa mostra para o dia (testes).
func stars_shown(day_number: int) -> int:
	var row := find_child("Stars_%d" % day_number, true, false)
	if row == null:
		return -1
	var lit: int = 0
	for star in row.get_children():
		if (star as TextureRect).modulate == UiTheme.STAR_ON:
			lit += 1
	return lit


## Botão pelo nome (testes e piloto automático).
func find_button(button_name: String) -> Button:
	return find_child(button_name, true, false) as Button


func _on_day_pressed(day_number: int) -> void:
	_selected_day = day_number
	day_selected.emit(day_number)
	refresh()


func _on_play_pressed() -> void:
	play_pressed.emit()


func _on_upgrade_pressed(upgrade_id: String) -> void:
	upgrade_requested.emit(upgrade_id)


func _on_rod_pressed(rod_id: String) -> void:
	rod_requested.emit(rod_id)


func _on_rod_equip_pressed(rod_id: String) -> void:
	rod_equip_requested.emit(rod_id)


func _on_bait_pressed(bait_id: String) -> void:
	bait_requested.emit(bait_id)


func _on_bait_equip_pressed(bait_id: String) -> void:
	bait_equip_requested.emit(bait_id)


func _on_artificial_bait_pressed(bait_id: String) -> void:
	artificial_bait_requested.emit(bait_id)


func _on_part_pressed(part_id: String) -> void:
	part_requested.emit(part_id)


func _on_part_install_pressed(part_id: String) -> void:
	part_install_requested.emit(part_id)


func _on_part_remove_pressed(part_id: String) -> void:
	part_remove_requested.emit(part_id)
