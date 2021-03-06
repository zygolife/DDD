#!/usr/bin/bash
#SBATCH -p short -n 2 -N 1 --mem 8gb --out logs/BTL_prep.log


module load ncbi-blast/2.9.0+


DB=results/combined_db/autometa_Bacteria.merge.fa
cat results/autometa/*/Bacteria.fasta > $DB
makeblastdb -in $DB -dbtype nucl -title DDD_autometa_Bacteria

DB=results/combined_db/autometa_filtered.merge.fa
cat results/autometa/*/Bacteria_run/Bacteria.filtered.fasta > $DB
makeblastdb -in $DB -dbtype nucl -title DDD_autometa_Bacteria_filtered

DB=results/combined_db/genome_asm.merge.fa
cat results/genome_asm/*.merge.fa > $DB
makeblastdb -in $DB -dbtype nucl -title DDD_merge


