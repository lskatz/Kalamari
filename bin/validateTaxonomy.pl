#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw/make_path/;
use File::Find qw/find/;
use Data::Dumper qw/Dumper/;

local $0 = basename $0;
sub logmsg{ print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(help debug-fasta)) or die $!;
  die usage() if($$settings{help} || !@ARGV);

  for my $krakendir (@ARGV){
    my $is_valid = validateTaxonomy($krakendir, $settings);
    logmsg "Valid $krakendir? $is_valid";
  }

  return 0;

}

# Return 1 if the taxonomy is good and 0 if not
sub validateTaxonomy{
  my($krakendir, $settings) = @_;

  my $taxtree_valid = 1;
  my $seqs_have_taxids = 1;

  my $taxdir = "$krakendir/taxonomy";
  my $libdir = "$krakendir/library";

  my $names = readDmp("$taxdir/names.dmp", $settings);
  my $nodes = readDmp("$taxdir/nodes.dmp", $settings);

  # See if every element in nodes has a parent
  logmsg "Validating taxonomy files";
  while(my($taxid, $taxinfo) = each(%$nodes)){
    my $parent = $$taxinfo[0];

    # Die with a useful message if the parent node is not present
    # and if the parent node is not 1 or 0
    if(! $$nodes{$parent} && $parent > 1){
      logmsg "ERROR: could not find node $parent which is the parent of $taxid";
      $taxtree_valid = 0;
    }

    # Find matching entries in names.dmp
    if($taxid > 1 && !$$names{$taxid}){
      logmsg "ERROR: could not find an entry in names.dmp for $taxid";
      $taxtree_valid = 0;
    }
    if($parent > 1 && !$$names{$parent} ){
      logmsg "ERROR: could not find an entry in names.dmp for $parent";
      $taxtree_valid = 0;
    }
    # TODO check the parents up the chain
  }

  # Validate that every fasta entry has a taxonomy representation
  my %fastadir = ();
  my @fasta = ();
  logmsg "Finding all fasta files in $libdir";
  find({wanted => sub{
    print STDERR ".";
    if($$settings{'debug-fasta'} && @fasta > 5){
      logmsg "DEBUG";
      goto END_FIND;
    }
    push(@fasta, $File::Find::name);
  }, no_chdir=>1, follow => 0, }, $libdir);
  # Exit from the find function to here if we are debugging
  END_FIND:
  {
    print STDERR "\n";
  }

  logmsg "Validating fasta files against the taxonomy";
  for my $file(sort @fasta){
    next if(-d $file);
    next if($file !~ /\.f\w+$/);

    # Get the taxid
    open(my $fh, $file) or die "ERROR: could not read from $file: $!";
    while(<$fh>){
      next if(!/^>/);
      chomp;
      my($seqname, $krakenColonTaxid, $taxid) = split /\|/;
      $seqname =~ s/^>//;
      if($krakenColonTaxid ne "kraken:taxid"){
        logmsg "Warning: middle field is not kraken:taxid for seq $seqname. Full line is '$_'";
      }

      if(!$taxid){
        logmsg "Warning: no taxid for $seqname in $file";
      }

      if(!$$nodes{$taxid}){
        logmsg "Warning: taxid $taxid is not represented in nodes.dmp ($file)";
        $seqs_have_taxids = 0;
      }
      if(!$$names{$taxid}){
        logmsg "Warning: taxid $taxid is not represented in names.dmp ($file)";
        $seqs_have_taxids = 0;
      }
    }
    close $fh;
  }

  my $is_good = $taxtree_valid && $seqs_have_taxids;
  return $is_good;
}

sub readDmp{
  my($dmp, $settings) = @_;
  my %dmp;
  open(my $fh, $dmp) or die "ERROR: could not read $dmp: $!";
  while(<$fh>){
    chomp;
    my @F = split /\t\|\t/;
    $F[-1] =~s/\t\|$//; # remove trailing chars for last field
    my $taxid = shift(@F);
    $dmp{$taxid} = \@F;
  }

  return \%dmp;
}

sub usage{
  print "Validate a kraken database for taxonomy
  Usage: $0 krakendb1 [krakendb2...]
  --debug-fasta   Just look at 5 fasta entries
  ";
  exit 0;
}

