#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 24 --mem 64gb --out logs/genomescope.%a.log -a 1-9

module load workspace/scratch
module load samtools
module load jellyfish
module load R

GENOMESCOPE=genomescope

FASTQFOLDER=input
SAMPLEFILE=samples_prefix.csv
CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
  N=$1
fi
if [ -z $N ]; then
  echo "cannot run without a number provided either cmdline or --array in sbatch"
  exit
fi

MAX=$(wc -l $SAMPLEFILE | awk '{print $1}')
if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in samplefile=$SAMPLEFILE"
  exit
fi
mkdir -p $GENOMESCOPE
JELLYFISHSIZE=1000000000
IFS=,
KMER=21
READLEN=150 # note this assumes all projects are 150bp reads which they may not be

tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    STEM=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
    # for this project has only a single file base  but this needs fixing otherse
    jellyfish count -C -m $KMER -s $JELLYFISHSIZE -t $CPU -o $SCRATCH/$STEM.jf <(pigz -dc $FASTQFOLDER/$/${STEM}_R[12].fq.gz)
    jellyfish histo -t $CPU $SCRATCH/$STEM.jf > $GENOMESCOPE/$STEM.histo
    Rscript scripts/genomescope.R $GENOMESCOPE/$STEM.histo $KMER $READLEN $GENOMESCOPE/$STEM/
done
