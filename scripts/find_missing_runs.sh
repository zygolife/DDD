#!/usr/bin/ksh
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
    if [ ! -d $OUTFOLDER ]; then
        echo "NEED to run $N"
	RERUN+=( $N )
    elif [ ! -f $OUTFOLDER/scaffolds.fasta ]; then
	RERUN+=( $N )
    fi
    OUTFOLDER=$ASM/${STEM}.plasmidspades
    if [ ! -d $OUTFOLDER ]; then
	RERUNPLASMID+=( $N )
    elif [ ! -f $OUTFOLDER/scaffolds.fasta ]; then
	RERUNPLASMID+=( $N )
    fi
    N=$(expr $N + 1)
#    echo "${RERUN[@]}"
done

OFS=","
echo  "rerun metaspades ${RERUN[@]}"
#lst="${RERUN[@]}"
lst=$(echo "${RERUN[@]}" | perl -p -e 's/ /,/g')
#$(join_by , "${RERUN[@]}")
echo "sbatch -a $lst pipeline/assemble/01_metaspades.sh"

echo  "rerun plamsidspades ${RERUNPLASMID[@]}"
lst=$(echo "${RERUNPLASMID[@]}" | perl -p -e 's/ /,/g')
#lst=$(join_by , "${RERUNPLASMID[@]}")
echo "sbatch -a $lst pipeline/assemble/02_plasmidspades.sh"
