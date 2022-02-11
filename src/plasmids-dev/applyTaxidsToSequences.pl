#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use DBI;
use Bio::SeqIO;

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help discarded=s)) or die $!;
  die usage() if($$settings{help} || @ARGV < 2);

  my($sqlite, $infile) = @ARGV;
  my $discarded = $$settings{discarded} || "/dev/null";

  my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite","","");

  my $numSeqs = convert($infile, $dbh, $discarded, $settings);

  return 0;
}

sub convert{
  my($infile, $dbh, $discardedFile, $settings) = @_;

  my $counter=0;

  my $in = Bio::SeqIO->new(-file=>$infile);
  my $out= Bio::SeqIO->new(-format=>"fasta");
  my $discarded = Bio::SeqIO->new(-format=>"fasta", -file=>">$discardedFile");
  while(my $seq = $in->next_seq){
    my $nuccore = $seq->id;
    $nuccore =~ s/\..*$//; # remove versioning
    my $sth = $dbh->prepare(qq(
      SELECT taxid
      FROM accession2taxid
      WHERE accession = ?;
    ))
      or die "ERROR preparing SELECT statement: ".$dbh->errstr();
    my $res = $sth->execute($nuccore)
      or die "ERROR executing SELECT statement: ".$dbh->errstr();
    my $row = $sth->fetch;
    my $taxid = $$row[0];

    # If we don't have a taxid, then it's most likely a
    # sequence removed from refseq, from the 10 or 20
    # that I manually checked out. Discard them.
    if(!$taxid){
      logmsg "ERROR: could not find taxid for $nuccore";
      $discarded->write_seq($seq);
      next;
    }

    my $krakenId = "$nuccore|kraken:taxid|$taxid";
    $seq->id($krakenId);
    $seq->desc(undef);
    $out->write_seq($seq);
  }

  return $counter;
}

sub usage{
  "$0: changes nuccore IDs to kraken deflines in a fasta
  Usage: $0 [options] accession2taxid.sqlite in.fasta > out.fasta
  --discarded  File path to where discarded sequences go
  --help       This useful help menu
  "
}
