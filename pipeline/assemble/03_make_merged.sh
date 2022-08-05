#!/usr/bin/bash
#SBATCH -p short -N 1 -n 16 --out logs/merge_asm.log
FORCE=0
SAMPLES=samples_prefix.csv
OUTDIR=results/genome_asm
ASM=assembly
IFS=,
N=1
tail -n +2 $SAMPLES | while read -r SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
	STEM=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
	STRAIN=$(echo -n $STRAIN | perl -p -e 's/\s+/_/g')
	echo "processing $STEM ($STRAIN)"
	if [ $FORCE -gt 0 ]; then
		rm -f $OUTDIR/$STEM.merge.fa
	fi
	if [ ! -s $OUTDIR/$STEM.merge.fa ]; then
		if [ -s $ASM/$STEM.plasmidspades/scaffolds.fasta ]; then
			perl -p -e "s/>NODE_(\d+)_length_(\d+)_cov_(\d(\.\d+)?)_cutoff_(\d+)_type_(\S+)/>${STRAIN}_plascf_\$1_covcut_\$4 length=\$2 cov=\$3 type=\$6/" >  $OUTDIR/$STEM.merge.fa
		fi
		if [ -s $ASM/$STEM.spades/scaffolds.fasta ]; then
			perl -p -e "s/>NODE_(\d+)_length_(\d+)_cov_(\d(\.\d+)?)/>${STRAIN}_metscf_\$1 length=\$2 cov=\$3/" >>  $OUTDIR/$STEM.merge.fa
		fi
	else
		echo "not processing $STEM merge already exists"
	fi
	N=$(expr $N + 1)
done
