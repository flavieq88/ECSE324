#include <stdio.h>
#include <stdlib.h>

short matrix[4][4] = { {0, 1, 2, 3}, {4, 5, 6, 7}, 
	{8, 9, 10, 11}, {12, 13, 14, 15} };
short vector[4*4] = {0};

int main(int argc, char* argv[]) {
	int n=4;

	int row=0;
	int col=0;
	int seq=0;
	int dir=1;

	for (; seq<n*n; seq++) {
		vector[seq] = matrix[row][col];
		printf("%i\n", vector[seq]);

		if (dir == 1) {
			if (col == n-1) {
				row++;
				dir = -1;
			} else if (row == 0) {
				col++;
				dir = -1;
			} else {
				col++;
				row--;
			}
		} else {
			if (row == n-1) {
				col++;
				dir = 1;
			} else if (col == 0) {
				row++;
				dir = 1;
			} else {
				col--;
				row++;
			}
		}
	}

	return 0;
}
