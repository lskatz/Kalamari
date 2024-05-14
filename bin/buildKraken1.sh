#!/bin/bash

set -eu

thisdir=$(dirname $0)
KALAMARI_VER=$(downloadKalamari.pl --version)

sharedir=$thisdir/../share/kalamari-$KALAMARI_VER
SRC="$sharedir/kalamari"
TAXDIR="$sharedir/taxonomy/filtered"

# Test prereqs
which kraken-build
which jellyfish

export tmpfile=$(mktemp --suffix=.fasta)
trap 'rm -f $tmpfile' EXIT

export DB="$sharedir/kalamari-kraken"
mkdir -pv $DB/library
cp -rv $TAXDIR $DB/taxonomy

# Make --add-to-library more efficient with
# concatenated fasta files
find $SRC -name '*.fasta.gz' | \
  xargs -n 100 -P 1 bash -c '
    for i in "$@"; do
      gzip -cd $i
    done > $tmpfile
    kraken-build --db $DB --add-to-library $tmpfile
  '

# Build the database
kraken-build --db $DB --build --threads 1
# Reduce the size of the database
kraken-build --db $DB --clean

