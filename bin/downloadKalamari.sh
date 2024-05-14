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
outdir_prefix="$thisdir/../share/kalamari-$VERSION"
mkdir -pv $outdir_prefix

tempdir=$(mktemp --directory KALAMARI.XXXXXX)
trap ' { rm -rf $tempdir; } ' EXIT
echo "TEMPDIR is $tempdir" >&2
echo "OUTDIR  is $outdir_prefix" >&2

TSV="$tempdir/in.tsv"
cat $thisdir/../src/chromosomes.tsv > $TSV
cat $thisdir/../src/plasmids.tsv   >> $TSV

cp -rv $thisdir/../src/taxonomy $tempdir/taxonomy

# Debug with `KALAMARI_DEBUG=1 downloadKalamari.sh`
if [[ ${KALAMARI_DEBUG:+1} ]]; then
  echo "DEBUG was set and so just downloading a few entries" >&2
  mv $TSV $TSV.tmp && \
    head -n 10 $TSV.tmp > $TSV
fi

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

