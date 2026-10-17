extends SceneTree
## Executável do simulador (adaptador: lê argumentos e grava o relatório).
##
## godot --headless --path game -s res://sim/run_campaign.gd --
##     --bots casual,skilled --seeds 30 --out caminho.json
## Normalmente chamado por tools/sim/simulate.py.


func _init() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var db := ContentLoader.load_dir()
	var campaign := Campaign.new(db)
	var runs: Array[Dictionary] = []
	var seeds: int = int(args.get("seeds", "10"))
	var first_seed: int = int(args.get("first-seed", "1"))
	for bot_id: String in String(args.get("bots", "casual,skilled")).split(","):
		for i in seeds:
			runs.append(campaign.run(bot_id, first_seed + i))
	var report := {
		"version": ProjectSettings.get_setting("application/config/version", ""), "runs": runs
	}
	var out_path: String = args.get("out", "user://campaign_report.json")
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("Não consegui gravar %s" % out_path)
		quit(1)
		return
	file.store_string(JSON.stringify(report))
	file.close()
	print("SIM_REPORT %s (%d campanhas)" % [out_path, runs.size()])
	quit(0)


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	var i := 0
	while i < raw.size():
		if raw[i].begins_with("--") and i + 1 < raw.size():
			parsed[raw[i].substr(2)] = raw[i + 1]
			i += 2
		else:
			i += 1
	return parsed
