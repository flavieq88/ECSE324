/**
* Part 3: Game of Life
* Implemented and working functionalities:
*   - drawing lines
*   - drawing rectangles
*   - game logic: initialization
* 	- game logic: changing the playing field
* 	- game logic: state update
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
#define CURSOR_ACTIVE 0x520A // cursor color on an active cell
#define CURSOR_INACTIVE 0xFF5F // cursor color on an inactive cell
	
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
// Checks the RVALID bit in the PS/2 data register. If valid, data is read and stored
// at the given address data and returns 1. Else, returns 0.
int read_PS2_data_ASM(char *data) {
	// pointer to memory mapped I/O for VGA
	volatile unsigned char *addr = (volatile unsigned char*) PS2_ADDR;
	int rvalid = (addr[1] >> 7) & 0x1; //get the 15th bit
	if (rvalid == 0) {
		return 0;
	}
	// get final byte of ps2 data and store in data
	*data = *addr;
	return 1;
}


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
		return; // invalid grid location
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

// Fills grid locations (x, y) within range with color c if board[y][x] == 1.
void GoL_draw_board(int board[12][16], short c) {
	for (int x = 0; x < 16; x++) {
		for (int y = 0; y < 12; y++) {
			if (board[y][x] == 1) {
				GoL_fill_gridxy(x, y, c); // fill rectangle if 1 in board
			} 
		}
	}
}

// Fills grid location (cx, cy) within range with cursor color.
// Color of cursor depends on if the cell is active (1) or inactive (0).
void GoL_draw_cursor(int board[12][16], int cx, int cy) {
	if (cx < 0 || cx >= 16 || cy < 0 || cy >= 12) {
		return; // invalid grid location
	}
	if (board[cy][cx] == 1) {
		GoL_fill_gridxy(cx, cy, CURSOR_ACTIVE); // fill rectangle with active color if 1 in board
	} else {
		GoL_fill_gridxy(cx, cy, CURSOR_INACTIVE); // fill rectangle with active color if 1 in board
	}
}

// Fills grid location (cx, cy) within range with normal color.
// Color of cell depends on if the cell is active (1) or inactive (0).
void GoL_erase_cursor(int board[12][16], int cx, int cy) {
	if (cx < 0 || cx >= 16 || cy < 0 || cy >= 12) {
		return; // invalid grid location
	}
	if (board[cy][cx] == 1) {
		GoL_fill_gridxy(cx, cy, FILL); // fill rectangle with active color if 1 in board
	} else {
		GoL_fill_gridxy(cx, cy, BACKGROUND); // fill rectangle with active color if 1 in board
	}
}

int num_neighbors(int board[12][16], int x, int y) {
	if (x < 0 || x >= 16 || y < 0 || y >= 12) {
		return -1; // invalid grid location
	}
	int n = 0;
	// check all 8 neighbours around, add if active
	if (x > 0 && y > 0) { // upper left
		n += board[y-1][x-1];
	}
	if (y > 0) { // upper
		n += board[y-1][x];
	}
	if (x < 15 && y > 0) { // upper right
		n += board[y-1][x+1];
	}
	if (x > 0) { // left
		n += board[y][x-1];
	}
	if (x < 15) { // right
		n += board[y][x+1];
	}
	if (x > 0 && y < 11) { // lower left
		n += board[y+1][x-1];
	}
	if (y < 11) { // lower
		n += board[y+1][x];
	}
	if (x < 15 && y < 11) { // lower right
		n += board[y+1][x+1];
	}
	return n;
}

void GoL_update_board(int board[12][16]) {
	// create a copy of the current board
	int prev[12][16];
	for (int x = 0; x < 16; x++) {
		for (int y = 0; y < 12; y++) {
			prev[y][x] = board[y][x];
		}
	}
	for (int x = 0; x < 16; x++) {
		for (int y = 0; y < 12; y++) {
			// get number of neighbours
			int n = num_neighbors(prev, x, y);
			// if cell was active
			if (prev[y][x]) {
				if (n == 0 || n == 1) {
					// Any active cell with 0 or 1 active neighbors becomes inactive
					board[y][x] = 0;
					GoL_fill_gridxy(x, y, BACKGROUND); // erase cell to make it inactive
				} else if (n == 2 || n == 3) {
					// Any active cell with 2 or 3 active neighbors remains active.
					board[y][x] = 1;
				} else if (n >= 4) {
					// Any active cell with 4 or more active neighbors becomes inactive.
					board[y][x] = 0;
					GoL_fill_gridxy(x, y, BACKGROUND); // erase cell to make it inactive
				}
			} else { // if cell was inactive
				if (n == 3) {
					// Any inactive cell with exactly 3 active neighbors becomes active.
					board[y][x] = 1;
				}
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
	// intialize cursor position
	int cx = 0;
	int cy = 0;
	
	GoL_draw_board(GoLBoard, FILL);
	GoL_draw_cursor(GoLBoard, cx, cy);
	
	char data; 
	int read;
	int process = 0;
	
	// infinite polling
	while (1) {
		// check user input
		read = read_PS2_data_ASM(&data);
		if (read) {
			if (data == 0xF0) { // distinguish between make and break
				process = 1;
				continue;
			}
			if (!process) {
				continue;
			}
			process = 0;
			switch (data) {
				case (0x1D): // W
					// move cursor up (lower y)
					if (cy > 0) {
						GoL_erase_cursor(GoLBoard, cx, cy);
						cy--;
					}
					break;
				case (0x1C): // A
					// move cursor left (lower x)
					if (cx > 0) {
						GoL_erase_cursor(GoLBoard, cx, cy);
						cx--;
					}
					break;
				case (0x1B): // S
					// move cursor down (higher y)
					if (cy < 11) {
						GoL_erase_cursor(GoLBoard, cx, cy);
						cy++;
					}
					break;
				case (0x23): // D
					// move cursor right (higher x)
					if (cx < 15) {
						GoL_erase_cursor(GoLBoard, cx, cy);
						cx++;
					}
					break;
				case (0x29): // space
					// toggle state of current cursor grid location
					if (GoLBoard[cy][cx] == 1) {
						GoLBoard[cy][cx] = 0;
					} else {
						GoLBoard[cy][cx] = 1;
					}
					GoL_draw_board(GoLBoard, FILL); // update board to user
					break;
				case (0x31): // N
					// update the GoLBoard to the next iteration
					GoL_update_board(GoLBoard);
					GoL_draw_board(GoLBoard, FILL); // update board to user
				default:
					break;
			}
		}
		// always show cursor
		GoL_draw_cursor(GoLBoard, cx, cy);
	}
	
	return 0;
}



