#!/bin/bash
set -e
set -o pipefail
#set -x

#which datasets dataformat

genus=$1
species=$2
expected=$3
spreadsheet=assembly-complete.tsv

acc=($(grep $genus $spreadsheet | grep $species | cut -f 1 | tr '\n' ' '))
chunk_size=100

for ((i=0; i<${#acc}; i+=chunk_size)); do
  chunk=("${acc[@]:i:chunk_size}")
  accs=$(echo "$chunk" | tr '\n' ',' | sed 's/,$//')
  # Join chunk into a comma-separated list
  accs=$(IFS=,; echo "${chunk[*]}")
  echo "ACCESSIONS: $accs"
  datasets summary genome accession $accs --report sequence --as-json-lines | \
    dataformat tsv genome-seq --fields accession,genbank-seq-acc | \
    grep $expected || true
done
