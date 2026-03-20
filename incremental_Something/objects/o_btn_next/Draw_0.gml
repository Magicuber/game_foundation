next = Get_Ele_By_Index(global.current_ele.index + 1)
if next.unlocked {
	image_blend = c_white
} else {
	image_blend = c_dkgrey
}

draw_self()


draw_set_font(fnt_menu)
draw_set_colour(c_black)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_text(x, y, btn_txt)
