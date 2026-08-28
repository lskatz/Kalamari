#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw/GetOptions/;

my $help;
GetOptions("help" => \$help) or die usage();
print usage() and exit 0 if $help;

my $header = <>;
die "ERROR: input must be an ICTV TSV file\n" if !defined $header;
chomp $header;
my @header = split /\t/, $header, -1;
my %column;
@column{@header} = (0 .. $#header);

for my $required ("species (ICTV)", "species_id", "genus_id") {
  die "ERROR: missing required column '$required'\n"
    if !exists $column{$required};
}

print "scientificName\tnuccoreAcc\ttaxid\tparent\tsource\n";
while (<>) {
  chomp;
  next if !length;
  my @field = split /\t/, $_, -1;
  my $species = $field[$column{"species (ICTV)"}];
  my $taxid = $field[$column{species_id}];
  my $genus_taxid = $field[$column{genus_id}];
  my $assembly = $field[$column{"NCBI Assembly accession"}]
    if exists $column{"NCBI Assembly accession"};
  next if !defined($assembly) || !length($assembly);

  my $acc = join("", edirect(
    "esearch -db assembly -query " . quote($assembly) .
    " | elink -target nuccore -name assembly_nuccore_insdc" .
    " | efetch -format accn"
  ));
  $acc =~ s/\s+/,/g;
  $acc =~ s/^,+|,+$//g;
  if (!length $acc) {
    warn "WARNING: no INSDC accession found for $assembly\n";
    next;
  }

  my $parent = join("", edirect(
    "efetch -db taxonomy -id " . quote($taxid) .
    " -format xml | xtract -pattern Taxon -element ParentTaxId"
  ));
  $parent =~ s/\s+//g;
  $parent = $genus_taxid if !length($parent) && defined($genus_taxid);

  (my $name = $species) =~ s/\s+/_/g;
  print join("\t", $name, $acc, $taxid, $parent, "ICTV"), "\n";
}

sub edirect {
  my ($command) = @_;
  open my $pipe, "-|", $command or die "ERROR: could not run edirect: $!\n";
  my @output = <$pipe>;
  close $pipe;
  return @output;
}

sub quote {
  my ($value) = @_;
  $value =~ s/'/'\\''/g;
  return "'$value'";
}

sub usage {
  return <<"USAGE";
Usage: ictvToKalamari.pl < ictv.tsv > viral-genomes.tsv

Convert an ICTV species TSV export into Kalamari's genome catalog format.
INSDC accessions are resolved from each NCBI assembly with Entrez Direct.
The parent taxid is read from the NCBI taxonomy record; the ICTV genus taxid
is used only when that query returns no value.
USAGE
}
