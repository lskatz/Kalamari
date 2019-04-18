#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;

use Test::More tests => 1;

$ENV{PATH}="$RealBin/../bin:$ENV{PATH}";

system("wget https://github.com/DerrickWood/kraken2/archive/v2.0.7-beta.tar.gz");
BAIL_OUT("ERROR downloading kraken2") if $?;
system("tar zxvf v2.0.7-beta.tar.gz");
BAIL_OUT("ERROR uncompressing kraken2") if $?;

my $KRAKEN2_DIR = "target";
system("cd kraken2-2.0.7-beta && ./install_kraken2.sh $KRAKEN2_DIR");
BAIL_OUT("ERROR installing kraken2") if $?;

pass("Installed the kraken2 environment");

