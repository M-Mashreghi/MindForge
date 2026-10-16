extends RefCounted
## Sanitizer and safety gate for any text that came from an AI provider
## (hints, explanations, flavor). Raw provider text is never shown: only
## the `text` returned by sanitize() with ok = true may reach the UI.
##
## sanitize() strips control characters and markup ([bbcode], <html>),
## collapses whitespace, and then REJECTS (never silently rewrites) text
## that is empty, longer than the display limit, contains links or e-mail
## addresses, shouts, or falls outside the game's tone policy: calm,
## family-friendly, and never judging the player.

const SANITIZER_VERSION := "ai-text-v1"
const DEFAULT_MAX := 160

## Words outside the tone policy (violence, sexual content, hate, self-harm,
## and labels for the player). Matched as whole words, case-insensitively.
const BLOCKED := [
	"kill", "killing", "murder", "blood", "gore", "suicide", "die", "dead", "death",
	"sex", "sexy", "porn", "nude", "hate", "nazi", "racist", "drugs", "gun", "bomb",
	"stupid", "dumb", "idiot", "moron", "loser", "weak", "pathetic", "useless", "failure",
]


## Returns {"ok": bool, "text": String, "reason": String}.
static func sanitize(raw: Variant, max_length: int = DEFAULT_MAX) -> Dictionary:
	if typeof(raw) != TYPE_STRING:
		return _reject("not_text")
	var text: String = raw
	# Strip control characters (keep normal spaces).
	var cleaned := ""
	for ch in text:
		var code := ch.unicode_at(0)
		if code == 9 or code == 10 or code == 13:
			cleaned += " "
		elif code >= 32 and code != 127 and not (code >= 0x200B and code <= 0x200F) and code != 0x2028 and code != 0x2029:
			cleaned += ch
	# Strip markup the UI could interpret.
	cleaned = RegEx.create_from_string("\\[[^\\]]*\\]").sub(cleaned, "", true)
	cleaned = RegEx.create_from_string("<[^>]*>").sub(cleaned, "", true)
	cleaned = cleaned.replace("[", "").replace("]", "").replace("<", "").replace(">", "")
	cleaned = RegEx.create_from_string("\\s+").sub(cleaned, " ", true).strip_edges()
	var reason := problem(cleaned, max_length)
	if reason != "":
		return _reject(reason)
	return {"ok": true, "text": cleaned, "reason": ""}


## "" when already-clean text is acceptable, otherwise the reason.
static func problem(text: String, max_length: int = DEFAULT_MAX) -> String:
	if text.strip_edges().is_empty():
		return "empty"
	if text.length() > max_length:
		return "too_long"
	for ch in text:
		if ch.unicode_at(0) < 32:
			return "control_character"
	if "[" in text or "]" in text or "<" in text or ">" in text:
		return "markup"
	var lowered := text.to_lower()
	if "http" in lowered or "www." in lowered or "://" in lowered or RegEx.create_from_string("\\b[\\w.]+\\.(com|net|org|io|gg|ru|xyz)\\b").search(lowered):
		return "link"
	if RegEx.create_from_string("[\\w.+-]+@[\\w-]+\\.[\\w.]+").search(lowered):
		return "email"
	for word in BLOCKED:
		if RegEx.create_from_string("\\b%s\\b" % word).search(lowered) != null:
			return "tone_policy"
	if _shouting(text):
		return "shouting"
	if "!!" in text or "??" in text:
		return "excessive_punctuation"
	return ""


static func _shouting(text: String) -> bool:
	var letters := 0
	var upper := 0
	for ch in text:
		if ch.to_lower() != ch.to_upper():
			letters += 1
			if ch == ch.to_upper():
				upper += 1
	return letters >= 12 and float(upper) / letters > 0.6


static func _reject(reason: String) -> Dictionary:
	return {"ok": false, "text": "", "reason": reason}
