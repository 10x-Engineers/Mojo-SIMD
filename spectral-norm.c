#include <stdio.h> 
#include <stdlib.h>
#include <math.h>
#include <time.h>

void print_array(int N, const double arr[])
{
    int i;
    if (N <= 20) {
        for (i = 0; i < N; i++) {
            printf("%.9f ", arr[i]);
        }
    } else {
        for (i = 0; i < 10; i++) {
            printf("%.9f ", arr[i]);
        }
        printf("... ");

        for (i = N-10; i < N; i++) {
            printf("%.9f ", arr[i]);
        }
    }
    printf("\n");
}

double eval_A(int i, int j)
{
  return 1.0/((i+j)*(i+j+1)/2+i+1);
}

void eval_A_times_u(int N, const double u[], double Au[])
{
  int i,j;
  for(i=0;i<N;i++)
    {
      Au[i]=0;
      for(j=0;j<N;j++)
        Au[i]+=eval_A(i,j)*u[j];
    }
}

void eval_At_times_u(int N, const double u[], double Au[])
{
  int i,j;
  for(i=0;i<N;i++)
    {
      Au[i]=0;
      for(j=0;j<N;j++) Au[i]+=eval_A(j,i)*u[j];
    }
}

void eval_AtA_times_u(int N, const double u[], double AtAu[])
{
  double v[N];
  eval_A_times_u(N,u,v);
  eval_At_times_u(N,v,AtAu);
}

int main(int argc, char *argv[])
{
  clock_t start_time = clock();

  int i;
  const int N = ((argc == 2) ? atoi(argv[1]) : 5000);
  double u[N],v[N],vBv,vv;
  for(i=0;i<N;i++) u[i]=1;

  for(i=0;i<10;i++)
    {
      eval_AtA_times_u(N,u,v);
      eval_AtA_times_u(N,v,u);
    }
  vBv=vv=0;
  for(i=0;i<N;i++) { vBv+=u[i]*v[i]; vv+=v[i]*v[i]; }
  printf("%0.9f\n",sqrt(vBv/vv));

  clock_t end_time = clock();
  double time_taken = (double)(end_time - start_time) / CLOCKS_PER_SEC;
  printf("Time taken: %.6f seconds\n", time_taken);
  return 0;
}