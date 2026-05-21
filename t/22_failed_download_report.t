#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

use Test::More tests => 5;

my $tmpdir = tempdir("kalamari.failed-downloads.XXXXXX", CLEANUP => 1, TMPDIR => 1);
my $fakeBin = "$tmpdir/fake-bin";
my $outdir  = "$tmpdir/out";
my $tsv     = "$tmpdir/chromosomes.tsv";
make_path($fakeBin, $outdir);

open(my $esearchFh, ">", "$fakeBin/esearch") or die "ERROR: could not write fake esearch: $!";
print $esearchFh "#!/usr/bin/env perl\nexit 0;\n";
close $esearchFh;

open(my $efetchFh, ">", "$fakeBin/efetch") or die "ERROR: could not write fake efetch: $!";
print $efetchFh "#!/usr/bin/env perl\nexit 0;\n";
close $efetchFh;

chmod(0755, "$fakeBin/esearch", "$fakeBin/efetch") or die "ERROR: could not chmod fake binaries: $!";

open(my $tsvFh, ">", $tsv) or die "ERROR: could not write test tsv: $!";
print $tsvFh join("\t", qw(scientificName nuccoreAcc taxid parent source))."\n";
print $tsvFh "Purpureocillium_lilacinum\tLC716767.1\t33203\t1052105\tUGA SME\n";
print $tsvFh "Madeupus species\tFAKE999999.1\t12345\t1\tTEST\n";
close $tsvFh;

{
  local $ENV{PATH} = "$fakeBin:$ENV{PATH}";
  my $cmd = "perl $RealBin/../bin/downloadKalamari.pl --numcpus 1 --buffersize 1 --outdir $outdir --require-all-downloads $tsv";
  system($cmd);
}

isnt($?, 0, "downloadKalamari exits non-zero when required genomes are missing");

my $failedTsv = "$outdir/failed-downloads.tsv";
ok(-e $failedTsv, "failed-downloads.tsv is written");

open(my $failedFh, "<", $failedTsv) or die "ERROR: could not read $failedTsv: $!";
my $failedContent = do { local $/; <$failedFh> };
close $failedFh;

like($failedContent, qr/^scientificName\tnuccoreAcc\ttaxid\tparent\tsource/m, "report has expected header");
like($failedContent, qr/\tLC716767\.1\t/, "report includes accession that previously failed in GitHub Actions");
like($failedContent, qr/\tFAKE999999\.1\t/, "report includes made-up accession");
