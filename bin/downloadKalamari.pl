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
  $dir =~ s/[\.\-'"\(\)]+/_/g;
  $dir="$$settings{outdir}/$dir";

  make_path($dir);

  my $acc = "$$fields{nuccoreAcc}";
  my $outfile = "$dir/$acc.fasta";
  # If it exists, then skip the download
  if(-e $outfile && -s $outfile > 0){
    logmsg "  SKIP: found $outfile already";
    return $outfile;
  }

  # Get the esearch xml in place for at least one downstream query
  my $esearchXml = "$dir/$acc.esearch.xml";
  system("esearch -db nuccore -query '$acc' > $esearchXml");
  if($?){
    die "ERROR running esearch: $!";
  }

  # Download the accessory files
  downloadCds("$dir/$acc", "protein", $settings);
  downloadCds("$dir/$acc", "nucleotide", $settings);
  geneCoordinatesFile("$dir/$acc", $settings);

  # Main query: efetch
  my $command = "cat $esearchXml | efetch -format fasta > $outfile.tmp";
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
  unlink($esearchXml);

  return $outfile;
}

sub downloadCds{
  my($outfile, $which, $settings) = @_;

  # The output file is .faa, the protein sequences,
  # but if the type is nucleotide, then it's .ffn.
  my $faaFile = "$outfile.faa";
  if($which =~ /nuc/i){
    $faaFile = "$outfile.ffn";
  }
  if(-e $faaFile){
    logmsg "Not redownloading $faaFile";
    return $faaFile;
  }

  my $esearchXml = "$outfile.esearch.xml";
  my $command = "cat $esearchXml | efetch -format fasta_cds_aa > $faaFile.tmp";
  if($which =~ /nuc/i){
    $command = "cat $esearchXml | efetch -format fasta_cds_na > $faaFile.tmp";
  }
    
  system($command);
  if($?){
    # If there was an error, wait 3 seconds to help with any backlog in the API
    my $msgF = "%s: could not download protein for $faaFile: %s\n  Command: $command";
    logmsg sprintf($msgF, "WARNING", $!);
    sleep 3;
    # after waiting 3 seconds, run again
    system($command);
    # If there is still an error, die
    if($?){
      die sprintf($msgF, "ERROR", $!);
    }
  }
  if(-s "$faaFile.tmp" == 0){
    #unlink("$outfile");
    #unlink("$outfile.tmp");
    return "";
  }
  mv("$faaFile.tmp", $faaFile) or die $!;

  return $outfile;
}

sub geneCoordinatesFile{
  my($outfile, $settings) = @_;

  my $coordinatesFile = "$outfile.genes";
  if(-e $coordinatesFile){
    return $coordinatesFile;
  }

  open(my $genesFh, ">", "$coordinatesFile.tmp") or die "ERROR: could not write to $coordinatesFile.tmp: $!";
  # header definitions: https://github.com/snayfach/MIDAS/blob/master/docs/build_db.md
  print $genesFh join("\t", qw(gene_id scaffold_id start end strand gene_type))."\n";

  # Read information from the CDS file
  open(my $ffnFh, "$outfile.ffn") or die "ERROR: could not read $outfile.ffn: $!";
  while(<$ffnFh>){
    next if(! />(\S+)\s+(.+)/);

    my($id, $desc) = ($1, $2);

    # Get all the key/values in the description fields
    my %F;
    while($desc =~ /\[(.+?)\]/g){
      my($key, $value) = split(/=/, $1);
      $F{$key} = $value;
    }

    $id=~ s/^>//;
    my $acc = basename($outfile);

    # determine strandedness and get coordinates
    my ($strand, $start, $stop) = ('+', -1, -1);
    if($F{location} =~ /complement/){
      $strand = '-';
      $F{location} =~ s/[^\d\.]+//g; # remove non-numbers
    }
   ($start, $stop) = split(/\.\./, $F{location});

    print $genesFh join("\t", 
      $id,
      $acc,
      $start,
      $stop,
      $strand,
      $F{gbkey},
    )."\n";

  }

  close $genesFh;
  close $ffnFh;

  mv("$coordinatesFile.tmp", $coordinatesFile) or die $!;

  return $coordinatesFile;
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
