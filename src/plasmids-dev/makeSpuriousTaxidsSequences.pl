#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use List::Util qw/uniq/;
use Bio::Perl;

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help)) or die $!;
  die usage() if($$settings{help} || @ARGV < 2);

  my($clusters, $fastaFile) = @ARGV;

  my $taxids = readClusters($clusters, $settings);
  printSpuriousSequences($fastaFile, $taxids, $settings);

  return 0;
}

sub readClusters{
  my($clusters, $settings) = @_;

  my %taxid;
  open(my $fh, $clusters) or die "ERROR: could not read $clusters: $!";
  while(<$fh>){
    chomp;
    my @id    = uniq(split /\t/);

    my ($acc, undef, undef) = split(/\|/, $id[0]);

    # Figure out all the taxids that $id[0] applies to
    my @taxid;
    my $counter = 0;
    for my $id(@id){
      $counter++;
      my(undef, undef, $taxid) = split(/\|/, $id);
      $taxid //= die "ERROR: taxid not found for ID $id in cluster $counter";
      push(@taxid, $taxid);
    }
    # Ensure unique taxids for this sequence
    @taxid = sort { $a <=> $b} uniq(@taxid);
    
    $taxid{$acc} = \@taxid;
  }

  return \%taxid;
}

sub printSpuriousSequences{
  my($fastaFile, $taxids, $settings) = @_;

  my $counter_in = 0;
  my $in = Bio::SeqIO->new(-file=>$fastaFile);
  my $out= Bio::SeqIO->new(-format=>"fasta");
  while(my $seq=$in->next_seq){
    my $acc = $seq->id;
    $acc =~ s/\..*$//; # remove versioning
    my $sequence = $seq->seq;
    my $taxid = $$taxids{$acc};
    if(!ref($taxid) || !@$taxid){
      logmsg "SKIPPING: acc $acc does not exist in clusters file";
      next;
    }
    for my $taxid(@$taxid){
      my $newId = "$acc|kraken:taxid|$taxid";
      $out->write_seq(Bio::Seq->new(-id=>$newId, -seq=>$sequence));
    }
  }
  $counter_in++;
}

sub usage{
  "$0: Duplicates sequence entries when they are binned together. Adds correct taxids in duplications.
  Usage: $0 [options] clusters.tsv in.fasta > out.fasta
  clusters.tsv One cluster per line, tab delimited, each 
               entry is a sequence entry.
               Each ID is a kraken-formatted ID, e.g.,
               NC_012345|kraken:taxid|9876
  in.fasta     Input fasta file whose IDs are kraken-
               formatted, e.g., NC_012345|kraken:taxid|9876
  out.fasta    Fasta file where each sequence entry is
               duplicated with a new taxid for each
               taxid in a cluster in clusters.tsv
  --help   This useful help menu

  "
}
