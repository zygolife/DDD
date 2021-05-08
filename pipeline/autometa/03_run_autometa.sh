#!/usr/bin/bash
#SBATCH -p short --mem 16gb -N 1 -n 4 --out logs/autometa_run.%a.%A.log


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
COVERAGE=results/coverage
ASM=results/genome_asm
AUTOMETAOUT=results/autometa

DAT=samples_prefix.csv
DATABASES=databases
if [ ! -d $DATABASES ]; then
    ln -s /srv/projects/db/autometa/1.0.2 $DATABASES
fi

DBFOLDER=$(realpath databases)
IFS=,
tail -n +2 $DAT | sed -n ${N}p | while read SPECIES STRAIN ACCESSION ASMNAME BIOPROJECT SRA HABITAT LOCATION
do
tail -n +2 $SAMPLES | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    echo -n "Start Time "
    date
    # Determine output directory
    OUTNAME=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
    GENOMEFILE=$ASM/${OUTNAME}.merge.fa
    COVTAB=$COVOUT/$OUTNAME.coverage.tab
    module load autometa/1.0.2
    module load git
    
    if [[ ! -d $AUTOMETAOUT/$OUTNAME || ! -f $AUTOMETAOUT/$OUTNAME/Bacteria_run/ML_recruitment_output.tab ]]; then
	time run_autometa.py -k bacteria -a $AUTOMETAOUT/$OUTNAME/Bacteria.fasta --ML_recruitment \
	    --processors $CPU --length_cutoff 1500 --taxonomy_table $AUTOMETAOUT/$OUTNAME/taxonomy.tab -o $AUTOMETAOUT/$OUTNAME/Bacteria_run -v $COVTAB
    fi
    
    if [ ! -d $AUTOMETAOUT/$OUTNAME/cluster_process_output ]; then
	cluster_process.py --bin_table $AUTOMETAOUT/$OUTNAME/Bacteria_run/ML_recruitment_output.tab --column ML_expanded_clustering \
	    --fasta $AUTOMETAOUT/$OUTNAME/Bacteria.fasta --do_taxonomy --db_dir $DBFOLDER \
	    --output_dir $AUTOMETAOUT/$OUTNAME/cluster_process_output
    fi
    echo -n "End Time "
    date
done
