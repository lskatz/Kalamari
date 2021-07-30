#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw/make_path/;
use Data::Dumper qw/Dumper/;

local $0 = basename $0;
sub logmsg{ print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(help)) or die $!;
  die usage() if($$settings{help} || !@ARGV);

  for my $taxdir (@ARGV){
    my $is_valid = validateTaxonomy($taxdir, $settings);
    logmsg "Valid: $taxdir";
  }

  return 0;

}

# Return 1 if the taxonomy is good and 0 if not
sub validateTaxonomy{
  my($dir, $settings) = @_;

  my $names = readDmp("$dir/names.dmp", $settings);
  my $nodes = readDmp("$dir/nodes.dmp", $settings);

  # See if every element in nodes has a parent
  while(my($taxid, $taxinfo) = each(%$nodes)){
    my $parent = $$taxinfo[0];

    # Die with a useful message if the parent node is not present
    # and if the parent node is not 1 or 0
    if(! $$nodes{$parent} && $parent > 1){
      logmsg "ERROR: could not find node $parent which is the parent of $taxid";
      return 0;
    }
  }

  return 1;
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
  print "Validate a folder of taxonomy containing nodes.dmp and names.dmp
  Usage: $0 taxonomy/ [taxonomy2...]
  ";
  exit 0;
}

