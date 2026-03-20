if !global.paused {
	
	if global.elements.ele_H.amt >= global.ele_unlock_cost {
		global.elements.ele_H.amt -= global.ele_unlock_cost
		global.ele_unlock_lvl++
		Ele_unlock_cost()
		global.current_ele = global.elements.ele_H
		
		with(o_element) {
			image_index = global.current_ele.index
		}
	}
	
}
			