#!/usr/bin/bash
#SBATCH -p intel,batch -N 1 -n 16 --mem 64gb --out logs/plasmidspades.%a.log -J plasmidspades

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
  OUTFOLDER=$ASM/${STEM}.plasmidspades
  if [[ ! -d $OUTFOLDER && ! -f $OUTFOLDER/scaffolds.fasta ]]; then
  	if [ -d $OUTFOLDER ]; then
		 time spades.py --threads $CPU -o $OUTFOLDER --restart-from last
	else
    		time spades.py --meta --plasmid --threads $CPU -m $MEM \
        -1 ${INFOLDER}/${STEM}_R1.fq.gz -2 ${INFOLDER}/${STEM}_R2.fq.gz \
        -o $OUTFOLDER
	fi
  fi
  if [ -f $OUTFOLDER/scaffolds.fasta ]; then
    rm -rf $OUTFOLDER/before_rr.fasta $OUTFOLDER/corrected $OUTFOLDER/K*
    rm -rf $OUTFOLDER/assembly_graph_after_simplification.gfa $OUTFOLDER/tmp
    pigz $OUTFOLDER/contigs.fasta
    pigz $OUTFOLDER/spades.log
  fi
done
