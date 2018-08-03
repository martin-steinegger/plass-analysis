mkdir results/velvet/results
OMP_NUM_THREADS=16 ../benchmark/velvet/velveth results/velvet/ 21 -shortPaired -fastq -separate allgenomes_reads_1.fastq allgenomes_reads_2.fastq
OMP_NUM_THREADS=16 ../benchmark/velvet/velvetg results/velvet/ -exp_cov auto
prodigal -i  results/velvet/contigs.fa  -a results/velvet/contigs.aa.fa -o /dev/null
mmseqs createdb results/velvet/contigs.aa.fa results/velvet/contigs.aa
evaluateResult.sh results/velvet/contigs.aa allproteins.fasta allproteins_nr_tc99_id95 results/velvet/results 100
