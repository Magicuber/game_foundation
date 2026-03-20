global.dust = 0
global.orbs = 0
global.smasher_lvl = 0
global.smasher_cost = int64(10)
global.elements = {
	
	ele_P: {
		name: "P",
		unlocked: true,
		index:	0,
		cost:	0,
		amt:	infinity,
		produces: "ele_H",
		show_in_counter: false,
	},
	
	ele_H: {
		name: "H",
		unlocked: false,
		index:	1,
		cost:	100,
		amt:	1000,
		produces: "ele_He",
		show_in_counter: true,
	},
	
	ele_He: {
		name: "He",	
		unlocked: false,
		index:	2,
		cost:	10,
		amt:	0,
		produces: "ele_Li",
		show_in_counter: false,
	},
	ele_Li: {
		name: "Li",	
		unlocked: false,
		index:	3,
		cost:	10,
		amt:	0,
		produces: "ele_Be",
		show_in_counter: false,
	},
	ele_Be: {
		name: "Be",		
		unlocked: false,
		index:	4,
		cost:	10,
		amt:	0,
		produces: "ele_B",
		show_in_counter: false,
	},
	ele_B: {
		name: "B",
		unlocked: false,
		index:	5,
		cost:	10,
		amt:	0,
		produces: "ele_C",
		show_in_counter: false,
	},
	ele_C: {
		name: "C",
		unlocked: false,
		index:	6,
		cost:	10,
		amt:	0,
		produces: "ele_N",
		show_in_counter: false,
	},
	ele_N: {
		name: "N",
		unlocked: false,
		index:	7,
		cost:	10,
		amt:	0,
		produces: "ele_O",
		show_in_counter: false,
	},
	ele_O: {
		name: "O",
		unlocked: false,
		index:	8,
		cost:	10,
		amt:	0,
		produces: "ele_F",
		show_in_counter: false,
	},
	ele_F: {
		name: "F",
		unlocked: false,
		index:	9,
		cost:	10,
		amt:	0,
		produces: "ele_Ne",
		show_in_counter: false,
	},
	ele_Ne: {
		name: "Ne",
		unlocked: false,
		index:	10,
		cost:	10,
		amt:	0,
		produces: "Dust",
		show_in_counter: false,
	},
	
}

global.current_ele	= global.elements.ele_P
