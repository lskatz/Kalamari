#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw/make_path/;
use File::Copy qw/mv/;
use Data::Dumper qw/Dumper/;

local $0 = basename $0;
sub logmsg{ print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(numcpus=i outdir=s help)) or die $!;
  die usage() if($$settings{help} || !@ARGV);
  $$settings{outdir} //= "Kalamari";
  $$settings{numcpus}||= 1;
  logmsg "Outdir will be $$settings{outdir}";

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
    my @F = split /\t/;
    @F{@header} = splice(@F,0,2);
    if($F{nuccoreAcc} eq 'XXXXXX'){
      logmsg "Skipping $F{scientificName}: has accession $F{nuccoreAcc}";
      next;
    }
    $F{taxid} = \@F;

    my $fasta = downloadEntry(\%F, $settings);
    $download_counter++;
  }
  close $fh;

  return $download_counter;
}

sub downloadEntry{
  my($fields,$settings) = @_;
  logmsg "Downloading $$fields{scientificName}:$$fields{nuccoreAcc}";
  my $dir = $$fields{scientificName};
  $dir =~ s| +|/|g;
  $dir="$$settings{outdir}/$dir";

  make_path($dir);

  my $acc = "$$fields{nuccoreAcc}";
  my $outfile = "$dir/$acc.fasta";
  # If it exists, then skip the download
  if(-e $outfile && -s $outfile > 0){
    logmsg "  SKIP: found $outfile already";
    return $outfile;
  }

  my $command = "esearch -db nuccore -query '$acc' | efetch -format fasta > $outfile.tmp";
  system($command);
  if($?){
    # If there was an error, wait 3 seconds to help with any backlog in the API
    my $msgF = "%s: could not download $acc: %s\n  Command: $command";
    logmsg sprintf($msgF, "WARNING", $!);
    sleep 3;
    # after waiting 3 seconds, run again
    system($command);
    # If there is still an error, die
    if($?){
      die sprintf($msgF, "ERROR", $!);
    }
  }
  if(-s "$outfile.tmp" == 0){
    #unlink("$outfile");
    #unlink("$outfile.tmp");
    return "";
  }

  # Format with Kraken headers
  # Open the fasta file from NCBI
  # and make a string for sprintf with a placeholder for taxid.
  my $stringf="";
  open(my $fh, "$outfile.tmp") or die "ERROR: could not read $outfile.tmp: $!";
    while(<$fh>){
      if(/(>\S+)/){
        $_ = $1 . "|kraken:taxid|%s\n";
      }
      $stringf.=$_;
    }
  close $fh;

  # Write to a new fasta file that will nave new headers
  open(my $fhOut,">", "$outfile.tmp2") or die "ERROR: could not write to $outfile.tmp2: $!";

  # For every taxid, write a new entry with the same sequence
  my $taxids = $$fields{taxid} || [];
  for my $taxid (@$taxids){
    print $fhOut sprintf($stringf, $taxid);
  }
  close $fhOut;

  # Create the final file
  mv("$outfile.tmp2",$outfile) 
    or die "ERROR: could not move $outfile.tmp2 to $outfile: $!";

  # Cleanup
  unlink("$outfile.tmp");

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
