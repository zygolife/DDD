#!/usr/bin/bash
#SBATCH -p short -N 1 -n 2 --out logs/download.%a.log

module load aspera
module load sratoolkit

# this was not implemeneted for the project because all data were available locally already
