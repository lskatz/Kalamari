#!/bin/bash

set -e
set -u

thisdir=$(dirname $0)

tempdir=$(mktemp --directory KALAMARI.XXXXXX)
trap ' { rm -rf $tempdir; } ' EXIT
echo "TEMPDIR is $tempdir" >&2

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

#echo "DEBUG" >&2; mv $TSV $TSV.tmp && head -n 5 $TSV.tmp > $TSV

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
}

perl $thisdir/downloadKalamari.pl $TSV \
  --outdir $tempdir/kalamari # --and protein --and nucleotide

if [ -d "./kalamari" ]; then
  rm -rf "./kalamari"
fi

mv -v $tempdir/kalamari .

build_kraken1 ./kalamari ./kraken1.kalamari
build_kraken2 ./kalamari ./kraken2.kalamari

