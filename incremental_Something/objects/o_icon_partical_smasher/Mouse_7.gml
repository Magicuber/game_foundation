if !global.paused {
	
	if global.elements.ele_H.amt >= global.smasher_cost {
		global.elements.ele_H.amt -= global.smasher_cost
		global.smasher_lvl++
		Smasher_cost()
			
		}
	
}
			