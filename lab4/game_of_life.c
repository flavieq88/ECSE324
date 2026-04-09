/**
* Part 3: Game of Life
* Implemented and working functionalities:
*   - drawing lines
*   - drawing rectangles
*   - game logic initialization
**/

#define VGA_PIX_ADDR 0xC8000000
#define VGA_CHAR_ADDR 0xC9000000
#define PS2_ADDR 0xFF200100
	
#define MAX_PIX_X 319
#define MAX_PIX_Y 239
#define MAX_CHAR_X 79
#define MAX_CHAR_Y 59
	
#define BACKGROUND 0xCD99 // color for background
#define FILL 0x0000 // color for grid lines and filled rectangles
	
// DRIVERS 
	
// VGA drivers
// Draws a point on the screen at the specified (x, y) coordinates in the indicated color c.
// Verifies that the given coordinates are valid (x in [0, 319] and y in [0, 239]).
void VGA_draw_point_ASM(int x, int y, short c) {
    if (x < 0 || x > MAX_PIX_X || y < 0 || y > MAX_PIX_Y) {
		return;
	}
	// pointer to memory mapped I/O for VGA
	volatile unsigned char *addr = (volatile unsigned char*) (VGA_PIX_ADDR | (y << 10) | (x << 1));
	*addr = c; 
	*(addr + 1) = c >> 8; // write both bytes
}

// Clears (sets to BACKGROUND) all the valid memory locations in the pixel buffer.
void VGA_clear_pixelbuff_ASM() {
	for (int x = 0; x <= MAX_PIX_X; x++) {
		for (int y = 0; y <= MAX_PIX_Y; y++) {
			VGA_draw_point_ASM(x, y, BACKGROUND);
		}
	}
}

// Writes the ASCII code c to the screen at (x, y) coordinate.
// Checks whether the coordinates supplied are valid (x in [0, 79], y in [0, 59]).
void VGA_write_char_ASM(int x, int y, char c) {
	if (x < 0 || x > MAX_CHAR_X || y < 0 || y > MAX_CHAR_Y) {
		return;
	}
	// pointer to memory mapped I/O for VGA
	volatile unsigned char *addr = (volatile unsigned char*) (VGA_CHAR_ADDR | (y << 7) | x);
	*addr = c; 
}

// Clears (sets to 0) all the valid memory locations in the character buffer.
void VGA_clear_charbuff_ASM() {
	for (int x = 0; x <= MAX_CHAR_X; x++) {
		for (int y = 0; y <= MAX_CHAR_Y; y++) {
			VGA_write_char_ASM(x, y, 0);
		}
	}
}

// PS/2 driver
int read_PS2_data_ASM(char *data);


// Fills pixels in a line from (x1, y1) to (x2, y2) in a horizontal or vertical line in the color c.
void VGA_draw_line(int x1, int y1, int x2, int y2, short c) {
	if (!(x1==x2 || y1==y2)) return; // not valid points for line (must be horizontal or vertical)
	if (x1 == x2) {
		// draw vertical line
		// lower and upper bound for y coordinate
		int low = y1;
		int high = y2;
		if (low > high) {
			low = y2;
			high = y1;
		}
		for (int y=low; y <= high; y++) {	
			VGA_draw_point_ASM(x1, y, c);
		}
	} else { // y1 == y2 
		// draw horizontal line
		int low = x1;
		int high = x2;
		if (low > high) {
			low = x2;
			high = x1;
		}
		for (int x=low; x <= high; x++) {	
			VGA_draw_point_ASM(x, y1, c);
		}
	}
}

// Draws a rectangle from pixel (x1, y1) to (x2, y2) in color c.
void VGA_draw_rect(int x1, int y1, int x2, int y2, short c) {
	int low_x = x1;
	int high_x = x2;
	if (x1 > x2) {
		low_x = x2;
		high_x = x1;
	}
	int low_y = y1;
	int high_y = y2;
	if (y1 > y2) {
		low_y = y2;
		high_y = y1;
	}
	// fill the rectangle using lines
	for (int x = low_x; x <= high_x; x++) {
		VGA_draw_line(x, low_y, x, high_y, c);
	}
}

// Draws a 16x12 grid in color c.
void GoL_draw_grid(short c) {
	// Draw all horizontal lines
	for (int y = 0; y <= MAX_PIX_Y; y += (MAX_PIX_Y+1)/12) {
		VGA_draw_line(0, y, MAX_PIX_X, y, c);
	}
	VGA_draw_line(0, MAX_PIX_Y, MAX_PIX_X, MAX_PIX_Y, c); // additional line at the end
	// Draw all vertical lines
	for (int x = 0; x <= MAX_PIX_X; x += (MAX_PIX_X+1)/16) {
		VGA_draw_line(x, 0, x, MAX_PIX_Y, c);
	}
	VGA_draw_line(MAX_PIX_X, 0, MAX_PIX_X, MAX_PIX_Y, c); // additional line at the end
}

// Fills the area of grid location (x, y) with color c.
// Verifies that the grid location is valid (x in [0, 15], y in [0, 11]).
void GoL_fill_gridxy(int x, int y, short c) {
	if (x < 0 || x >= 16 || y < 0 || y >= 12) {
		return; //invalid grid location
	}
	// compute the x1, y1, x2, y2 for rectangle fill
	int x1 = x * ((MAX_PIX_X+1)/16) + 1;
	int x2 = (x+1) * ((MAX_PIX_X+1)/16) - 1;
	int y1 = y * ((MAX_PIX_Y+1)/12) + 1;
	int y2 = (y+1) * ((MAX_PIX_Y+1)/12) - 1;
	// adjust if at the last column or row since it's 1 less pixel
	if (x == 15) {
		x2 -= 1;
	}
	if (y == 11) {
		y2 -= 1;
	}
	VGA_draw_rect(x1, y1, x2, y2, c);
}

void GoL_draw_board(int board[12][16], short c) {
	for (int x = 0; x < 16; x++) {
		for (int y = 0; y < 12; y++) {
			if (board[y][x] == 1) {
				GoL_fill_gridxy(x, y, c); // fill rectangle if 1 in board
			}
		}
	}
}

// main program: game logic
int main() {
	VGA_clear_charbuff_ASM();
	VGA_clear_pixelbuff_ASM();
	GoL_draw_grid(FILL);
	
	// initialize the board
	int GoLBoard[12][16] = {
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0},
		{0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},					   
	};
	
	GoL_draw_board(GoLBoard, FILL);
	
	return 0;
}



