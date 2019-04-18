#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use Net::FTP ();

use Test::More tests => 1;

$ENV{PATH}="$RealBin/../bin:$ENV{PATH}";

my $ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1);
$ftp->login;
$ftp->binary;
$ftp->get("/entrez/entrezdirect/edirect.tar.gz");

system("tar zxf edirect.tar.gz");
BAIL_OUT("ERROR: could not untar edirect.tar.gz") if $?;
unlink("edirect.tar.gz");

system("./edirect/setup.sh");
BAIL_OUT("ERROR: could not set up edirect") if $?;

pass("Installed edirect");

