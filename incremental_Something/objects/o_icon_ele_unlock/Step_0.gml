if !global.paused {
	
	if global.elements.ele_H.amt >= global.elements[$ global.current_ele.produces].cost {
		if instance_exists(elock) {
			instance_destroy(elock)
		}
	}
	
	text_to_draw = string(global.elements[$ global.current_ele.produces].cost) + " : " + global.current_ele.produces
	
}