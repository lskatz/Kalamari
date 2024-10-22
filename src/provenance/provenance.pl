#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $header=<>; 
chomp($header); 
print $header."\tsource\n"; 

# Get the list of sources that raw entries in NCBI reports
my @line=`cat ncbi_general.tsv`; 
chomp(@line);
my %ncbi_general;
for(@line){
  my @G = split(/\t/);
  next if(@G < 2);
  next if($G[0] =~ /\s/);
  $ncbi_general{$G[0]}=$G[1];
}

# Get sources: \.\d+$ removes version numbers from accessions.
# Get the list of sources from NCBI references
#my %ncbi_ref = map{chomp; s/\.\d+$//; uc($_)=>1} `cat ncbi.acc`;
my %ncbi_ref = map{chomp; s/\.\d+$//; uc($_)=>1} `zcat ncbi_ref.acc.gz | tr '\t' '\n'`;
# NCTC3000 list of sources
my %nctc     = map{chomp; s/\.\d+$//; uc($_)=>1} `cat nctc3000.acc`;
my %fda      = map{chomp; s/\.\d+$//; uc($_)=>1} `cat fda-argos.acc`;
my %sme      = map{chomp; s/\.\d+$//; uc($_)=>1} `cat SME.acc | tr '\t' '\n'`;

while(<>){
  chomp;
  my @F = split(/\t/);
  my $acc = uc($F[1]);

  $acc =~ s/\.\d+$//;
  my $source = "UNKNOWN";
  if($sme{$acc}){ 
    $source = "SME";
  }elsif($nctc{$acc}){
    $source = "NCTC3000";
  }elsif($fda{$acc}){
    $source = "FDA-ARGOS";
  }elsif($ncbi_ref{$acc}){
    $source = "NCBI-REF";
  }elsif($ncbi_general{$acc}){
    $source = "NCBI-GEN:$ncbi_general{$acc}";
  }
  
  print join("\t", @F, $source)."\n";

}