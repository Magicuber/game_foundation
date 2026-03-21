if x < -30 || x > room_width + 30 || y < -30 || y > room_height + 30 {
    instance_destroy()
} else {
	x += lengthdir_x(exit_vel, direction)
	y += lengthdir_y(exit_vel, direction)
	exit_vel -= 1
} 