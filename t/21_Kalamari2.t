#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw/basename dirname/;
use File::Copy qw/cp/;
use File::Find qw/find/;
use Getopt::Long qw/GetOptions/;
use FindBin qw/$RealBin/;

use Test::More tests => 6;

$ENV{PATH}="$RealBin/../bin:$RealBin/../edirect:$ENV{PATH}";

my $src = "Kalamari2_test";
my $version = `$RealBin/../bin/downloadKalamari.pl --version`;
chomp($version);
my $db  = "$RealBin/Kalamari2_v$version";
my $numcpus = 2;
my $tsv = "$RealBin/../src/chromosomes.tsv"; # Kalamari_v$version.tsv";
my $genus = "Cronobacter"; # For testing, just choose one genus that is not redacted

my $kraken_exe = `which kraken2 2>/dev/null`;
chomp($kraken_exe);
if(-x $kraken_exe){
  pass("Found kraken executable: $kraken_exe");
} else {
  fail("Could not find kraken executable or it is not executable");
}
my $kraken_dir = dirname($kraken_exe);

diag("Version is $version");
diag("database location will be $db");
diag("Source files will be read from $src");
diag("Reading from $tsv");
diag("Temporary tsv in $tsv.$genus.tmp");

# Make the test file
open(my $fh, $tsv) or die "ERROR: could not read from $tsv: $!";
open(my $outFh, ">", "$tsv.$genus.tmp") or die "ERROR: could not write to $tsv.$genus.tmp: $!";
my $header = <$fh>;
print $outFh $header;
while(<$fh>){
  next if(!/$genus/);
  print $outFh $_;
}
close $outFh;
close $fh;
END{ unlink("$tsv.$genus.tmp"); }

mkdir $src;
system("perl $RealBin/../bin/downloadKalamari.pl -o $src $tsv.$genus.tmp");
is($?, 0, "Downloaded all fasta files");

mkdir $db;
mkdir "$db/taxonomy";

subtest "Taxonomy files" => sub{
  plan tests => 2;
  for my $file("$db/taxonomy/names.dmp", "$db/taxonomy/nodes.dmp"){
    if(-e $file){
      pass("Found $file");
      next;
    }

    my $oldpath = "$RealBin/../src/taxonomy/".basename($file);
    cp($oldpath, "$file")
      or BAIL_OUT("ERROR: could not copy $oldpath to $file: $!");

    is(-e $file, 1, "Copied $oldpath => $file");
  }
};

subtest "Add-to-library" => sub{
  plan tests => 7;

  find({no_chdir=>1, wanted=>sub{
    my $path = $File::Find::name;
    return if(!-f $path);
    return if($path !~ /$genus/);

    if(-s $path == 0){
      fail("File is zero bytes: $path");
      return;
    }

    diag `
      perl $kraken_dir/kraken2-build --db $db --add-to-library $path 2>&1
    `;
    is($?, 0, "Added $path");
  }}, $src);
};

system("kraken2-build --db $db --build --threads $numcpus");
is($?, 0, "Built Kraken2 database at $db");

system("kraken2-build --db $db --clean");
is($?, 0, "Cleaned the database $db");

END{ system("rm -rf $db"); }


