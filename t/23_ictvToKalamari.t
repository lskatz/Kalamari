#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use File::Temp qw/tempdir/;
use Test::More tests => 4;

my $tmp = tempdir(CLEANUP => 1);
my $mock = "$tmp/bin";
mkdir $mock or die $!;

write_mock("esearch", <<'SCRIPT');
#!/bin/sh
echo assembly-result
SCRIPT
write_mock("elink", <<'SCRIPT');
#!/bin/sh
cat
SCRIPT
write_mock("efetch", <<'SCRIPT');
#!/bin/sh
case "$*" in
  *"-format accn"*) echo NC_012345.1 ;;
  *) echo '<Taxon><ParentTaxId>10509</ParentTaxId></Taxon>' ;;
esac
SCRIPT
write_mock("xtract", <<'SCRIPT');
#!/bin/sh
echo 10509
SCRIPT

my $input = join("\n",
  "species (conventional)\tspecies (ICTV)\tspecies_id\tgenus\tgenus_id\tNCBI Assembly accession\tICTV VMR identifier",
  "Human virus\tTest virus\t12345\tTestgenus\t10509\tGCF_000000001.1\tVMR1",
  ""
);
local $ENV{PATH} = "$mock:$ENV{PATH}";
my $input_file = "$tmp/ictv.tsv";
open my $input_fh, ">", $input_file or die $!;
print $input_fh $input;
close $input_fh;
my $output = `perl '$RealBin/../bin/ictvToKalamari.pl' < '$input_file'`;
is($? >> 8, 0, "ICTV conversion succeeds");
my @line = grep { length } split /\n/, $output;
is($line[0], "scientificName\tnuccoreAcc\ttaxid\tparent\tsource", "writes Kalamari header");
is($line[1], "Test_virus\tNC_012345.1\t12345\t10509\tICTV", "writes resolved INSDC genome and provenance");
is(scalar(@line), 2, "writes one catalog row");

sub write_mock {
  my ($name, $body) = @_;
  open my $fh, ">", "$mock/$name" or die $!;
  print $fh $body;
  close $fh;
  chmod 0755, "$mock/$name" or die $!;
}
