#!/bin/bash -e
REPORT=$1
VALS=$2
if [[ ! -s "${REPORT}" ]]; then
    exit 1
fi

GOOD=$( awk -v check="$VALS" 'BEGIN{split(check,checklist," "); cnt=0}{if($3 >= (checklist[NR]-0.005)){cnt=cnt+1}}END{if(cnt==NR){print "GOOD"}else{print "BAD"}}' "${REPORT}")
ERROR=0
if [[ "$GOOD" != "GOOD" ]]; then
    ERROR=$((ERROR+1))
    >&2 echo "Failed check! Input: ${values[3]} Expected: $TARGET Comparison: ${TEST}"
    continue
fi

if [ $ERROR -ne 0 ]; then
    exit 1
fi

exit 0
