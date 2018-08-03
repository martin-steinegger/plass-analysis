mkdir results/metaspades/
spades.py -1 allgenomes_reads_1.fastq -2 allgenomes_reads_2.fastq -o results/metaspades/  --meta
prodigal -i results/metaspades/contigs.fasta -a results/metaspades/contigs.aa.fasta -o /dev/nul
mmseqs createdb results/metaspades/contigs.aa.fasta results/metaspades/contigs.aa
evaluateResult.sh results/metaspades/contigs.aa allproteins.fasta allproteins_nr_tc99_id95 results/metaspades/results 100
