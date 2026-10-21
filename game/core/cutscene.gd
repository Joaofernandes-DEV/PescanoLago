class_name Cutscene
extends RefCounted
## Uma cutscene em passos (Fase 7, Bloco B, item 2; P-40), de cutscenes.json:
## falar (talk), andar até (walk), gesto (gesture), câmera (camera), esperar
## (wait) e cartela (card). Os passos vão na ordem: o próximo começa quando o
## atual acaba, ou junto com ele se o atual tem "together". Passo com "seconds"
## acaba sozinho depois desse tempo (0 = na hora); os outros (falar e andar)
## acabam quando a cena avisa (complete). Pular dá a lista do que ainda não
## acabou, para a cena pôr cada coisa no lugar final.
##
## Só a ordem e o tempo: quem fala, anda e mexe a câmera é a cena (CutscenePlayer).

var id: String
var steps: Array
var finished: bool = false
var skipped: bool = false

## Próximo passo a começar.
var _next: int = 0
## Passo em andamento -> segundos que faltam (-1 = espera a cena avisar).
var _running: Dictionary = {}


## cutscene: um item de cutscenes.json (id e steps).
func _init(cutscene: Dictionary) -> void:
	id = String(cutscene["id"])
	steps = cutscene["steps"]
	assert(not steps.is_empty(), "Cutscene sem passos: %s" % id)


func step_at(index: int) -> Dictionary:
	return steps[index]


## Passos em andamento agora (índices).
func running() -> Array[int]:
	var result: Array[int] = []
	for index: int in _running:
		result.append(index)
	return result


## Avança o tempo: {"started": passos que começam agora, "ended": passos com
## tempo que acabaram agora}, na ordem.
func advance(dt: float) -> Dictionary:
	var started: Array[int] = []
	var ended: Array[int] = []
	if finished:
		return {"started": started, "ended": ended}
	for index: int in _running.keys():
		if float(_running[index]) < 0.0:
			continue
		_running[index] = float(_running[index]) - dt
		if float(_running[index]) <= 0.0:
			_running.erase(index)
			ended.append(index)
	while _next < steps.size() and not _blocked():
		var index: int = _next
		_next += 1
		started.append(index)
		var step: Dictionary = steps[index]
		if not step.has("seconds"):
			_running[index] = -1.0
		elif float(step["seconds"]) > 0.0:
			_running[index] = float(step["seconds"])
		else:
			ended.append(index)
	finished = _next >= steps.size() and _running.is_empty()
	return {"started": started, "ended": ended}


## A cena avisa que um passo sem tempo (falar, andar) acabou.
func complete(index: int) -> void:
	_running.erase(index)
	finished = _next >= steps.size() and _running.is_empty()


## Pula o resto: devolve os passos que estavam andando ou nem tinham começado,
## na ordem, para a cena pôr tudo no lugar final.
func skip() -> Array[int]:
	var left: Array[int] = running()
	for index in range(_next, steps.size()):
		left.append(index)
	left.sort()
	_running.clear()
	_next = steps.size()
	finished = true
	skipped = true
	return left


## Algum passo em andamento segura o próximo (não é "together").
func _blocked() -> bool:
	for index: int in _running:
		if not bool((steps[index] as Dictionary).get("together", false)):
			return true
	return false
