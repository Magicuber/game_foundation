next = Get_Ele_By_Index(global.current_ele.index + 1)
if next.unlocked {
	image_blend = c_white
} else {
	image_blend = c_dkgrey
}

draw_self()
