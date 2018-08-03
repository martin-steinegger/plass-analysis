mkdir results/plass/
plass allgenomes_reads_1.fastq allgenomes_reads_2.fastq results/plass/final.contigs.aa.fa results/plass/assembly/
mmseqs createdb results/plass/final.contigs.aa.fa results/plass/final.contigs.aa
evaluateResult.sh results/plass/final.contigs.aa allproteins.fasta allproteins_nr_tc99_id95 results/plass/results 100
