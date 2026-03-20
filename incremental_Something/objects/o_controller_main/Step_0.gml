
if gen_timer > gen_interval {
	gen_timer = 0
	
	if global.smasher_lvl > 0 {
		instance_create_layer(0, 0, "Instances", o_proton_blaster)

	}
	
}

gen_timer ++