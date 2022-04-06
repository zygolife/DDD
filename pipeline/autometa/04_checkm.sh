#!/usr/bin/bash -l
#SBATCH -p short --mem 64gb -N 1 -n 16 --out logs/checkm.%a.log 


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
AUTOMETAOUT=$(realpath results/autometa)
TEMP=/scratch/$USER/$$
mkdir -p $TEMP
SAMPLES=samples_prefix.csv
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    echo -n "Start Time "
    date
    # Determine output directory
    OUTNAME=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')

    module load checkm
    CLUSTERDIR=$AUTOMETAOUT/$OUTNAME/cluster_process_output
    TOPDIR=$AUTOMETAOUT/$OUTNAME
    BACTERIARUN=$AUTOMETAOUT/$OUTNAME/Bacteria_run
    pushd $TOPDIR
    if [[ -s $CLUSTERDIR/cluster_taxonomy.tab ]]; then 
	checkm lineage_wf $CLUSTERDIR $TOPDIR/checkM -x fasta -t $CPU --tmpdir $TEMP --pplacer_threads $CPU
	checkm taxonomy_wf domain Bacteria -t $CPU -x fasta $CLUSTERDIR $TOPDIR/checkM  -f checkM_taxonomy_wf_results --tab_table
	PHYLUM=$(grep DBSCAN  $CLUSTERDIR/cluster_taxonomy.tab | cut -f3 | sed -n 1p)
	if [ ! -z $PHYLUM ]; then
	    checkm taxonomy_wf phylum $PHYLUM -t $CPU -x fasta $CLUSTERDIR $TOPDIR/checkM  -f checkM_taxonomy_phylum_wf_results --tab_table
	fi
    elif [ -s $BACTERIARUN/Bacteria.filtered.fasta ]; then
	checkm lineage_wf $BACTERIARUN $TOPDIR/checkM -x fasta -t $CPU --tmpdir $TEMP --pplacer_threads $CPU
	checkm taxonomy_wf domain Bacteria -t $CPU -x fasta $BACTERIARUN $TOPDIR/checkM  -f checkM_taxonomy_wf_results --tab_table
	#PHYLUM=$(grep DBSCAN  $CLUSTERDIR/cluster_taxonomy.tab | cut -f3 | sed -n 1p)
	#if [ ! -z $PHYLUM ]; then
	#    checkm taxonomy_wf phylum $PHYLUM -t $CPU -x fasta $BACTERIARUN $TOPDIR/checkM  -f checkM_taxonomy_phylum_wf_results --tab_table
	#fi
    else 
	echo "No Bacteria.fasta for $TOPDIR"
    fi
    popd
    echo -n "End Time "
    date
done

rm -rf $TEMP
