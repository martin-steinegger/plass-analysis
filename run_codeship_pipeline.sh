#!/bin/bash -ex
BASE_DIR="$HOME/clone/regression_test"
PLASS="$HOME/clone/build/src/plass"

cd ${BASE_DIR}
# build the benchmark tools
git clone https://github.com/martin-steinegger/plass-analysis.git
cd plass-analysis
git submodule init
git submodule update
cd ..
# setup mmseqs2
git clone https://github.com/soedinglab/mmseqs2.git
cd mmseqs2
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release  ..
make -j 4 VERBOSE=0
cd ..
cd ..
MMSEQSPATH="$(realpath mmseqs2)/mmseqs2/build/src"
export PATH=$MMSEQSPATH:$PATH

#setup benchmark database
mkdir results

# go run it
EVALUATE="./plass-analysis/Prochloroccus/evaluateResults.sh"

plass ./plass-analysis/data/allgenomes_reads_sample_1.fastq ./plass-analysis/data/allgenomes_reads_sample_2.fastq results/final.contigs.aa.fa results/tmp
mmseqs createdb results/final.contigs.aa.fa results/final.contigs.aa
$EVALUATE results/final.contigs.aa ./plass-analysis/data/prochloroccus_allproteins ./plass-analysis/data/prochloroccus_allproteins_nr results/ 100 > report-${CI_COMMIT_ID}
cat results/sense >> report-${CI_COMMIT_ID}
cat results/precision >> report-${CI_COMMIT_ID}

# fill out the report and fail
cat report-${CI_COMMIT_ID}
#curl -F upfile=@report-${CI_COMMIT_ID} https://mmseqs.com/regression.php?secret=${REGRESSIONSECRET}
exit $?
