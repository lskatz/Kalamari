#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use File::Temp qw/tempdir/;
use File::Copy qw/mv/;

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  die usage() if(!@ARGV);
  GetOptions($settings,qw(help debug seqs=s namesdmp=s accessions2taxid=s clusters=s convergence=s outdir=s numcpus=i tempdir=s)) or die $!;
  die usage() if($$settings{help} );
  $$settings{tempdir} //= tempdir("$0.XXXXXX", TMPDIR=>1, CLEANUP=>1);
  $$settings{numcpus} ||= 1;
  $$settings{outdir}  ||= "$0.out"; mkdir $$settings{outdir};
  $$settings{seqs}    ||= die "ERROR: need --seqs";
  $$settings{convergence} ||= die "ERROR: need --convergence";
  $$settings{clusters}||= die "ERROR: need --clusters";
  $$settings{accessions2taxid} ||= die "ERROR: need --accessions2taxid";
  $$settings{namesdmp} ||= die "ERROR: need --namesdmp";

  logmsg "Output directory is $$settings{outdir}";

  my ($samples, $clusters) = readClusters("clusters.tsv", $settings);
  #die Dumper $$clusters{AA842};
  #die Dumper $$samples{FR821778};

  my $seqs = readSeqs($$settings{seqs}, $settings);
  
  my $taxa = readSpreadsheet($$settings{convergence}, $settings);

  my $namesInfo = namesToTaxids($$settings{namesdmp}, $settings);

  # Sort each cluster's samples by "Best" so that the zeroth would be the best 
  # representative of each cluster
  # Choose one representative per cluster
  my $clustersReps = clustersReps($samples, $clusters, $seqs, $taxa, $namesInfo, $$settings{outdir}, $settings);
  my @clusterName = sort keys(%$clusters);
  if($$settings{debug}){
    @clusterName = splice(@clusterName, 0, 200);
    logmsg "DEBUG: Just looking at ".scalar(@clusterName)." clusters";
  }
  my $numClusters = @clusterName;

  # write remaining singleton clusters
  for(my $i=0; $i<$numClusters; $i++){
  #while(my($clusterName,$seqName) = each(%$clustersReps)){
    my $clusterName = $clusterName[$i];
    next if(@{$$clusters{$clusterName}} > 1); # ie, look at singletons only
    my $seqName = $$clusters{$clusterName[$i]}[0];

    my $outfile = "$$settings{outdir}/$clusterName.fasta";

    # Skip if it exists (likely, a singleton cluster)
    if(-e $outfile){
      logmsg "SKIP: Found singleton $outfile ($i / $numClusters)";
      next;
    }
    my $taxon = (defined($$taxa{$seqName})) ? $$taxa{$seqName}{mobcluster_convergence_taxon} : "";
    my $taxid = 0;
    if(defined($$namesInfo{$taxon})){
      $taxid = $$namesInfo{$taxon};
    } else {
      $taxid = accession2Taxid($seqName, $$settings{accessions2taxid}, $settings);
    }
    if(!$taxid){
      die "ERROR: could not find the taxid for $seqName";
    }


    open(my $fh, '>', $outfile."tmp") or die "ERROR writing to $outfile.tmp: $!";
    my $sequence = $$seqs{$seqName} || die "ERROR: could not find sequence for $seqName in $$settings{seqs}";
    $sequence =~ s/(.{1,60})/$1\n/g;
    print $fh ">$seqName|kraken:taxid|$taxid cluster=$clusterName singleton=1 taxon=$taxon\n$sequence\n";
    close $fh;
    mv($outfile."tmp",$outfile) or die $!;

    logmsg "Wrote $outfile ($i / $numClusters)";
  }

  return 0;

}

# map names to taxids
# and taxids to names
sub namesToTaxids{
  my($dmp, $settings) = @_;

  my %map;

  my $rowsCounter = 0;

  local $/ = "\t|\n";
  open(my $fh, $dmp) or die "ERROR reading $dmp: $!";
  while(<$fh>){
    chomp;
    my($taxid, $name, undef, $type) = split(/\t\|\t/, $_);
    next if($type ne 'scientific name');

    $map{$name} = $taxid;
    $map{$taxid}= $name; # reciprocal hash!

    if($rowsCounter > 10000){
      logmsg "DEBUG: only getting $rowsCounter rows from $dmp";
      last;
    }
  }

  return \%map;
}

