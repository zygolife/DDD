#!/usr/bin/bash
#SBATCH -p short

SAMPLES=samples_prefix.csv
INFOLDER=input
ASM=assembly
function join_by { d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi; }

#declare -f join_by
RERUN=()
RERUNPLASMID=()
#declare -a RERUN
#declare -a RERUNPLASMID
IFS=,
N=1
tail -n +2 $SAMPLES | while read -r SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    STEM=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
    OUTFOLDER=$ASM/${STEM}.spades
    if [[ -d $OUTFOLDER && ! -f  $OUTFOLDER/scaffolds.fasta ]]; then
	echo "rm -rf $OUTFOLDER"
    fi
    OUTFOLDER=$ASM/${STEM}.plasmidspades
    if [[ -d $OUTFOLDER && ! -f  $OUTFOLDER/scaffolds.fasta ]]; then
	echo "rm -rf $OUTFOLDER"
    fi

    N=$(expr $N + 1)
done
