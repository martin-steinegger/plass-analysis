#!/bin/bash
TSV=$1
LEN=$2
awk -v lencut=$LEN 'BEGIN{group=""; len=0; cov=""}
                    $1!=group { if(len >= lencut) { n[cov*len]++; } group=$1; len=$8; cov=(1+$7-$6)/$8;  }{ cov = cov > (1+$7-$6)/$8 ? cov : (1+$7-$6)/$8}
                    END{if(len >= lencut) { n[cov*len]++; }; for (i in n) print i,n[i] }' ${TSV} | sort -n
