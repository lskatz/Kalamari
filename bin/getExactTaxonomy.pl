#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw/make_path/;
use File::Which qw/which/;
use File::Copy qw/mv/;
use Data::Dumper qw/Dumper/;

local $0 = basename $0;
sub logmsg{ print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(outdir=s datadir=s help)) or die $!;
  die usage() if($$settings{help} || !@ARGV);
  $$settings{outdir} || die "ERROR: need --outdir";
  $$settings{datadir}||= "$ENV{HOME}/.taxonkit";

  for my $exe(qw(taxonkit)){
    if(!which($exe)){
      die "ERROR: could not find $exe in your PATH";
    }
  }


  # Get a list of all parent and child taxids.
  my %taxid;
  for my $tsv (@ARGV){
    logmsg "Reading from $tsv";
    my $assemblies = readSpreadsheet($tsv, $settings);

    # Scrape info from each accession in the spreadsheet
    while(my($nuccoreAcc,$info) = each(%$assemblies)){
      # Looking at two fields for taxa on the spreadsheet
      for my $key(qw(taxid parent)){
        # Verify they are present
        if(!$$info{$key}){
          die "ERROR: $key was not defined for the line with this info\n".Dumper($info);
        }
        # Add them to our list
        $taxid{$$info{$key}}++;
      }
    }
  }

  my $allTaxid = getLineages(\%taxid, $settings);
  writeDmps($allTaxid, $$settings{outdir}, $settings);

  return 0;
}

sub getLineages{
  my($taxids, $settings) = @_;

  # Keep track of taxids not found
  my %taxidNotFound;

  my %allTaxid;
  my @taxid = sort {$a <=> $b} keys(%$taxids);
  my $taxidStr = join("\n", @taxid);
  open(my $fh, "echo '$taxidStr' | taxonkit lineage -t --data-dir $$settings{datadir} |") or die "ERROR running taxonkit on $taxid[0]...: $!";

  while(<$fh>){
    chomp;
    my($thisTaxid, $names, $lineage) = split /\t/;
    if(!$lineage){
      logmsg "ERROR: no lineage found for $thisTaxid";
      $taxidNotFound{$thisTaxid}++;
    }
    for my $newtaxid(split(/;/, $lineage)){
      $allTaxid{$newtaxid}++;
    }
  }
  close $fh;

  return \%allTaxid;
}

sub writeDmps{
  my($taxids, $outdir, $settings) = @_;

  my @taxid = sort {$a <=> $b} keys(%$taxids);

  # read the nodes file
  my $nodes = readDmp("$$settings{datadir}/nodes.dmp", $settings);
  # read the names file
  my $names = readDmp("$$settings{datadir}/names.dmp", $settings);

  mkdir $outdir;
  open(my $nodesFh, ">", "$outdir/nodes.dmp") or die $!;
  open(my $namesFh, ">", "$outdir/names.dmp") or die $!;

  for my $taxid(@taxid){
    if($$nodes{$taxid}){
      print $nodesFh $$nodes{$taxid};
      print $namesFh $$names{$taxid};
    }
  }
  close $nodesFh;
  close $namesFh;

}

sub readDmp{
  my($dmp, $settings) = @_;
  my %tax;
  open(my $dmpFh,$dmp) or die "ERROR reading $dmp: $!";
  while(<$dmpFh>){
    #s/(\s*\|\s*)+$//g; # right trim
    my($id) = split(/\t/, $_);
    $tax{$id} .= $_;
  }
  close $dmpFh;
  return \%tax;

}

sub readSpreadsheet{
  my($tsv, $settings) = @_;

  my %asm;

  open(my $fh, $tsv) or die "ERROR: could not read $tsv: $!";
  my $header = <$fh>;
  chomp($header);
  my @header = split(/\t/, $header);
  while(my $line = <$fh>){
    chomp $line;
    my %F;
    my @F = split(/\t/, $line);
    @F{@header} = @F;

    $asm{$F{nuccoreAcc}} = \%F;
  }
  close $fh;

  return \%asm;
}

sub usage{
  print "$0: uses taxonkit and a Kalamari spreadsheet to make nodes.dmp and names.dmp
  Usage: $0 -o taxonomy/ spreadsheet.tsv [spreadsheet2.tsv...]
  --outdir    The directory where .dmp files go
  --help      This menu
  --datadir   Alternate location of dmp files. Default: ~/.taxonkit
  ";

  exit 0;
}

