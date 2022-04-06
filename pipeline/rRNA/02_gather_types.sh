#!/usr/bin/bash
#SBATCH -p short
module load hmmer/3
INDIR=results/barrnap
OUTDIR=results/16S_tree
#OUTFILE=$OUTDIR/16S_hits.ctgs.txt
OUTFAS=$OUTDIR/Burk.16S_hits.ctgs.fas
mkdir -p $OUTDIR
rm -f $OUTFAS
for file in $(ls $INDIR/*16S*.tab )
do
	if [ ! -s $file ]; then
		continue
	fi
	stem=$(basename $file .16S_hits.blastn.tab)
	hits=$INDIR/$stem.16S_hits.fas
	if [ ! -f $hits.ssi ]; then
		esl-sfetch --index $hits
	fi
#	grep [Bb]urk $file | cut -f1 | sort | uniq >> $OUTFILE	
	grep [Bb]urk $file | cut -f1 | sort | uniq | esl-sfetch -f $hits - >> $OUTFAS
done


# do exrtact all 16s hits later
