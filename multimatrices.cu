#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define BLOCK_SIZE 16

__global__ 
void MultiMatrices(float *d_ma, float *d_mb, float *d_mp, int Width, int m, int n){
    
    int Row = blockIdx.y*blockDim.y+threadIdx.y;

    int Col = blockIdx.x*blockDim.x+threadIdx.x;

    if ((Row < m) && (Col < n)) { 
        float Pvalue = 0;
        
        for (int k = 0; k < Width; k++) {
            Pvalue += d_ma[Row*Width+k]*d_mb[k*n+Col];
        }   
        d_mp[Row*n+Col] = Pvalue;
    }

}

void MM_cpu(float *h_ma, float *h_mb, float *h_mp, int Width, int m, int n) {
    float Pvalue = 0;

    for(int Row = 0; Row < m; Row++) {
        for(int Col = 0; Col < n; Col++) {
            
            for (int k = 0; k < Width; k++) {
                Pvalue += h_ma[Row*Width+k]*h_mb[k*n+Col];
            }
            h_mp[Row*n+Col] = Pvalue;
            Pvalue = 0;
        }
    }
} 

void llenarMatriz(float *matrix, int x, int y, float v){
    for (int i = 0; i < x; i++) {       
        for (int j = 0; j < y; j++) {
            matrix[(i*y)+j] = v;
        }
    }
}


void imprimirMatriz(float *matrix, int x, int y){
    for (int i = 0; i < x; i++) {
        for (int j = 0; j < y; j++) {
            printf("%f ", matrix[(i*y)+j]);
        }
        printf("\n");
    }
}


int main(int argc, char *argv[]){
    //Programa <archivo>

    if ( argc != 2 ) {
        //Salir del programa
        printf("Fallo al ingresar el argumento\n");
    }
    else 
    {
        FILE *fp;
        float floatBuffer;

        int ma, ka, kb, nb;
        int m, k, n;
    
        float *h_a, *h_b, *h_c;
        float *d_a, *d_b, *d_c;

        fp = fopen (argv[1], "r");
        if (fp == NULL) {
            perror ("Error al abrir el archivo");
        }
        else
        {
                     
            fscanf(fp, "%d", &ma);
            fscanf(fp, "%d", &ka);

            cudaMallocHost((void **) &h_a, sizeof(float)*ma*ka);

            for (int i = 0; i < ma; i++) {
                for (int j = 0; j < ka; j++) {
                    fscanf(fp, "%f", &floatBuffer);
                    h_a[(i*ka) + j] = floatBuffer;
                }
            }
                
            fscanf(fp, "%d", &kb);
            fscanf(fp, "%d", &nb);

            cudaMallocHost((void **) &h_b, sizeof(float)*kb*nb);

            for (int i = 0; i < kb; i++) {
                for (int j = 0; j < nb; j++) {
                    fscanf(fp, "%f", &floatBuffer);
                    h_b[(i*nb) + j] = floatBuffer;
                }
            }
            
            fclose(fp);
        }

        if (ka != kb) {
            printf("la matriz no cumple con la condicion de multiplicatividad");
            return 0;
        }

        m = ma;
        k = ka;
        n = nb;               

        cudaMallocHost((void **) &h_c, sizeof(float)*m*n);
        llenarMatriz(h_c, m, n, 0);
                
        imprimirMatriz(h_a, m, k);
        imprimirMatriz(h_b, k, n);
        imprimirMatriz(h_c, m, n);
        
        //MM_cpu(h_a, h_b, h_c, k, m, n);
        
        //no hay que olvidarse de declarar espacio en el device
        cudaMalloc((void **) &d_a, sizeof(float)*m*k);
        cudaMalloc((void **) &d_b, sizeof(float)*k*n);
        cudaMalloc((void **) &d_c, sizeof(float)*m*n);
        
        

        cudaMemcpy(d_a, h_a, sizeof(float)*m*k, cudaMemcpyHostToDevice);
        cudaMemcpy(d_b, h_b, sizeof(float)*k*n, cudaMemcpyHostToDevice);
        cudaMemcpy(d_c, h_c, sizeof(float)*m*n, cudaMemcpyHostToDevice);

                

        unsigned int grid_rows = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;
        unsigned int grid_cols = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;

        dim3 dimGrid(grid_cols, grid_rows);
        dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);
   
        cudaError_t MMErr;
        cudaError_t asyncErr;

        
    
        MultiMatrices<<<dimGrid, dimBlock>>>(d_a, d_b, d_c, k, m, n);

        cudaMemcpy(h_c, d_c, sizeof(float)*m*n, cudaMemcpyDeviceToHost);        

        MMErr = cudaGetLastError();
        if(MMErr != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(MMErr));

        asyncErr = cudaDeviceSynchronize();
        if(asyncErr != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(asyncErr));
        

        imprimirMatriz(h_c, m, n);

        cudaFree(d_a);
        cudaFree(d_b);
        cudaFree(d_c);

        cudaFreeHost(h_a);
        cudaFreeHost(h_b);
        cudaFreeHost(h_c);    

    }

    return 0;
}
