#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 12 --mem 24gb --out logs/BTL_Search.log -C xeon

CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

module load ncbi-blast/2.9.0+
QUERY=lib/TwoBtlsForQuery.fa
DB=results/combined_db/genome_asm.merge.fa
OUT=results/BTL/BTL-vs-combined.TBLASTN
if [ ! -s $OUT ]; then
	tblastn -db $DB -query $QUERY -out $OUT -evalue 1e-10 -num_threads $CPU
fi

DB=results/combined_db/autometa_Bacteria.merge.fa
OUT=results/BTL/BTL-vs-autometa_Bacteria.TBLASTN
if  [ ! -s $OUT ]; then
	tblastn -db $DB -query $QUERY -out $OUT -evalue 1e-8 -num_threads $CPU
fi

DB=results/combined_db/autometa_filtered.merge.fa
OUT=results/BTL/BTL-vs-autometa_Bacteria_filtered.TBLASTN
if [ ! -s $OUT ]; then
	tblastn -db $DB -query $QUERY -out $OUT -evalue 1e-8 -num_threads $CPU
fi
