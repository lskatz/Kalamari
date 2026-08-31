#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw/GetOptions/;

sub logmsg {
  my ($message) = @_;
  print STDERR "$message\n";
}

my $help;
GetOptions("help" => \$help) or die usage();
print usage() and exit 0 if($help || !@ARGV);

my $tsvFile = shift @ARGV;

open my $fh, "<", $tsvFile or die "ERROR: could not open '$tsvFile': $!\n";
my $header = <$fh>;
die "ERROR: input must be an ICTV TSV file\n" if !defined $header;
chomp $header;
my @header = split /\t/, $header, -1;
my %column;
@column{@header} = (0 .. $#header);

for my $required ("speciesICTV", "assemblyAcc") {
  die "ERROR: missing required column '$required'\n"
    if !exists $column{$required};
}

my @headerOut=qw(scientificName nuccoreAcc taxid parent source);

print join("\t", @headerOut), "\n";
while (<$fh>) {
  chomp;
  next if /^\s*$/;

  my @field = split /\t/, $_, -1;
  my %F;
  @F{@header} = @field;

  if (!defined($F{"assemblyAcc"}) || !length($F{"assemblyAcc"})){
    logmsg "WARNING: no assembly accession found for $F{speciesICTV}, skipping";
    next;
  }

  my $taxid = ncbiTaxidForSpecies($F{"speciesICTV"});
  if (!defined($taxid) || !length($taxid)) {
    warn "WARNING: no NCBI taxid found for $F{speciesICTV}\n";
    next;
  }

  my $parent = ncbiParentTaxid($taxid);
  if (!defined($parent) || !length($parent)) {
    warn "WARNING: no NCBI parent taxid found for $F{speciesICTV} ($taxid)\n";
    next;
  }

  my $acc = join("", edirect(
    "esearch -db assembly -query " . quote($F{"assemblyAcc"}) . " 2>/dev/null" .
    " | elink -target nuccore -name assembly_nuccore_insdc 2>/dev/null" .
    " | efetch -format accn 2>/dev/null"
  ));
  $acc =~ s/\s+/,/g;
  $acc =~ s/^,+|,+$//g;
  if (!length $acc) {
    warn "WARNING: no INSDC accession found for $F{assemblyAcc}\n";
    next;
  }

  (my $name = $F{"speciesICTV"}) =~ s/\s+/_/g;
  logmsg "processing $name with taxid $taxid, parent $parent, and accession $acc";
  print join("\t", $name, $acc, $taxid, $parent, "ICTV"), "\n";
}

sub ncbiTaxidForSpecies {
  my ($species) = @_;
  my $query = '"' . $species . '"[Scientific Name]';
  my @taxid = edirectValues(
    "esearch -db taxonomy -query " . quote($query) . " 2>/dev/null" .
    " | efetch -format xml 2>/dev/null" .
    " | xtract -pattern Taxon -element TaxId 2>/dev/null"
  );
  @taxid = grep { /^\d+$/ } @taxid;

  warn "WARNING: multiple NCBI taxids found for $species: @taxid; using $taxid[0]\n"
    if @taxid > 1;

  return $taxid[0];
}

sub ncbiParentTaxid {
  my ($taxid) = @_;
  my @parent = edirectValues(
    "efetch -db taxonomy -id " . quote($taxid) . " -format xml 2>/dev/null" .
    " | xtract -pattern Taxon -element ParentTaxId 2>/dev/null"
  );
  @parent = grep { /^\d+$/ } @parent;

  warn "WARNING: multiple NCBI parent taxids found for $taxid: @parent; using $parent[0]\n"
    if @parent > 1;

  return $parent[0];
}

sub edirectValues {
  my ($command) = @_;
  my $output = join(" ", edirect($command));
  $output =~ s/^\s+|\s+$//g;

  return split /\s+/, $output;
}

sub edirect {
  my ($command) = @_;

  open my $pipe, "-|", "($command) < /dev/null" or die "ERROR: could not run edirect: $!\n";
  my @output = <$pipe>;
  warn "WARNING: edirect command failed: $command\n" if !close $pipe;

  return @output;
}

sub quote {
  my ($value) = @_;
  $value =~ s/'/'\\''/g;
  return "'$value'";
}

sub usage {
  return <<"USAGE";
Usage: ictvToKalamari.pl ictv.tsv > viral-genomes.tsv

Convert an ICTV species TSV export into Kalamari's genome catalog format.
INSDC accessions are resolved from each NCBI assembly with Entrez Direct.
The taxid is resolved from the ICTV species name using NCBI taxonomy, and
the parent taxid is read from that NCBI taxonomy record.
USAGE
}
