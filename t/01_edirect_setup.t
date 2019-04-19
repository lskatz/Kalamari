#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use Net::FTP ();

use Test::More tests => 2;

$ENV{PATH}="$RealBin/../bin:$ENV{PATH}";

diag "Downloading edirect.tar.gz";
my $ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1);
$ftp->login;
$ftp->binary;
$ftp->get("/entrez/entrezdirect/edirect.tar.gz");
$ftp->quit;

if(!-e "edirect.tar.gz"){
  system("wget ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/edirect.tar.gz > wget.log 2>&1");
  if($?){
    diag ("ERROR could not download edirect.tar.gz with either Net::FTP or wget: $!\n".`cat wget.log`);
  }
}

if(!-e "edirect.tar.gz"){
  BAIL_OUT("ERROR: edirect.tar.gz is not present");
}

my @stat = stat("edirect.tar.gz");
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size) = @stat;
ok($size > 0, "Downloaded edirect.tar.gz");

diag "Decompressing edirect.tar.gz";
system("tar xzf edirect.tar.gz");
BAIL_OUT("ERROR: could not untar edirect.tar.gz") if $?;

diag "Installing edirect with setup.sh";
system("./edirect/setup.sh");
BAIL_OUT("ERROR: could not set up edirect") if $?;

pass("Installed edirect");

END{unlink("edirect.tar.gz");}

