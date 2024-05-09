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

DB="$sharedir/kalamari-kraken1"
mkdir -pv $DB
cp -rv $TAXDIR $DB/taxonomy
find $SRC -name '*.fasta' \
  -exec kraken-build --db $DB --add-to-library {} \;
kraken-build --db $DB --build --threads 1
kraken-build --db $DB --clean
