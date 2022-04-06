#!/usr/bin/bash
#SBATCH -p short -N 1 -n 4 --mem 24gb --out logs/barrnap.%a.log

module load barrnap
module load hmmer/3
module load vsearch
module load ncbi-blast/2.9.0+

SAMPLES=samples_prefix.csv
INFOLDER=input
ASM=assembly
OUTASM=results/genome_asm
QUERYRDNA=lib/Coemansia_rDNA.fasta
BARRNAP_OUT=results/barrnap
NCBI16S=lib/16S_ribosomal_RNA
NCBIITS=lib/ITS_eukaryote_sequences
NCBI18S=lib/18S_fungal_sequences
#SSUDB=lib/SILVA_138.1_SSURef_NR99_tax_silva_trunc.udb
#if [ ! -f $SSUDB ]; then
#    vsearch --makeudb_usearch $(echo $SSUDB | perl -p -e 's/\.udb/.fasta/') --output $SSUDB --threads $CPU
#fi

mkdir -p $OUTASM $BARRNAP_OUT
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

IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    # Determine output directory
    STRAINNOSPACE=$(echo "$STRAIN" | perl -p -e 'chomp; s/\s+/_/g')
    STEM=$(echo -n $SPECIES | perl -p -e 's/\s+/_/g')
    PLASMIDASM=$ASM/${STEM}.plasmidspades/scaffolds.fasta
    METAASM=$ASM/${STEM}.spades/scaffolds.fasta
    GENOME=$OUTASM/$STEM.merge.fa
    if [ ! -s $GENOME ]; then
	perl -p -e "s/>NODE_(\d+)_length_(\d+)_cov_([^_]+)_cutoff_(\d+)_type_(\S+)/>${STRAINNOSPACE}_plascf_\$1_covcut_\$4 length=\$2 cov=\$3/" $PLASMIDASM > $GENOME
	perl -p -e "s/>NODE_(\d+)_/>${STRAINNOSPACE}_metscf_\$1 /" $METAASM >> $GENOME
    fi
    if [ ! -f $GENOME.ssi ]; then
	esl-sfetch --index $GENOME
    fi
    if [ ! -f $BARRNAP_OUT/$STEM.euk_barrnap.gff3 ]; then
	for type in euk bac arc mito
	do
	    barrnap --kingdom $type --threads $CPU $GENOME > $BARRNAP_OUT/$STEM.${type}_barrnap.gff3
	done
    fi
    if [ ! -f  $BARRNAP_OUT/$STEM.16S_hits.gff3 ]; then
	for type in euk bac arc mito
	do
	    grep 16S_ $BARRNAP_OUT/$STEM.${type}_barrnap.gff3 | grep -v partial
	done | sort | uniq > $BARRNAP_OUT/$STEM.16S_hits.gff3
    fi
    if [ ! -f $BARRNAP_OUT/$STEM.16S_hits.fas ]; then
	unset IFS
	cut -f1,4,5,6 $BARRNAP_OUT/$STEM.16S_hits.gff3 |  while read CHROM START END SCORE 
	do
	    esl-sfetch -c $START..$END $GENOME $CHROM 
	done > $BARRNAP_OUT/$STEM.16S_hits.fas
    fi

    if [ ! -s $BARRNAP_OUT/$STEM.16S_hits.blastn.tab ]; then
 	blastn -query $BARRNAP_OUT/$STEM.16S_hits.fas  -db $NCBI16S -evalue 1e-30 -out $BARRNAP_OUT/$STEM.16S_hits.blastn.tab \
		     -num_threads $CPU -num_alignments 5 -outfmt "6 qacc sacc length pident qstart qend sstart ssend score evalue sscinames"
    fi
    if [ ! -s $BARRNAP_OUT/$STEM.ITS_hits.blastn.tab ]; then
	blastn -query $GENOME -db $NCBIITS -evalue 1e-30 -out $BARRNAP_OUT/$STEM.ITS_hits.blastn.tab \
	    -num_threads $CPU -num_alignments 10 -outfmt "6 qacc sacc length pident qstart qend sstart ssend score evalue sscinames"
    fi
    if [ ! -s $BARRNAP_OUT/$STEM.18S_hits.blastn.tab ]; then
	    blastn -db $NCBI18S -query $GENOME -evalue 1e-30 -out $BARRNAP_OUT/$STEM.18S_hits.blastn.tab \
		     -num_threads $CPU -num_alignments 5 -outfmt "6 qacc sacc length pident qstart qend sstart ssend score evalue sscinames"
 	fi
#	vsearch --db $SSUDB --usearch_global $BARRNAP_OUT/$STEM.16S_hits.fas --uc $BARRNAP_OUT/$STEM.16S_hits.SILVA_SSU.uc --id 0.95 --threads $CPU
#    fi
done
