if !global.paused {
	
	if global.elements.ele_H.amt >= global.smasher_cost {
		global.elements.ele_H.amt -= global.smasher_cost
		global.smasher_lvl++
		Smasher_cost()
		
		with(o_controller_main) {
			gen_interval = max(5, 300 / global.smasher_lvl)
		}
	}
	
}
			