# Read all sequences in a fasta file into a hash
# with values just being sequence and not Seq object.
sub readSeqs{
  my($file,$settings)=@_;
  my %seq;
  my $numSeqs = 0;

  # Use the lh3 method to read fasta files
  open(my $seqFh, "<", $file) or die "ERROR: could not open $file for reading: $!";
  my @aux = undef;
  my ($id, $seq);
  my ($n, $slen, $comment, $qlen) = (0, 0, 0);
  while ( ($id, $seq, undef) = readfq($seqFh, \@aux)) {
    $seq{$id}=$seq;
    $numSeqs++;

    if($numSeqs > 200){
      logmsg "DEBUG: only reading $numSeqs seqs";
      last;
    }
  };
  return \%seq;
}

# Read the supplemental table with convergence rank, etc
sub readSpreadsheet{
  my($infile, $settings)=@_;

  my %spreadsheet;

  open(my $fh, $infile) or die $!;
  my $header = <$fh>;
  chomp($header);
  my @header = split /\t/, $header;
  while(<$fh>){
    chomp;
    my @F = split /\t/;
    my %F;
    @F{@header} = @F;

    $spreadsheet{$F{accession}} = \%F;
  }

  return \%spreadsheet;
}

# Read the clusters file with key sample_id.
# Return samples hash and clusters hash.
sub readClusters{
  my($infile, $settings) =@_;

  my %cluster;
  my %sample;

  my $clusterField = "secondary_cluster_id"; # primary_cluster_id or secondary_cluster_id
  logmsg "Clustering by $clusterField";

  open(my $fh, "clusters.txt") or die $!;
  my $header = <$fh>;
  chomp($header);
  my @header = split /\t/, $header;
  while(<$fh>){
    chomp;
    my @F = split(/\t/, $_);
    my %F;
    @F{@header} = @F;

    $sample{$F{sample_id}} = \%F;

    push(@{$cluster{$F{$clusterField}}}, $F{sample_id});
  }
  return (\%sample, \%cluster);
}

sub clustersReps{
  my ($samples, $clusters, $seqs, $taxa, $namesInfo, $outdir, $settings) = @_;

  my %representative; # clusterName => seqName

  # get a listing of cluster names
  my @clusterName = sort keys(%$clusters);
  if($$settings{debug}){
    @clusterName = splice(@clusterName, 0, 200);
    logmsg "DEBUG: Just looking at ".scalar(@clusterName)." clusters";
  }
  my $numClusters = @clusterName;

  # Loop through the clusters
  for(my $i=0;$i<$numClusters;$i++){
    my $clusterName = $clusterName[$i];
    my $numSeqs = @{$$clusters{$clusterName}};
    my $clusterRepFile = "$outdir/$clusterName.fasta";
    if(-e $clusterRepFile){

      # If the sequence is more than 1kb then ok I assume it's a complete plasmid
      my $clusterSeqs = readSeqs($clusterRepFile, $settings);
      my($firstSeqId, $firstSeq) = each(%$clusterSeqs);
      if(length($firstSeq) > 1000){
        logmsg "SKIP: Found $clusterRepFile ($i / $numClusters)";
        next;
      }
      # If it's not more than 1kb then let's redo the thing
      logmsg "Found $clusterRepFile but need to redo";
    }

    my %seqForAni;
    for(my $j=0;$j<$numSeqs;$j++){
      my $seqName = $$clusters{$clusterName}[$j];
      if($$seqs{$seqName}){
        $seqForAni{$seqName} = $$seqs{$seqName};
      } else {
        logmsg "WARNING: $seqName not found for cluster $clusterName";
      }
    }

    # Don't bother with ANI if it's just one sequence
    my $numAniSeqs = keys(%seqForAni);
    if($numAniSeqs < 2){
      if($numAniSeqs == 0){
        logmsg "WARNING: no sequences defined for $clusterName";
      } elsif($numAniSeqs == 1){
        $representative{$clusterName} = (keys(%seqForAni))[0];
      }
      next;
    }

    # Find the most central genome for each cluster
    my %aniTotal;
    my $aniResults = ani(\%seqForAni, $settings);
    while(my($query,$hits) = each(%$aniResults)){
      while(my($ref, $ani) = each(%$hits)){
        $aniTotal{$ref}   += $ani;
        $aniTotal{$query} += $ani;
      }
    }

    my @sortedSeqs = sort{
      # Give the best ANI at the integers place
      # or the best length at the kb place
      sprintf("%0.0f",$aniTotal{$b})    <=> sprintf("%0.0f",$aniTotal{$a}) ||
      int(length($$seqs{$b})/1000)*1000 <=> int(length($$seqs{$a})/1000)*1000 ||
      $a cmp $b; # ... or at worst, alphabetical
    } keys(%aniTotal);
    my $seqName = $sortedSeqs[0];
    $representative{$clusterName} = $seqName;

    # get the taxon for this cluster
    if(!defined($$taxa{$seqName})){
      die Dumper \@sortedSeqs, $seqName;
    }
    my $taxon = (defined($$taxa{$seqName})) ? $$taxa{$seqName}{mobcluster_convergence_taxon} : "";
    #my $taxid = (defined($$namesInfo{$taxon})) ? $$namesInfo{$taxon} : -1;
    
    my $taxid = 0;
    if(defined($$namesInfo{$taxon})){
      $taxid = $$namesInfo{$taxon};
    } else {
      $taxid = accession2Taxid($seqName, $$settings{accessions2taxid}, $settings);
    }
    if(!$taxid){
      die "ERROR: could not find the taxid for $seqName";
    }

    # Write sequence to a single file.
    # First to a tmp file and then to the real file
    # to help with resuming where you left off.
    my $sequence = $$seqs{$seqName};
    $sequence =~ s/(.{1,60})/$1\n/g;
    open(my $fh, '>', $clusterRepFile.".tmp") or die "ERROR: could not write to $clusterRepFile.tmp: $!";
    print $fh ">$seqName|kraken:taxid|$taxid cluster=$clusterName singleton=0 taxon=$taxon\n$sequence\n";
    close $fh;
    mv($clusterRepFile.".tmp", $clusterRepFile) or die $!;
    logmsg "Wrote $clusterRepFile ($i / $numClusters)";
  }

  return \%representative;
}

