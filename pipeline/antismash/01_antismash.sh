#!/usr/bin/bash -l
#SBATCH -p batch,intel --mem 64gb -N 1 -n 16 --out logs/antismash.%a.log 


CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "need to provide a number by --array or cmdline"
	exit
    fi
fi
TOP=results/antismash
pushd $TOP
echo -n "Start Time "
date
INFILE=$(ls data/*.fasta | sed -n ${N}p)
OUTDIR=$(basename $INFILE .fasta)
echo "Going to run antismash on $INFILE ($OUTDIR)"
# Determine output directory
if [ ! -d $OUTDIR ]; then
	module load antismash/6.0.0
	#module load antismash/5.2.0
	antismash --genefinding-tool prodigal -c $CPU --taxon bacteria --cb-general --cb-knownclusters --clusterhmmer $INFILE
fi
echo -n "End Time "

date
