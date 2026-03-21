if !visible { exit }

var px = panel_x
var py = panel_y
var pw = panel_w
var ph = panel_h

// --- Background panel ---
draw_set_alpha(0.95)
draw_set_colour(c_dkgray)
draw_roundrect(px, py, px + pw, py + ph, false)
draw_set_alpha(1)

// --- Title bar ---
draw_set_colour(c_black)
draw_roundrect(px, py, px + pw, py + 100, false)
draw_set_font(fnt_menu)
draw_set_colour(c_white)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_text(px + pw / 2, py + 50, "UPGRADES")

// --- Scissor / clip rows to panel ---
gpu_set_scissor(px, py + 100, pw, ph - 100)

var num = array_length(upgrades)
var row_x = px + row_padding
var row_w = pw - row_padding * 2

for (var i = 0; i < num; i++) {
    var entry   = upgrades[i]
    var row_top = (py + 110) + i * row_h - scroll_y
    var row_bot = row_top + row_h - row_padding

    // Skip rows fully outside the panel
    if row_bot < py + 100 || row_top > py + ph { continue }

    // Row background — highlight if affordable
    var can_buy = entry.available_func()
    draw_set_colour(can_buy ? c_green : c_gray)
    draw_set_alpha(0.3)
    draw_roundrect(row_x, row_top, row_x + row_w, row_bot, false)
    draw_set_alpha(1)

    // Row border
    draw_set_colour(can_buy ? c_lime : c_silver)
    draw_roundrect(row_x, row_top, row_x + row_w, row_bot, true)

    // Label
    draw_set_font(fnt_menu)
    draw_set_colour(c_white)
    draw_set_halign(fa_left)
    draw_set_valign(fa_top)
    draw_text(row_x + 20, row_top + 16, entry.label)

    // Level / current state
    draw_set_font(fnt_cost)
    draw_set_colour(c_yellow)
    draw_set_halign(fa_right)
    draw_text(row_x + row_w - 20, row_top + 16, entry.level_func())

    // Description
    draw_set_colour(c_silver)
    draw_set_halign(fa_left)
    draw_text(row_x + 20, row_top + 70, entry.description)

    // Cost
    draw_set_colour(can_buy ? c_lime : c_red)
    draw_set_halign(fa_left)
    draw_text(row_x + 20, row_top + 130, "Cost: " + entry.cost_func())

    // Buy button
    var btn_x1 = row_x + row_w - 180
    var btn_y1 = row_top + 120
    var btn_x2 = row_x + row_w - 20
    var btn_y2 = row_top + 180

    draw_set_colour(can_buy ? c_green : c_dkgray)
    draw_set_alpha(0.9)
    draw_roundrect(btn_x1, btn_y1, btn_x2, btn_y2, false)
    draw_set_alpha(1)
    draw_set_colour(c_white)
    draw_set_halign(fa_center)
    draw_set_valign(fa_middle)
    draw_set_font(fnt_cost)
    draw_text((btn_x1 + btn_x2) / 2, (btn_y1 + btn_y2) / 2, "BUY")
}

gpu_set_scissor(0, 0, display_get_gui_width(), display_get_gui_height())

// --- Scrollbar ---
var total_h   = array_length(upgrades) * row_h
var bar_track = ph - 120
if total_h > ph {
    var bar_h   = (ph / total_h) * bar_track
    var bar_y   = py + 110 + (scroll_y / max_scroll) * (bar_track - bar_h)
    draw_set_colour(c_white)
    draw_set_alpha(0.4)
    draw_roundrect(px + pw - 18, bar_y, px + pw - 6, bar_y + bar_h, false)
    draw_set_alpha(1)
}