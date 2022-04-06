#!/usr/bin/bash
#SBATCH -p batch,intel --mem 24gb -N 1 -n 24 --out logs/autometa_taxonomy.%a.%A.log

# see module load below

CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi


N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
fi

if [ -z $N ]; then
    echo "need to provide a number by --array or cmdline"
    exit
fi
COVOUT=results/coverage
ASM=results/genome_asm
AUTOMETAOUT=results/autometa
mkdir -p $AUTOMETAOUT
DATABASES=databases
if [ ! -d $DATABASES ]; then
    ln -s /srv/projects/db/autometa/1.0.2 $DATABASES
fi
INFOLDER=input
SAMPLES=samples_prefix.csv
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
	echo -n "Start Time "
	date
    # Determine output directory
    OUTNAME=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
    GENOMEFILE=$ASM/${OUTNAME}.merge.fa
    COVTAB=$COVOUT/$OUTNAME.coverage.tab

    if [ ! -f $COVTAB ]; then
	bash pipeline/autometa/01_make_cov.sh $N
    fi
    if [[ ! -d $AUTOMETAOUT/$OUTNAME || ! -s $AUTOMETA/$OUTNAME/taxonomy.tab ]]; then
	module load autometa/1.0.2
	make_taxonomy_table.py -a $GENOMEFILE -p $CPU -o $AUTOMETAOUT/$OUTNAME --cov_table $COVTAB
    fi
    echo -n "End Time "
    date

done
