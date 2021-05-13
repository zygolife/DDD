
#!/usr/bin/bash
#SBATCH -p short -N 1 -n 8 --mem 24gb --out BTL_Search.log

CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi


module load ncbi-blast/2.9.0+
DB=results/combined_db/genome_asm.merge.fa
QUERY=lib/TwoBtlsForQuery.fa

tblastn -db $DB -query $QUERY -out results/BTL/BTL-vs-combined.TBLASTN -evalue 1e-10 -num_threads $CPU
