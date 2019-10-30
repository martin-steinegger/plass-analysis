#!/bin/bash -ex
BASE_DIR="$HOME/clone/regression_test"
PLASS="$HOME/clone/build/src/"
export PATH=$PLASS:$PATH
notExists() {
	[ ! -f "$1" ]
}


cd ${BASE_DIR}
# build the benchmark tools
if notExists "plass-analysis"; then
  git clone https://github.com/martin-steinegger/plass-analysis.git
  cd plass-analysis
  git submodule init
  git submodule update
  cd ..
fi  
# setup mmseqs2
if notExists "mmseqs2"; then
  git clone https://github.com/soedinglab/mmseqs2.git
  cd mmseqs2
  mkdir build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release  ..
  make -j 4 VERBOSE=0
  cd ..
  cd ..
fi
MMSEQSPATH="$(realpath mmseqs2)/build/src"
export PATH=$MMSEQSPATH:$PATH

#setup benchmark database
mkdir results

PLASSANALPATH="$(realpath plass-analysis)/Prochloroccus/"
export PATH=$PLASSANALPATH:$PATH

# go run it
plass assemble ./plass-analysis/data/allgenomes_reads_sample_1.fastq ./plass-analysis/data/allgenomes_reads_sample_2.fastq results/final.contigs.aa.fa results/tmp
mmseqs createdb results/final.contigs.aa.fa results/final.contigs.aa
chmod -R u+x ./plass-analysis/
export PATH="$(realpath plass-analysis)":$PATH

# eval it
mmseqs createdb ./plass-analysis/data/prochloroccus_allproteins.fasta ./plass-analysis/data/prochloroccus_allproteins
mmseqs createdb ./plass-analysis/data/prochloroccus_allproteins_nr.fasta ./plass-analysis/data/prochloroccus_allproteins_nr
evaluateResults.sh results/final.contigs.aa ./plass-analysis/data/prochloroccus_allproteins ./plass-analysis/data/prochloroccus_allproteins_nr results/ 100 

cat results/sense > report-${CI_COMMIT_ID}
cat results/precision >> report-${CI_COMMIT_ID}
cat report-${CI_COMMIT_ID}
# fill out the report and fail
check_result.sh report-${CI_COMMIT_ID} "0.495 0.474 0.451 0.422 0.389 0.343 0.295 0.245 0.196 0.133 0.980 0.980 0.979 0.979 0.977 0.974 0.965 0.940 0.864 0.649"
exit $?

