#!/bin/bash

set -e

if [[ "$1" =~ -h ]]; then
  echo "Usage: $0 "
  echo "  Downloads the standard chromosomes and plasmids for Kalamari"
  echo "  from source and formats the kraken1 and kraken2 databases"
  exit 0
fi

set -u

thisdir=$(dirname $0)
VERSION=$(downloadKalamari.pl --version)
#VERSION=$(perl -lane 'print $1 if /our \$VERSION\s*=\s*"([^"]+)";/' $thisdir/../Makefile.PL)
outdir_prefix="$thisdir/../share/kalamari-$VERSION"
mkdir -pv $outdir_prefix

tempdir=$(mktemp --directory KALAMARI.XXXXXX)
trap ' { rm -rf $tempdir; } ' EXIT
echo "TEMPDIR is $tempdir" >&2
echo "OUTDIR  is $outdir_prefix" >&2

CHR_URL=https://raw.githubusercontent.com/lskatz/Kalamari/master/src/chromosomes.tsv
PSM_URL=https://raw.githubusercontent.com/lskatz/Kalamari/master/src/plasmids.tsv
TSV="$tempdir/in.tsv"
curl "$CHR_URL" >  "$TSV"
curl "$PSM_URL" >> "$TSV"

NODES_URL=https://github.com/lskatz/Kalamari/raw/master/src/taxonomy/nodes.dmp
NAMES_URL=https://github.com/lskatz/Kalamari/raw/master/src/taxonomy/names.dmp
mkdir "$tempdir/taxonomy"
curl $NODES_URL > $tempdir/taxonomy/nodes.dmp
curl $NAMES_URL > $tempdir/taxonomy/names.dmp

#echo "DEBUG" >&2; mv $TSV $TSV.tmp && head -n 3 $TSV.tmp > $TSV

function build_kraken1(){
  in_dir=$1
  DB=$2

  rm -rvf $DB
  mkdir -v $DB
  cp -rv $tempdir/taxonomy $DB/
  find $in_dir -name '*.fasta' -exec kraken-build -db $DB \
    --add-to-library {} \;
  kraken-build --db $DB --build --threads 1
  kraken-build --db $DB --clean
  du -shc $DB

  echo "DONE. Set KRAKEN_DEFAULT_DB=$(realpath $DB)"
}

function build_kraken2(){
  in_dir=$1
  DB=$2

  rm -rvf $DB
  mkdir -v $DB
  cp -rv $tempdir/taxonomy $DB/
  find $in_dir -name '*.fasta' -exec kraken2-build -db $DB \
    --add-to-library {} \;
  kraken2-build --db $DB --build --threads 1
  kraken2-build --db $DB --clean
  du -shc $DB
  echo "DONE. Set KRAKEN2_DEFAULT_DB=$(realpath $DB)"
}

perl $thisdir/downloadKalamari.pl $TSV \
  --outdir $tempdir/kalamari

rm -rf $outdir_prefix
mkdir -v $outdir_prefix

mv -v $tempdir/kalamari $outdir_prefix/kalamari

#build_kraken1 $outdir_prefix/kalamari $outdir_prefix/kraken1.kalamari
#build_kraken2 $outdir_prefix/kalamari $outdir_prefix/kraken2.kalamari

