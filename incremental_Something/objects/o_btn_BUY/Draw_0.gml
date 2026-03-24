if global.elements.ele_H.amt >= global.smasher_cost {
	image_blend = c_white
} else {
	image_blend = c_dkgrey
}
draw_self()
draw_set_font(fnt_cost)
draw_set_colour(c_black)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_text(x,y,text_to_draw)
