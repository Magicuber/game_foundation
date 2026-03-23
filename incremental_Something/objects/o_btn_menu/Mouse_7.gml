if (opened) {
	layer_set_visible(layer_name, false)	
	image_index = 0
	opened = !opened
} else {
	layer_set_visible(layer_name, true)
	image_index = 1
	opened = !opened
}