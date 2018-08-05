#!/bin/bash
awk '{n[$3]++} END {for (i in n) print i,n[i]}' $1| sort -n
