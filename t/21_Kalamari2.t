#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw/basename dirname/;
use File::Copy qw/cp/;
use File::Find qw/find/;
use Getopt::Long qw/GetOptions/;
use FindBin qw/$RealBin/;

use Test::More tests => 6;

$ENV{PATH}="$RealBin/../bin:$ENV{PATH}";

my $src = "Kalamari2_test";
my $version = 3.5;
my $db  = "Kalamari2_v$version";
my $numcpus = 2;
my $tsv = "$RealBin/../src/Kalamari_v$version.tsv";
my $genus = "Cronobacter"; # For testing, just choose one genus that is not redacted

my $kraken_exe = `which kraken2 2>/dev/null`;
chomp($kraken_exe);
if(-x $kraken_exe){
  pass("Found kraken executable: $kraken_exe");
} else {
  fail("Could not find kraken executable or it is not executable");
}
my $kraken_dir = dirname($kraken_exe);

note("Version is $version");
note("database location will be $db");
note("Source files will be read from $src");
note("Reading from $tsv");

system("$RealBin/../bin/downloadKalamari.pl -o $src $tsv");
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

    my $oldpath = "$RealBin/../src/taxonomy_v$version/".basename($file).".gz";
    cp($oldpath, "$file.gz")
      or BAIL_OUT("ERROR: could not copy $oldpath to $file.gz: $!");

    system("gunzip -f $file.gz");
    is($?, 0, "Gunzipped to create $file");
  }
};

subtest "Add-to-library" => sub{
  plan tests => 7;

  #for my $file(glob("$db/library/

  find({no_chdir=>1, wanted=>sub{
    my $path = $File::Find::name;
    return if(!-f $path);
    return if($path !~ /$genus/);

    if(-s $path == 0){
      fail("File is zero bytes: $path");
      return;
    }

    system("perl $kraken_dir/kraken2-build --db $db --add-to-library $path");
    is($?, 0, "Added $path");
  }}, $src);
};

system("kraken2-build --db $db --build --threads $numcpus");
is($?, 0, "Built Kraken2 database at $db");

system("kraken2-build --db $db --clean");
is($?, 0, "Cleaned the database $db");

