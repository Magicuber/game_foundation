if y < room_height + 30 || y > room_height - 30 || x < room_width + 30 || x > room_width - 30{
	x += lengthdir_x(exit_vel, direction)
	y += lengthdir_y(exit_vel, direction)
	exit_vel -= 1
	
} else {
	instance_destroy()
}