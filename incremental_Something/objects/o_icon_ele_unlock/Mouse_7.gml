if !global.paused {
	
	if global.elements[$ global.current_ele.produces].amt >= global.elements[$ global.next_unlock].cost {
		global.elements[$ global.current_ele.produces].amt -= global.elements[$ global.next_unlock].cost
		global.elements[$ global.current_ele.produces].unlocked = true

		global.current_ele = global.elements[$ global.current_ele.produces]
		global.elements[$ global.current_ele.produces].show_in_counter = true
		global.next_unlock = global.current_ele.produces
		with(o_element) {
			image_index = global.current_ele.index
		}
	}
	
}
			