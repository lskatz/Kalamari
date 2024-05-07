#!/bin/bash

set -eu

thisdir=$(dirname $0)
thisfile=$(basename $0)
KALAMARI_VER=$(downloadKalamari.pl --version)

# Set up some directories
tempdir=$(mktemp -d $thisfile.XXXXXX)
trap "rm -rf $tempdir" EXIT
outdir="$thisdir/../share/kalamari-$KALAMARI_VER/taxonomy"
mkdir -pv $outdir

# output files
outnodes="$outdir/nodes.dmp"
outnames="$outdir/names.dmp"

# Build files
delnodes="$thisdir/../src/taxonomy/build/delnodes.txt"
addnodes="$thisdir/../src/taxonomy/build/nodes.dmp"
addnames="$thisdir/../src/taxonomy/build/names.dmp"

# Source files
srcnodes="$tempdir/nodes.dmp"
srcnames="$tempdir/names.dmp"

# First, download the standard taxonomy dump tar.gz file
curl ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz > $tempdir/taxonomy.tar.gz 
tar -C $tempdir -xzf $tempdir/taxonomy.tar.gz

# Next, build the taxonomy database.
# Remove taxids in $delnodes from the source nodes file
while read -r line; do
    # If we see a comment line, skip it
    if [[ "$line" =~ ^# ]]; then
        continue
    fi

    # Read each 'word' as a taxid and remove it from
    # $srcnodes using sed /d
    for taxid in $line; do
        echo "Removing taxid $taxid from $srcnodes"
        sed -i -e "/^$taxid\t/d" $srcnodes
    done
done < $delnodes

# Add in new nodes and names
echo "Combining NCBI taxonomy with new additions from Kalamari"
cat $srcnodes $addnodes > $outnodes
cat $srcnames $addnames > $outnames

# Copy in the rest of the source files
echo "Copying any remaining taxonomy files to the target"
for i in $tempdir/*.dmp; do
    cp -nv $i $outdir/
done

echo "Output can be found in $outdir"
