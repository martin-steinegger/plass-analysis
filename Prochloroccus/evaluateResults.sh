#!/bin/bash
ASSEMBLY=$1
REFERENCE=$2
REFERENCENR=$3
RESULT=$4
LEN=$5
mkdir -p ${RESULT}/search1

awk -v len=$LEN '$3 > len{print }' ${ASSEMBLY}.index > ${ASSEMBLY}.ids
mmseqs createsubdb ${ASSEMBLY}.ids ${ASSEMBLY} ${ASSEMBLY}.${LEN}
mmseqs createsubdb ${ASSEMBLY}.ids ${ASSEMBLY}_h ${ASSEMBLY}.${LEN}_h

mmseqs search ${ASSEMBLY}.${LEN} ${REFERENCE} ${RESULT}/assembly_against_reference ${RESULT}/search1 -s 5 --max-seqs 5000 --min-ungapped-score 100  -a --min-seq-id 0.89 
for i in $(seq 90 99| awk '{print $1/100}'); do
  mmseqs filterdb     ${RESULT}/assembly_against_reference ${RESULT}/assembly_against_reference_${i} --filter-column 3 --comparison-value ${i} --comparison-operator ge
  mmseqs createtsv    ${ASSEMBLY}.${LEN} ${REFERENCE} ${RESULT}/assembly_against_reference_${i} ${RESULT}/assembly_against_reference_${i}.tsv
  mappedFraction.sh ${ASSEMBLY}.${LEN}.index ${RESULT}/assembly_against_reference_${i}.tsv $LEN >> ${RESULT}/precision
done
cat $RESULT/precision

# sens
mkdir -p $RESULT/search2
mmseqs search $REFERENCENR ${ASSEMBLY}.${LEN} ${RESULT}/reference_against_assembly ${RESULT}/search2 --max-seqs 500000  -a --min-seq-id 0.89 
for i in $(seq 90 99| awk '{print $1/100}'); do
  mmseqs filterdb     ${RESULT}/reference_against_assembly ${RESULT}/reference_against_assembly_${i} --filter-column 3 --comparison-value $i --comparison-operator ge
  mmseqs createtsv    $REFERENCENR ${ASSEMBLY}.${LEN} ${RESULT}/reference_against_assembly_${i} ${RESULT}/reference_against_assembly_${i}.tsv
  mappedFraction.sh ${REFERENCENR}.index ${RESULT}/reference_against_assembly_${i}.tsv $LEN >> ${RESULT}/sense
done

