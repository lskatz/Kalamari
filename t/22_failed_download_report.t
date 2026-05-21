#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

use Test::More;

sub inPath {
  my ($exe) = @_;
  for my $dir (split(/:/, $ENV{PATH} // "")) {
    my $candidate = "$dir/$exe";
    return 1 if (-x $candidate);
  }
  return 0;
}

for my $exe (qw(esearch efetch)) {
  if (!inPath($exe)){
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
print $tsvFh "Purpureocillium lilacinum\tFAKE111111.1\t33203\t1052105\tUGA SME\n";
print $tsvFh "Madeupus species\tFAKE999999.1\t12345\t1\tTEST\n";
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

like($failedContent, qr/^scientificName\tnuccoreAcc\ttaxid\tparent\tsource/m, "report has expected header");
like($failedContent, qr/\tFAKE111111\.1\t/, "report includes first made-up accession");
like($failedContent, qr/\tFAKE999999\.1\t/, "report includes made-up accession");
