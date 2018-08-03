mkdir results/megahit/assembly/
megahit -1 allgenomes_reads_1.fastq -2 allgenomes_reads_2.fastq -o results/megahit/assembly/
prodigal -i  results/megahit/assembly/final.contigs.fa -a results/megahit/assembly/final.contigs.aa.fa -o /dev/null
mmseqs createdb results/megahit/assembly/final.contigs.aa.fa results/megahit/assembly/final.contigs.aa
evaluateResult.sh results/megahit/assembly/final.contigs.aa allproteins.fasta allproteins_nr_tc99_id95 results/megahit/results 100
