int sum(int *array, int length) {
    int answer = 0;
    for (int index=0; index<length; index++)
        answer += array[index];

    return answer;
} // sum

int main(int argc, char* argv[]) {
    int a[4] = {1, 2, 3, 4};
    int b[8] = {2, 3, 5, 7, 11, 13, 17, 19};

    int a_s = sum((int *) a, 4); // 10
    int b_s = sum((int *) b, 8); // 77
    
    return 0;
} // main