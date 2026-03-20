function Smasher_cost(){
	
	newCost = global.smasher_cost + power(1.5, global.smasher_lvl)
	global.smasher_cost = int64(newCost)
}

function Ele_unlock_cost(){
	
	newCost = global.ele_unlock_cost + power(3, global.ele_unlock_lvl)
	global.ele_unlock_cost = int64(newCost)
}