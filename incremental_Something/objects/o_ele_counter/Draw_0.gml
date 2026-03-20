draw_self()

draw_set_font(fnt_menu)
draw_set_colour(c_black)
draw_set_halign(fa_left)
draw_set_valign(fa_top)
//draw_text(x,y,"H:"+string(global.elements.ele_H.amt))

var ele_names = variable_struct_get_names(global.elements)
var col_width = 216
var row_height = 75
var padding = 10
var slot = 0

for (var i = 0; i < array_length(ele_names); i++) {
    var ele = global.elements[$ ele_names[i]]
    
    if ele.show_in_counter {
        var col = slot mod 5
        var row = slot div 5
        
        draw_text(x - 540 + (col * col_width) + padding, y - 75 + (row * row_height) - padding, ele.name + ": " + string(ele.amt))
        slot++
    }
}