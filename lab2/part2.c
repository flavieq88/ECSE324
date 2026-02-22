#include <stdio.h>
#include <stdlib.h>

int recaman(unsigned int num, unsigned char *array);
int search(int tgt, unsigned char *array, unsigned int size);

int main(int argc, char* argv[]) {
	if (argc != 2) {
		printf("Must provide 0 <= N < 100 for number of Recaman numbers\n"); 
		return 1;
	}
	int n = atoi(argv[1]);
	printf("Calculating the first %i Recaman numbers\n", n+1);
	char result[101] = {0};
	recaman(n, result);
	for (int i=0; i<=n; i++) {
		printf("%i\n", result[i]);
	}
}

int recaman(unsigned int num, unsigned char *array) {
	if (num == 0) {
		array[num] = 0;
		return 0;
	}

	unsigned int prev = 0;
	int rnums = 0;
	unsigned int rnuma = 0;
	
	prev = recaman(num-1, array);

	rnums = prev - num;
	rnuma = prev + num;

	if ((rnums > 0) && (search(rnums, array, num-1) < 0))
		array[num] = rnums;
	else
		array[num] = rnuma;
	return array[num];
}

int search(int tgt, unsigned char *array, unsigned int size) {
	int idx = -1;

	for (int i=0; i<size; i++) {
		if (array[i] == tgt) {
			idx = i;
			break;
		}
	}
	return idx;
}
