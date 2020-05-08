#!/bin/bash

set -e
set -u

NUMCPUS=24

if [ $# -lt 2 ]; then
  echo "Usage: $0 plasmids.fasta aniThreshold > clusters.tsv"
  exit 0
fi

export sequences=$1
export aniThreshold=$2

# Double check that fastANI works
echo -n "FastANI " >&2
fastANI --version  >&2

TMP=$(mktemp --tmpdir=$(pwd) --directory fastani.XXXXXX)
#trap ' { rm -rf $TMP; } ' EXIT
mkdir "$TMP/log"
mkdir "$TMP/ani"
mkdir "$TMP/cluster"
echo "tmpdir $TMP";

# Separate the sequences into individual seqs
perl -MBio::Perl -e '
  $tmpdir = "'$TMP'/individual";
  mkdir $tmpdir;
  my $counter = 0;
  $in=Bio::SeqIO->new(-file=>"'$sequences'");
  while($seq=$in->next_seq){
    $counter++;
    $out=Bio::SeqIO->new(-file=>">$tmpdir/$counter.fasta");
    $out->write_seq($seq);
  }
';
querylist=$TMP/querylist.fofn
find $TMP/individual -name '*.fasta' > $querylist
numseqs=$(wc -l < $querylist)

qsub -q edlb.q -N fastani -o $TMP/log -e $TMP/log -pe smp 1 -V -cwd -t 1-$numseqs \
  -v "sequences=$sequences" -v "tmp=$TMP" -v "querylist=$querylist" <<- "END_OF_SCRIPT"
  set -e
  set -u
  module load gcc
  ref=$tmp/individual/$SGE_TASK_ID.fasta
  cluster=$(grep -m 1 ">" $ref | sed 's/^>//')

  aniFile=$tmp/ani/$SGE_TASK_ID.tsv;
  fastANI -r $ref --ql $querylist -o $aniFile

  while IFS= read -r line; do
    ANI=$(echo "$line" | cut -f 3)
    if [ "$ANI" == "" ]; then continue; fi;

    # If we have a cluster, include this plasmid
    if (( $(echo "$ANI >= $aniThreshold" | bc -l) )); then
      queryFile=$(echo "$line" | cut -f 1);
      deflineJ=$(grep -m 1 ">" $queryFile | sed 's/^>//')
      cluster="$cluster\t$deflineJ"
    fi
  done < $aniFile

  clusterFile="$tmp/cluster/$SGE_TASK_ID.tsv"
  (
    echo -e "$cluster";
    echo;
  ) > $clusterFile

  echo "Clusters are in $clusterFile"

END_OF_SCRIPT

