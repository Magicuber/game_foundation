if visible {
	draw_set_alpha(0.9)
    draw_set_colour(c_dkgray)
    draw_rectangle(100, 200, 980, 1700, false)
    draw_set_alpha(1)
    
    draw_set_font(fnt_menu)
    draw_set_colour(c_white)
    draw_set_halign(fa_center)
    draw_text(540, 250, "UPGRADES")
}