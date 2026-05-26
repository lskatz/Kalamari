#!/usr/bin/env perl

use strict;
use warnings;
use Config qw(%Config);
use FindBin qw/$RealBin/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

use Test::More;

sub tsv_to_markdown {
  my ($tsv) = @_;
  my @lines = grep { length($_) } split(/\n/, $tsv);
  return "" if !@lines;

  my @header = split(/\t/, shift @lines);
  my @markdown = (
    "| " . join(" | ", @header) . " |",
    "| " . join(" | ", map { "---" } @header) . " |",
  );
  for my $line (@lines) {
    my @cols = split(/\t/, $line);
    push(@markdown, "| " . join(" | ", @cols) . " |");
  }
  return join("\n", @markdown) . "\n";
}

sub in_path {
  my ($exe) = @_;
  my $pathSeparator = $Config{path_sep} || ":";
  for my $dir (split(/\Q$pathSeparator\E/, $ENV{PATH} // "")) {
    my $candidate = "$dir/$exe";
    return 1 if (-x $candidate);
  }
  return 0;
}

for my $exe (qw(esearch efetch)) {
  if (!in_path($exe)){
    plan skip_all => "$exe is required in PATH for this test";
  }
}

plan tests => 5;

my $tmpdir = tempdir("kalamari.failed-downloads.XXXXXX", CLEANUP => 1, TMPDIR => 1);
my $outdir  = "$tmpdir/out";
my $tsv     = "$tmpdir/chromosomes.tsv";
make_path($outdir);

open(my $tsvFh, ">", $tsv) or die "ERROR: could not write test tsv: $!";
print $tsvFh join("\t", qw(scientificName nuccoreAcc taxid parent source))."\n";
print $tsvFh "Purpureocillium lilacinum\tFAKE111111.1\t33203\t28196\tUGA SME\n";
print $tsvFh "Madeupus species\tFAKE999999.1\t12345\t470\tTEST\n";
close $tsvFh;

my $cmd = "perl $RealBin/../bin/downloadKalamari.pl --numcpus 1 --buffersize 1 --outdir $outdir --require-all-downloads $tsv";
system($cmd);

my $exitCode = $? >> 8;
is($exitCode, 1, "downloadKalamari exits with code 1 when required genomes are missing");

my $failedTsv = "$outdir/failed-downloads.tsv";
ok(-e $failedTsv, "failed-downloads.tsv is written");

open(my $failedFh, "<", $failedTsv) or die "ERROR: could not read $failedTsv: $!";
my $failedContent = do { local $/; <$failedFh> };
close $failedFh;
if ($ENV{KALAMARI_SHOW_FAILED_DOWNLOAD_TABLE}) {
  diag("failed-downloads.tsv:\n$failedContent");
  my $failedMarkdown = tsv_to_markdown($failedContent);
  diag("failed-downloads.md:\n$failedMarkdown");
}
my @failedLines = grep { length($_) } split(/\n/, $failedContent);

is(scalar(@failedLines), 3, "report has header plus two failed rows");
is($failedLines[0], "scientificName\tnuccoreAcc\ttaxid\tparent\tsource", "report has expected header");
my @failedDataLines = @failedLines > 1 ? @failedLines[1 .. $#failedLines] : ();
my @failedAccessions = sort map { (split(/\t/, $_))[1] } @failedDataLines;
is_deeply(\@failedAccessions, [qw(FAKE111111.1 FAKE999999.1)], "report includes both made-up accessions");
