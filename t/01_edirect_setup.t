#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use Net::FTP ();

use Test::More tests => 2;

$ENV{PATH}="$RealBin/../bin:$ENV{PATH}";

my $ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1);
$ftp->login;
$ftp->binary;
$ftp->get("/entrez/entrezdirect/edirect.tar.gz");
$ftp->quit;

my @stat = stat("edirect.tar.gz");
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size) = @F;
ok($size > 0, "Downloaded edirect.tar.gz\n@stat\n".`ls -lht`);

system("tar xzf edirect.tar.gz");
BAIL_OUT("ERROR: could not untar edirect.tar.gz\n".`ls -lht`) if $?;

system("./edirect/setup.sh");
BAIL_OUT("ERROR: could not set up edirect") if $?;

pass("Installed edirect");

END{unlink("edirect.tar.gz");}

