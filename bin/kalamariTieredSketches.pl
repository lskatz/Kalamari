#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use File::Find qw/find/;
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help)) or die $!;
  usage() if($$settings{help} || @ARGV < 3);

  my($taxdir, $assembliesdir, $outdir) = @ARGV;

  # Gives a hash of taxid => assembly file
  my $assemblies = readAssemblies($assembliesdir, $settings);
  my $taxonomy   = readTaxonomy($taxdir, $settings);
  die Dumper $taxonomy;

  return 0;
}

# Gives a hash of taxid => assembly file
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
        $assemblies{$taxid} = "$File::Find::name";
      }
    }
  }}, $assembliesdir);

  return \%assemblies;
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
