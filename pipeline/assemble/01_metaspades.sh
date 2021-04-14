#!/usr/bin/bash
#SBATCH -p intel,batch -N 1 -n 16 --mem 64gb --out logs/metaspades.%a.log -J metaspades

module load spades/3.15.2

MEM=64
SAMPLES=samples_prefix.csv
INFOLDER=input
ASM=assembly
mkdir -p $ASM
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
  CPU=1
fi

N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi


#--meta
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
  STEM=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
  OUTFOLDER=$ASM/${STEM}.spades
  if [ ! -d $OUTFOLDER ]; then
   time spades.py --meta --threads $CPU -m $MEM \
        -1 ${INFOLDER}/${STEM}_R1.fq.gz -2 ${INFOLDER}/${STEM}_R2.fq.gz \
        -o $OUTFOLDER
  fi
  if [ -f $OUTFOLDER/scaffolds.fasta ]; then
    rm -rf $OUTFOLDER/tmp $OUTFOLDER/corrected $OUTFOLDER/K*
    rm -f $OUTFOLDER/before_rr.fasta $OUTFOLDER/first_pe_contigs.fasta
    pigz $OUTFOLDER/spades.log $OUTFOLDER/*.gfa $OUTFOLDER/*.fastg $OUTFOLDER/*.paths
  fi
done
