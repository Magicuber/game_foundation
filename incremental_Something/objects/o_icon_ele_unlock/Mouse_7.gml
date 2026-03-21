if !global.paused {
	
	if global.elements[$ global.next_unlock].amt >= global.elements[$ global.next_unlock].cost {
		global.elements[$ global.next_unlock].amt -= global.elements[$ global.next_unlock].cost
		global.elements[$ global.next_unlock].unlocked = true
		global.max_ele = global.next_unlock
		
		global.current_ele = global.elements[$ global.next_unlock]
		global.elements[$ global.next_unlock].show_in_counter = true
		global.next_unlock = global.current_ele.produces
		
		with(o_element) {
			image_index = global.current_ele.index
		}
	}
	
}
			