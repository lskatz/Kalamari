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
export nl=$'\n'
find $SRC -name '*.fasta.gz' | \
  xargs -n 100 -P 1 bash -c '
    for i in "$@"; do
      gzip -cd $i
    done > $tmpfile
    echo -ne "ADDING to library:\n  "
    zgrep "^>" $tmpfile | sed "s/^>//" | tr "$nl" " "
    echo
    echo "^^ contents of $tmpfile ^^"
    kraken-build --db $DB --add-to-library $tmpfile
  '

# Build the database
kraken-build --db $DB --build --threads 1
# Reduce the size of the database
kraken-build --db $DB --clean


if [ ! -e "$sharedir/kalamari-kraken1" ]; then
  ln -sv kalamari-kraken "$sharedir/kalamari-kraken1"
fi
