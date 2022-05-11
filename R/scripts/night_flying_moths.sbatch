#!/bin/bash 
#SBATCH --partition=short-serial 
#SBATCH --job-name=nightflyingmoths
#SBATCH -o out/%A_%a.out
#SBATCH -e err/%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --array=1
#SBATCH --mem=16000
module add jaspy/3.7/r20200606
Rscript 4_produce_outputs.R