/* Example of using "parallel" block */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <time.h>

#define do_omp
int main() {
	// task: add 10 to each element of x
	int N = 500000;
	int x[500000];
    int i;

	srand(time(NULL));
	// print initial data
	for (i = 0; i < N; i++) {
         x[i]=rand();
    }

#ifdef do_omp
	// process data
	#pragma omp parallel num_threads(4)
	{
		int tid = omp_get_thread_num();
		int chunk_size = N / omp_get_num_threads();
		int start_idx = tid * chunk_size;
		int end_idx = (tid == omp_get_num_threads()-1) ? N : start_idx + chunk_size;
		int idx;
#else 
        {
        int start_idx = 0;
        int end_idx = N;
        int idx;
#endif
		for (idx = start_idx; idx < end_idx; idx++) {
			//printf("thread %d processed element %d of x\n", omp_get_thread_num(), idx);
			x[idx] += 10;
		}
	}

	// print results
    //for (i = 0; i < N; i++) {
        //printf("%d ", x[i]);
    //}
    printf("\n");

    // done
    exit(0);
}
