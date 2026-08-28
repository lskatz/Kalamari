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
    GetOptions($settings,qw(help datadir=s)) or die $!;
    die usage() if($$settings{help} || !@ARGV);
    $$settings{datadir}||= "$ENV{HOME}/.taxonkit";

    logmsg "Using taxonomy files in $$settings{datadir}";
    
    for my $tsv(@ARGV){
        logmsg "Checking $tsv";
        checkContigFile($tsv, $settings);
    }

    return 0;
}

sub checkContigFile{
    my($tsv,$settings)=@_;
    open(my $fh, $tsv) or die "Error opening $tsv: $!";
    my $header=<$fh>;
    chomp $header;
    my @header=split(/\t/,$header);
    
    # A particular order in the headers is not needed but we want to see that they are there
    my @expectedHeader = sort qw(scientificName nuccoreAcc taxid parent source);
    for my $h (@expectedHeader){
      if(!grep($h, @header)){
        die "Error: $tsv is missing expected header '$h'";
      }
    }

    while(my $kalamariLine = <$fh>){
      next if($kalamariLine =~ /^\s*#/); # skip comment lines

      chomp $kalamariLine;
      my @F=split(/\t/,$kalamariLine);
      
      # Get an index of the fields using the @F{@header} syntax.
      my %F;
      @F{@header}=@F;
      
      # Get information about taxonomy from our local taxonomy database
      # Need to check if the taxid is in the database and if the parent taxid is right above that.
      logmsg "Checking taxid and parent taxids for $F{nuccoreAcc} ($F{taxid})";
      open(my $taxFh, "echo '$F{taxid}' | taxonkit lineage -t --data-dir $$settings{datadir} |") or die "ERROR running taxonkit on $F{taxid}: $!";
      while(my $taxonkitLine = <$taxFh>){
        chomp $taxonkitLine;
        my(undef, $namesLineage, $taxidLineage) = split(/\t/,$taxonkitLine);
        my @lineage = split(/;/,$taxidLineage);
        if($lineage[-1] ne $F{taxid}){
          die "ERROR: taxid $F{taxid} was not found in the taxonomy database\n$taxonkitLine\n$kalamariLine";
        }
        if($lineage[-2] ne $F{parent}){
          die "ERROR: parent taxid $F{parent} is not the parent of taxid $F{taxid}\n$taxonkitLine\n$kalamariLine";
        }
      }
      close $taxFh;
      
      #die Dumper \@lineage;
      #@G=`esearch -db nuccore -query "$query" | elink -target taxonomy | efetch -format xml | xtract -pattern Taxon -element TaxId ScientificName -block LineageEx/Taxon -tab "\n" -element TaxId ScientificName Rank`;
    }
}