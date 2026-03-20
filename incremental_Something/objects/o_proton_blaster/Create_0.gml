target_x = room_width / 2
target_y = room_height / 2
image_index = 0
depth = 8
// Choose a random off-screen edge to spawn from (0=top, 1=bottom, 2=left, 3=right)
var edge = irandom(3);

switch (edge) {
    case 0: // Top
        x = irandom(room_width);
        y = -sprite_height;
        break;
    case 1: // Bottom
        x = irandom(room_width);
        y = room_height + sprite_height;
        break;
    case 2: // Left
        x = -sprite_width;
        y = irandom(room_height);
        break;
    case 3: // Right
        x = room_width + sprite_width;
        y = irandom(room_height);
        break;
}

// Point toward center and set speed
move_speed = 5;
direction = point_direction(x, y, target_x, target_y);
speed = move_speed;