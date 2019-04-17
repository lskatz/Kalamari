#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw/make_path/;
use Data::Dumper qw/Dumper/;

use threads;

local $0 = basename $0;
sub logmsg{ print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(numcpus=i outdir=s help)) or die $!;
  $$settings{outdir} //= "Kalamari";
  $$settings{numcpus}||= 1;

  # Check for prerequisites
  for my $exe(qw(esearch efetch)){
    my $path = which($exe);
    if(!$path){
      die "ERROR: could not find $exe in PATH!";
    }
  }

  my @spreadsheet = @ARGV;

  for my $s(@spreadsheet){
    downloadKalamari($s, $$settings{outdir}, $settings);
  }

  return 0;
}

sub downloadKalamari{
  my($spreadsheet, $outdir, $settings) = @_;

  my $download_counter = 0;
  open(my $fh, $spreadsheet) or die "ERROR: could not read $spreadsheet: $!";
  my $header = <$fh>;
  chomp($header);
  my @header = split /\t/, $header;
  while(<$fh>){
    chomp;
    my %F;
    @F{@header} = split /\t/;
    my $fasta = downloadEntry(\%F, $settings);
    $download_counter++;
  }
  close $fh;

  return $download_counter;
}

sub downloadEntry{
  my($fields) = @_;
  my $dir = $$fields{scientificName};
  $dir =~ s|_+|/|g;

  make_path($dir);

  die Dumper $fields;

  my $acc = "$$fields{nuccoreAcc}.fasta";
  my $outfile = "$dir/$acc.fasta";
  my $command = "esearch -db nuccore -query $acc | efetch -format fasta > $outfile";
  system($command);
  if($?){
    die "ERROR: could not download $acc: $!\n  Command: $command";
  }

  return $outfile;
}

sub which{
  my($tool_name)=@_;
  for my $path ( split /:/, $ENV{PATH} ) {
      my $exe = "$path/$tool_name";
      if ( -f $exe && -x $exe ) {
          return $exe;
          last;
      }
  }
  return "";
}

sub usage{
  "Usage: $0 [options] spreadsheet.tsv

  --outdir  ''  Output directory of Kalamari database
  --numcpus  1
  ";
}
