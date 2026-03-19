global.dust = 0
global.orbs = 0
global.smasher_lvl = 0
global.smasher_cost = int64(10)
global.elements = {
	
	ele_P: {
		
		unlocked: true,
		index:	0,
		cost:	0,
		amt:	infinity,
		value:	1,
	},
	
	ele_H: {
		
		unlocked: false,
		index:	1,
		cost:	100,
		amt:	0,
		value:	5
	},
	
	ele_He: {
				
		unlocked: false,
		index:	2,
		cost:	1000,
		amt:	0,
		value:	10
	},
	ele_Li: {
				
		unlocked: false,
		index:	3,
		cost:	10000,
		amt:	0,
		value:	15
	},
	ele_Be: {
				
		unlocked: false,
		index:	4,
		cost:	100000,
		amt:	0,
		value:	20
	},
	
}

global.current_ele	= global.elements.ele_P
