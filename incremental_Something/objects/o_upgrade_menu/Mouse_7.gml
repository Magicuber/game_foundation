if !visible { exit }

var mx = mouse_x
var my = mouse_y
var num = array_length(upgrades)
var row_x = panel_x + row_padding
var row_w = panel_w - row_padding * 2

for (var i = 0; i < num; i++) {
    var entry   = upgrades[i]
    var row_top = (panel_y + 110) + i * row_h - scroll_y

    var btn_x1 = row_x + row_w - 180
    var btn_y1 = row_top + 120
    var btn_x2 = row_x + row_w - 20
    var btn_y2 = row_top + 180

    if point_in_rectangle(mx, my, btn_x1, btn_y1, btn_x2, btn_y2) {
        entry.buy_func()
        break
    }
}