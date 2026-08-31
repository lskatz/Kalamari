#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw/make_path/;
use File::Find qw/find/;
use File::Temp qw/tempdir/;
use Data::Dumper qw/Dumper/;

local $0 = basename $0;
sub logmsg{ print STDERR "$0: @_\n";}

exit main();

sub main{
    my $settings={};
    GetOptions($settings,qw(help datadir=s check-completeness!)) or die $!;
    die usage() if($$settings{help} || !@ARGV);
    $$settings{'check-completeness'} //= 1;
    $$settings{datadir}||= "$ENV{HOME}/.taxonkit";
    $$settings{tempdir}||= tempdir("$0.XXXXXX", CLEANUP => 1, TMPDIR => 1);

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

      # Assess completeness and genbank accession
      # First, get the NCBI xml
      my $query = $F{nuccoreAcc}."[accn]";
      system("esearch -db nuccore -query '$query' 2>/dev/null | efetch -format docsum 2>/dev/null > $$settings{tempdir}/$F{nuccoreAcc}.xml");
      die "ERROR: efetch returned no results for $F{nuccoreAcc}" if($?);
      #die system("cat $$settings{tempdir}/$F{nuccoreAcc}.xml");

      # Next, parse for each field
      my $ncbiTaxid = `cat $$settings{tempdir}/$F{nuccoreAcc}.xml | xtract -pattern DocumentSummary -element TaxId`;
      chomp $ncbiTaxid;
      
      if($ncbiTaxid ne $F{taxid}){
        # Use edirect to figure out the parent taxid for $ncbiTaxid and compare to $ncbiTaxid
        my $ncbiParentTaxids = `efetch -db taxonomy -id $ncbiTaxid -format xml 2>/dev/null | xtract -pattern Taxon -element TaxId -block "**/Taxon" -element TaxId`;
        chomp $ncbiParentTaxids;
        my @ncbiLineage = split(/\s+/,$ncbiParentTaxids);
        if(!grep{$F{taxid} eq $_ || $F{parent} eq $_} (@ncbiLineage, $ncbiTaxid)){
          print "ERROR: taxid $F{taxid} nor parentTaxid $F{parent} does not match NCBI taxid ($ncbiTaxid) nor any NCBI parent taxids (@ncbiLineage) for $F{nuccoreAcc}\n$kalamariLine\n";
        }
      }

      # Finally, check completeness
      if($$settings{'check-completeness'}){
        my $completeness = `cat $$settings{tempdir}/$F{nuccoreAcc}.xml | xtract -pattern DocumentSummary -element Completeness`;
        chomp $completeness;
        if(lc($completeness) ne "complete"){
          print "ERROR: $F{nuccoreAcc} is not a complete genome according to NCBI (Completeness: $completeness)\n$kalamariLine\n";
        }
      }
    }
}

sub usage{
    "$0: Verify that each contig in a contigs file exists, has a valid taxonomy ID, and is a complete genome.
    Usage: $0 [options] <kalamari contigs tsv file...>
    Options:
      --help                   Show this message
      --datadir                Path to taxonomy files (default: \$HOME/.taxonkit)
      --tempdir                Path to temporary directory (default: system temp dir)
      --no-check-completeness  Skip completeness check (default: false)
    ";
}