# Run ANI on sequences from a hash whose format is
# id => sequenceStr
sub ani{
  my($seqs, $settings) = @_;

  # initialize the ANI hash
  my %ANI;
  my @seqName = keys(%$seqs);
  for my $seqI(@seqName){
    for my $seqJ(@seqName){
      $ANI{$seqI}{$seqJ}=0;
    }
  }

  my $aniDir = tempdir("$0.XXXXXX", TMPDIR=>1, DIR=>$$settings{tempdir});

  my $log  = "$aniDir/ani.log";
  my $fofn = "$aniDir/fofn.txt";
  open(my $fofnFh, '>', $fofn) or die "ERROR: could not write to $fofn: $!";
  while(my($id,$seq) = each(%$seqs)){
    # Record the filename for ANI later
    my $filename = "$aniDir/$id.fasta";
    print $fofnFh $filename."\n";

    # Print the sequence to file
    open(my $fh, '>', $filename) or die "ERROR: could not write to $filename: $!";
    print $fh ">".$id."\n".$seq."\n";
    close $fh;
  }

  # Run ANI with the fofn
  my @result = `fastANI --ql $fofn --rl $fofn --threads $$settings{numcpus} -o /dev/stdout 2>> $log `;
  for(@result){
    chomp;
    my ($query, $ref, $ani) = split /\t/;

    $query = basename($query, ".fasta");
    $ref   = basename($ref  , ".fasta");

    # Record the sum of both ANI (back and forth)
    $ANI{$query}{$ref} += $ani;
    $ANI{$ref}{$query} += $ani;
  }

  return \%ANI;
}

sub accession2Taxid{
  my($accession, $db, $settings) = @_;
  my $taxid = `sqlite3 $db 'SELECT taxid FROM accession2taxid WHERE accession = "$accession"'`;
  chomp($taxid);
  logmsg "Found taxon from $accession ($taxid) using $db";
  return $taxid;
}

# Read fq subroutine from Andrea which was inspired by lh3
sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!(@$aux)); # remove deprecated 'defined'
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my $name = /^.(\S+)/? $1 : '';
    my $comm = /^.\S+\s+(.*)/? $1 : ''; # retain "comment"
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $seq, $comm, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq, $comm);
}


sub usage{
  "$0: create representative fasta file for Kraken, from mobsuite
  Usage: $0 [OPTIONS] > out.fasta

  OPTIONS
  --seqs     fasta file of all sequences with correct seqnames (ncbi_plasmid_full_seqs.fas)
  --clusters clusters tsv file from mobsuite
  --convergence  Table of convergence information for each cluster (mobsuite TableS5)
  --outdir   output directory
  --accessions2taxid  Database of accessions and taxids, in sqlite3 format
  --namesdmp   names.dmp file
  --debug
  --help     This useful help menu
  --numcpus  Number of cpus to use at least with ANI
  "
}

