#!/bin/bash -x
BASE=$(pwd)
mkdir genomes
cd genomes
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_genbank.txt
IFS=$'\n'
for spec in $(grep De_novo_assembly_of_single-cell_genome $BASE/genomes/assembly_summary_genbank.txt | awk -F'\t' '{print $8}'|awk '{print $1}'|sort|uniq); do
    mkdir $spec
    cd $spec
    for url in $(grep -i De_novo_assembly_of_single-cell_genome $BASE/genomes/assembly_summary_genbank.txt|awk -F '\t' '{print $20}'); do
      url=$(echo $url|awk '{gsub("ftp://","https://"); print $0"/"}')
      for file in $(curl -s $url|grep href|sed 's/.*href="//'|sed 's/".*//'|grep '^[a-zA-Z].*'|grep "faa.gz\|fna.gz"|grep -v "_cds_from_\|_rna_from"); do
         curl -s -O $url/$file
      done
    done
    cd $BASE/genomes
    gunzip $spec/*.gz
    cat $spec/*.fna >> allgenomes.fasta
done
cd ..
prodigal -i genomes/allgenomes.fasta  -a genomes/allproteins.fasta -o /dev/null
bbmap/randomreads.sh paired snprate=0.005 adderrors coverage=1 len=150 mininsert=150 maxinsert=350 gaussian=true ref=$BASE/genomes/allgenomes.fasta out1=$BASE/allgenomes_reads_1.fastq out2=$BASE/allgenomes_reads_2.fastq
flash $BASE/allgenomes_reads_1.fastq $BASE/allgenomes_reads_2.fastq
cat out.extendedFrags.fastq out.notCombined_1.fastq out.notCombined_2.fastq > all_merged_reads_nucl.fastq
sed -n '1~4s/^@/>/p;2~4p' all_merged_reads_nucl.fastq > all_merged_reads_nucl.fasta
mmseqs linclust allproteins_nr allproteins_nr_clu tmp --min-seq-id 0.95 -c 0.99 --cov-mode 1 
mmseqs createsubdb allproteins_nr_clu allproteins_nr allproteins_nr_tc99_id95
mmseqs createsubdb allproteins_nr_clu allproteins_nr_h allproteins_nr_tc99_id95_h
