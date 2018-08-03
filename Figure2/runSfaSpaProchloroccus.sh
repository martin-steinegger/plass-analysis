mkdir results/sfaspa/
spa_suit.pl -o results/sfaspa/ -p sfaspa-0.2.1/param/parameter.generic  -i all_merged_reads_nucl.fasta
mmseqs createdb results/sfaspa/post/post.fasta results/sfaspa/post/post
evaluateResult.sh results/sfaspa/post/post allproteins.fasta allproteins_nr_tc99_id95.fasta results/sfaspa/results 100
