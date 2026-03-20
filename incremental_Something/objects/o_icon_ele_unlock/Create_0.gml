if global.ele_unlock_lvl == 0 {
	elock = instance_create_layer(x,y,"Instances",o_lock)
	

} else {
	elock = noone
	
}

text_to_draw = string(global.ele_unlock_lvl) + "H"