#!/bin/bash
calc() { awk "BEGIN{print $*}";}
LEN=$1
TSV=$2
LENCUTOFF=$3
SUM=$(lenDistribution.sh $LEN| awk -v len=$LENCUTOFF  'BEGIN{sum=0} $1> len {sum+=$1 * $2}END{print sum}')
ALIGNED=$(mappedDistribution.sh $TSV $LENCUTOFF| awk 'BEGIN{sum=0}{sum+=$1 * $2}END{print sum}')
printf '%.0f\t%.0f\t%.3f\n' $SUM $ALIGNED $(calc $ALIGNED/$SUM)
