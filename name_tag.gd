extends Label

@export var max_font_size: int = 64
@export var min_font_size: int = 12

func shrink_to_fit():
	var font = get_theme_font("font")
	var current_size = max_font_size
	
	# Loop down from max size until the text width fits within the label width
	while current_size > min_font_size:
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, current_size)
		if text_size.x <= size.x:
			break
		current_size -= 1
		
	# Apply the newly calculated font size override
	add_theme_font_size_override("font_size", current_size)
