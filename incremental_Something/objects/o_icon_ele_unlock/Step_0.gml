if !global.paused {
	
	if global.elements.ele_H.amt >= global.ele_unlock_cost {
		if instance_exists(elock) {
			instance_destroy(elock)
		}
	}
	
	text_to_draw = string(global.ele_unlock_cost) + "H"
	
}