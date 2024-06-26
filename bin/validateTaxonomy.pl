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

  for my $dir (@ARGV){
    my $is_valid = validateTaxonomy($dir, $settings);
    logmsg "Valid $dir? $is_valid";
  }

  return 0;

}

# Return 1 if the taxonomy is good and 0 if not
sub validateTaxonomy{
  my($taxdir, $settings) = @_;

  my $taxtree_valid = 1;
  my $seqs_have_taxids = 1;

  my $names = readDmp("$taxdir/names.dmp", $settings);
  my $nodes = readDmp("$taxdir/nodes.dmp", $settings);

  # See if every element in nodes has a parent
  logmsg "Validating taxonomy files";
  while(my($taxid, $taxinfo) = each(%$nodes)){
    my $parent = $$taxinfo[0];

    #if($parent == 1){
    #  die Dumper $taxid,$taxinfo,$$names{$taxid},$$nodes{$parent};
    #}

    # Die with a useful message if the parent node is not present
    if(! $$nodes{$parent}){
      logmsg "ERROR: could not find node $parent which is the parent of $taxid";
      $taxtree_valid = 0;
    }

    # Find matching entries in names.dmp
    if(!$$names{$taxid}){
      logmsg "ERROR: could not find an entry in names.dmp for $taxid";
      $taxtree_valid = 0;
    }
    if(!$$names{$parent} ){
      logmsg "ERROR: could not find an entry in names.dmp for $parent";
      $taxtree_valid = 0;
    }
  }

  my $is_good = $taxtree_valid;
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
  print "Validate a taxonomy folder with dmp files
  Usage: $0 folder [folder2...]
  ";
  exit 0;
}

