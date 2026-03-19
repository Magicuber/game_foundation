function Smasher_cost(){
	
	newCost = global.smasher_cost + power(1.5, global.smasher_lvl)
	global.smasher_cost = int64(newCost)
}