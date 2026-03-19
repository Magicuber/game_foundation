if !global.paused {
	
	if fused {
		if fuse_stagger < fuse_stagger_total {
			global.can_fuse = false
			
			fuse_stagger++
		} else {
			instance_create_layer(x,y,"Instances",o_partical_spawning)
			fuse_stagger = 0
			global.can_fuse = true
			fused = false
		}
	}
	
}