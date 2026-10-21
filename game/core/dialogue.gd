class_name Dialogue
extends RefCounted
## Uma conversa de balões (Fase 7, Bloco B; P-39): as falas de dialogues.json na
## ordem, cada uma com quem fala, o texto e o estilo do balão (say, shout ou
## whisper). O texto aparece aos poucos, em letras por segundo (a velocidade dos
## balões nas configurações; 0 = a fala inteira de uma vez), e o jogador avança
## com um clique: se a fala ainda está aparecendo, ela se completa; se já está
## inteira, vem a próxima. Depois da última, a conversa termina.
##
## Só a regra: o balão, a voz e a boca mexendo ficam na cena (DialoguePlayer).

## O que um clique fez.
enum Press { COMPLETED_LINE, NEXT_LINE, FINISHED, IGNORED }

const DEFAULT_STYLE: String = "say"

var id: String
var lines: Array
## Fala atual (0 = a primeira).
var index: int = 0
var chars_per_s: float
var finished: bool = false

var _revealed: float = 0.0


## dialogue: um item de dialogues.json (id e lines).
func _init(dialogue: Dictionary, p_chars_per_s: float) -> void:
	id = String(dialogue["id"])
	lines = dialogue["lines"]
	chars_per_s = p_chars_per_s
	assert(not lines.is_empty(), "Diálogo sem falas: %s" % id)


func line() -> Dictionary:
	return {} if finished else lines[index]


func speaker() -> String:
	return String(line().get("speaker", ""))


func text() -> String:
	return String(line().get("text", ""))


func style() -> String:
	return String(line().get("style", DEFAULT_STYLE))


## Quantas letras da fala atual já aparecem.
func revealed_count() -> int:
	var length: int = text().length()
	if chars_per_s <= 0.0:
		return length
	return mini(int(_revealed), length)


func revealed_text() -> String:
	return text().substr(0, revealed_count())


func is_line_complete() -> bool:
	return revealed_count() >= text().length()


## A fala atual ainda está aparecendo (quem fala mexe a boca).
func is_typing() -> bool:
	return not finished and not is_line_complete()


## Avança o tempo; devolve o trecho de texto que apareceu agora (a cena toca a voz
## a cada poucas letras).
func advance(dt: float) -> String:
	if not is_typing():
		return ""
	var before: int = revealed_count()
	_revealed += dt * chars_per_s
	return text().substr(before, revealed_count() - before)


## Clique do jogador.
func press() -> Press:
	if finished:
		return Press.IGNORED
	if not is_line_complete():
		_revealed = float(text().length())
		return Press.COMPLETED_LINE
	if index + 1 >= lines.size():
		finished = true
		return Press.FINISHED
	index += 1
	_revealed = 0.0
	return Press.NEXT_LINE


## Pula a conversa inteira (as cutscenes do item 2 podem ser puladas).
func skip() -> void:
	finished = true


## Quantas letras há no trecho (espaços e pontuação não fazem voz).
static func letter_count(chunk: String) -> int:
	var count: int = 0
	for character: String in chunk:
		if character.to_upper() != character.to_lower():
			count += 1
	return count
