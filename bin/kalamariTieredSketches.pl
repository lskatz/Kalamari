#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use File::Find qw/find/;
use File::Temp qw/tempdir/;
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help)) or die $!;
  usage() if($$settings{help} || @ARGV < 3);

  $$settings{tempdir} = tempdir(".".basename($0).".XXXXXXXXXX", CLEANUP=>1, TMPDIR=>1);

  my($taxdir, $assembliesdir, $outdir) = @ARGV;
  # There are many reported ranks in the taxonomy and so
  # some of the point is to capture which tiers we actually care about.
  # E.g., we usually do not care about the infraclass level.
  # Note: should we expose this as a command line option? Or is it ok to keep this hard coded?
  my @sortedRank = qw(domain kingdom phylum class order family genus species);

  # TODO
  # Mask all mobile elements 
  # eg. ISFInder DB, plasmids, phage etc 
  # and put these masked assemblies into a new temporary directory.
  # Create the masked genomes into a temporary directory, but then
  # cp it over to a subdirectory of the output directory, so that the
  # masked genomes are available for future use or resuming a canceled run.

  # Find what assemblies belong to what taxids.
  my $assemblies = readAssemblies($assembliesdir, $settings);
  my @taxids = sort {$a<=>$b} keys %$assemblies;
  # Read the taxonomy, and figure out which taxids belong to which taxonomic levels.
  my $taxonomy   = readTaxonomy(\@taxids, $taxdir, $settings);
  die Dumper $taxonomy;
  # Designate which genomes are going to go into which clusters.
  # E.g., 
  #           'kingdom' => {
  #                      'Metazoa' => '33208',
  #                      'Bacillati' => '1783272',
  #                      'Pseudomonadati' => '3379134'
  # And so one cluster at the top would have at least three genomes eachwith a lineage that includes one of these taxids.
  # And then one cluster each for Metazoa, Bacillati, and Pseudomonadati to dive deeper into the taxonomy into phylum.
  # TODO: I do not seem to havea  metazoa, Bacillati, or a Pseudomonadati in the taxonomy hash. Need to debug.

  return 0;
}

# Gives a hash of taxid => array of assembly files
sub readAssemblies{
  my($assembliesdir, $settings) = @_;
  my %assemblies;
  find({wanted => sub{
    my $file = $_;
    return unless -f $file;
    return unless $file =~ /\.fa(sta)?(\.gz)?$/;

    my $z = IO::Uncompress::AnyUncompress->new($file)
        or die "Can't open $file: $AnyUncompressError\n";
    while(my $line = $z->getline){
      chomp $line;
      if($line =~ /^>([^|]+)\|kraken:taxid\|(\d+)/){
        my($accession, $taxid) = ($1, $2);
        push @{$assemblies{$taxid}}, "$File::Find::name";
      }
    }
  }}, $assembliesdir);

  return \%assemblies;
}

sub readTaxonomy{
  my($taxids, $taxdir, $settings) = @_;
  my %taxonomy;

  my $taxidsFile = "$$settings{tempdir}/taxids.txt";
  my $lineageFile = "$$settings{tempdir}/lineage.txt";

  # Write the taxids to a temporary file to play safe with taxonkit.
  open(my $fh, ">", $taxidsFile) or die "ERROR: could not write to $taxidsFile: $!";
  print $fh join("\n", @$taxids) . "\n";
  close($fh);

  # use taxonkit to read the taxonomy, and then figure out which taxids belong to which taxonomic levels.
  system("taxonkit lineage --data-dir $taxdir --show-lineage-ranks --show-lineage-taxids < $taxidsFile > $lineageFile");
  die "Error running taxonkit list: $!" if $?;

  # Read the lineage file into memory, saving each tier of the taxonomy
  # So that we know which taxids belong to which taxonomic levels.
  # This returns a hash like 'family' => { Listeriaceae => 186820, Hominidae => 9604, ... }
  open(my $lineageFh, "<", $lineageFile) or die "ERROR: could not read $lineageFile: $!";
  while(my $line = <$lineageFh>){
    chomp $line;
    my($taxid, $rankValues, $lineageTaxids, $rankKeys) = split("\t", $line);
    my @rankValue = split(";", $rankValues);
    my @lineageTaxid = split(";", $lineageTaxids);
    my @rankKey = split(";", $rankKeys);

    my $numTiers = scalar(@rankKey);
    for(my $i=0; $i<$numTiers; $i++){
      #push(@{ $taxonomy{$rankKey[$i]}{$rankValue[$i]} }, $lineageTaxid[$i]);
      $taxonomy{$rankKey[$i]}{$rankValue[$i]} = $lineageTaxid[$i];
    }
    
  }
  return \%taxonomy;
}

sub usage{
  print "$0: reads a taxonomy and a set of assemblies with taxids in their deflines,
  and produces a tiered sketch for each taxonomic level.
  At the top level, there is just one sketch that represents all kingdoms.
  At the next level, there is one sketch for each kingdom, and the
  sketches represent each phylum.
  Usage: $0 [options] taxdir assembliesdir outdir
  where:
  taxdir        is a directory containing nodes.dmp and names.dmp (optionally: merged.dmp and delnodes.dmp)
  assembliesdir is a directory containing assemblies with taxids in their deflines
                in the format of >accession|kraken:taxid|taxid
                where accession is a unique identifier; kraken:taxid is a literal string;
                and taxid is the taxonomic ID of the assembly.
                Assemblies must have the .fasta or .fa extension, or fasta.gz/.fa.gz.
  outdir        is a directory where the tiered sketches will be written.
  --help   This useful help menu
  \n";
  exit 0;
}
