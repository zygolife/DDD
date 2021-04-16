#!/usr/bin/bash
#SBATCH -p intel,batch -N 1 -n 16 --mem 64gb --out logs/plasmidspades.%a.log -J plasmidspades

# Load modules
if [ -n "$MODULESHOME" ]; then
  module load spades/3.15.2
fi

# Define params
MEM=64
SAMPLES=samples_prefix.csv
INFOLDER=input
ASM=assembly

# Ensure parent output directory
mkdir -p $ASM

# Determine num CPUs
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
  CPU=$2
  if [ ! $CPU ]; then
    CPU=1
  fi
fi

# Determine job index
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

# Determine input data from job index
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE; do

  # Determine output directory
  STEM=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
  OUTFOLDER=$ASM/${STEM}.plasmidspades
  echo "OUTPUT:\n\t${OUTFOLDER}"
  
  # Run spades
  if [ ! -d $OUTFOLDER ]; then
    cmd="spades.py --meta --plasmid --threads $CPU -m $MEM \
        -1 ${INFOLDER}/${STEM}_R1.fq.gz -2 ${INFOLDER}/${STEM}_R2.fq.gz \
        -o $OUTFOLDER"
    echo "Running:\n\t$cmd"
    time $cmd
  fi
  
  # Clean up and compress
  if [ -f $OUTFOLDER/scaffolds.fasta ]; then
    echo "Cleaning..."
    rm -rf $OUTFOLDER/before_rr.fasta $OUTFOLDER/corrected $OUTFOLDER/K*
    rm -rf $OUTFOLDER/assembly_graph_after_simplification.gfa $OUTFOLDER/tmp
    pigz $OUTFOLDER/contigs.fasta
    pigz $OUTFOLDER/spades.log
  fi
  
done