#!/bin/bash

set -eu

# Check for dependencies
which taxonkit

thisdir=$(dirname $0)
thisfile=$(basename $0)
KALAMARI_VER=$(downloadKalamari.pl --version)

# Set up some directories
tempdir=$(mktemp -d $thisfile.XXXXXX)
trap "rm -rf $tempdir" EXIT
outdir="$thisdir/../share/kalamari-$KALAMARI_VER/taxonomy/filtered"
srcdir="$thisdir/../share/kalamari-$KALAMARI_VER/taxonomy"
mkdir -pv $outdir

# output files
outnodes="$outdir/nodes.dmp"
outnames="$outdir/names.dmp"

# source taxonomy
srcnodes="$srcdir/nodes.dmp"
srcnames="$srcdir/names.dmp"

# source leaf taxids
taxid=$(cut -f 3,4 $thisdir/../src/chromosomes.tsv $thisdir/../src/plasmids.tsv | grep -v taxid | tr '\t' '\n' | sort -n | uniq)

# Getting all necessary taxids
alltaxids=$(echo "$taxid" | taxonkit --data-dir=$srcdir lineage -t | cut -f 3 | tr ';' '\n' | grep . | sort -n | uniq)
alltaxids=$'1\n'"$alltaxids"
numtaxids=$(wc -c <<< $alltaxids)
echo "found $numtaxids taxids after calculating each taxon's lineage"

# Filter nodes.dmp and names.dmp for $alltaxids
echo "Finding all filtered taxids in $srcnodes"
num=0
# Replace the for loop with regex for grep
regex=$(echo "$alltaxids" | perl -plane 's/(\d+)/^$1\t/' | tr '\n' '|' | sed 's/|$//');

grep -E "$regex" $srcnodes > $outnodes
grep -E "$regex" $srcnames > $outnames

# Copy in the rest of the source files
echo "Copying any remaining taxonomy files to the target"
for i in $srcdir/*.dmp; do
    cp -nv $i $outdir/
done