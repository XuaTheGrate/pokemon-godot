extends DMDialogueProcessor

const COLOR_REPLACEMENTS = {
	"[m]": "[color=#3050C8]",
	"[f]": "[color=#E00808]"
}

func _preprocess_line(raw_line: String) -> String:
	for k in COLOR_REPLACEMENTS.keys():
		raw_line = raw_line.replace(k, COLOR_REPLACEMENTS[k])
	return raw_line
