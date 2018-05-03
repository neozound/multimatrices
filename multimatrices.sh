#!/bin/bash
#
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -J "multimatrices"
#SBATCH -t 01:00
#SBATCH --gres=gpu:1


module load cuda

which nvcc

srun -n 1 ./a.out datos.txt
