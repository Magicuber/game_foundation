if !visible { exit }

// Scroll via mouse wheel
var wheel = mouse_wheel_up() - mouse_wheel_down()
scroll_y = clamp(scroll_y - wheel * scroll_speed, 0, max(0, max_scroll))

// Clamp scroll for touch/drag (optional future extension)
var total_rows = array_length(upgrades)
max_scroll = max(0, total_rows * row_h - panel_h + row_padding)