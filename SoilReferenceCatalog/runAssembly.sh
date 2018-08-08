#!/bin/bash -x
#BSUB -J download[1-640]
#BSUB -o out.%I.%J
#BSUB -e err.%I.%J

id=$(sed "${LSB_JOBINDEX}q;d" SRC_sample_ids.txt)
mkdir -p $id
cd $id
if [  ! -f ${id}_aa ]
then
  if [ ! -f allreads ]; then
    wget https://sra-download.ncbi.nlm.nih.gov/srapub/${id}
    fastq-dump --split-files -split-3 ./$id
  fi
  mmseqs assemble ${id}_1.fastq ${id}_2.fastq ${id}_assembly.fas  /tmp/tmp_${id}
  rm -rf /tmp/tmp_${id}
  # clean up
fi
