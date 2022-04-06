#!/usr/bin/bash -l

mkdir -p results/Bacteria_genomes/data
pushd results/Bacteria_genomes/data

for file in ../../autometa/*/cluster_process_output/*.fasta; do m=$(dirname $file); n=$(dirname $m); base=$(basename $n); b=$(basename $file); ln -s $file ${base}__$b ; done
for file in ../../autometa/*/Bacteria_run/*.fasta; do m=$(dirname $file); n=$(dirname $m); base=$(basename $n); b=$(basename $file); ln -s $file ${base}__AllBacteria.fasta; done
