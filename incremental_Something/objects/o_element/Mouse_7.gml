if !global.paused {
	if global.can_fuse {
		fused = true
		global.elements[$ global.current_ele.produces].amt++
	}
}