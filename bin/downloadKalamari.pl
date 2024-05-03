#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename dirname/;
use File::Path qw/make_path/;
use File::Copy qw/mv/;
use File::Temp qw/tempdir/;
use Data::Dumper qw/Dumper/;
use POSIX qw/ceil/;

use threads;

local $0 = basename $0;
sub logmsg{ my $tid=threads->tid; print STDERR "$0(TID$tid): @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(numcpus=i buffersize|buffer-size=i tempdir=s and=s@ outdir=s help)) or die $!;
  usage() if($$settings{help} || !@ARGV);
  $$settings{outdir} //= "Kalamari";
  $$settings{tempdir} //= tempdir("$0.XXXXXX", CLEANUP=>1, TMPDIR=>1);
  $$settings{numcpus}||= 1;
  $$settings{and}    //= [];
  $$settings{buffersize} //= 10;
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
    my $downloadCount = downloadKalamari($s, $$settings{outdir}, $settings);
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

  my @queue;
  while(<$fh>){
    chomp;
    my %F;
    my @F = split /\t/;
    @F{@header} = @F;
    if($F{nuccoreAcc} eq 'XXXXXX'){
      logmsg "Skipping $F{scientificName}: has accession $F{nuccoreAcc}";
      next;
    }

    push(@queue, \%F);
  }
  close $fh;
  @queue = sort {$$a{nuccoreAcc} cmp $$b{nuccoreAcc} } @queue;

  my @thr;
  my $numPerThread = ceil(scalar(@queue)/$$settings{numcpus});
  for(my $i=0;$i<$$settings{numcpus};$i++){
    my @subQueue = splice(@queue, 0, $numPerThread);
    $thr[$i] = threads->new(\&downloadEntryWorker, \@subQueue, $settings);
    logmsg "Sent ".scalar(@subQueue)." entries to thread ".$thr[$i]->tid;

    # Offset the threads to help avoid exceeding the API
    # rate limit.
    sleep 1;
  }

  # Close out the threads
  my @errors;
  for(my $i=0;$i<@thr;$i++){
    logmsg "Joining thread $i";
    my $fastasAndErrors = $thr[$i]->join;
    my($fastas, $errors) = @$fastasAndErrors;
    push(@errors, @$errors);
  }

  logmsg "Done downloading for $spreadsheet";
  for my $acc(@errors){
    logmsg "ERROR downloading: $acc";
  }
  if(!@errors){
    logmsg "NOTE I did not detect any missing downloads.";
  }

  return $download_counter;
}

sub downloadEntryWorker{
  my($queue, $settings) = @_;

  my $bufferSize = $$settings{buffersize} || 10;

  my @fasta = ();
  my @err;
  while(@$queue > 0){
    my @entries = sort {$$a{nuccoreAcc} cmp $$b{nuccoreAcc} }
                       splice(@$queue, 0, $bufferSize);
    my ($fasta, $err) = downloadEntries(\@entries, $settings);
    push(@fasta, @$fasta);
    push(@err, @$err);
  }

  return [\@fasta, \@err];
}

sub downloadEntries{
  my($entries,$settings) = @_;
  my $numEntries = scalar(@$entries);
  my @acc = map{$$_{nuccoreAcc}} @$entries;
  logmsg "Downloading ".scalar(@acc)." accessions";
  my $queryArg = join("[accession] OR ", sort(@acc))."[accession]";
  my $dir = tempdir("download.XXXXXX", DIR=>$$settings{tempdir});

  # Accessions that had errors
  my @err;

  # Get the esearch xml in place for at least one downstream query
  my $esearchXml = "$dir/esearch.xml";
  my $esearchCmd = "esearch -db nuccore -query '$queryArg' > $esearchXml";
  command($esearchCmd);
  if($?){
    die "ERROR running: $esearchCmd: $!";
  }

  # Get started on the assembly file
  my $outfile = "$dir/all.fasta";

  # Main query: efetch
  my $efetchCmd = "cat $esearchXml | efetch -format fasta > $outfile";
  system($efetchCmd);

  my $seqsWithVersion = readSeqs($outfile);
  my $seqs = {};
  while(my($acc, $seq) = each(%$seqsWithVersion)){
    # Remove the version from the accession
    $acc =~ s/\..+//;
    $$seqs{$acc} = $seq;
  }

  # List of fastas that will be generated
  my @fasta;

  for(my $i=0; $i<$numEntries; $i++){
    my $acc            = $$entries[$i]{nuccoreAcc};
    my $scientificName = $$entries[$i]{scientificName};
    my $taxid          = $$entries[$i]{taxid};

    my $seq = $$seqs{$acc};
    if(!$seq){
      logmsg "WARNING: Could not find assembly for $acc after batch downloading";
      push(@err, $acc);
      next;
    }
    
    my ($genus, $species) = split(/\s+/, $scientificName, 2);
    $species ||= "sp";
    $species =~ s/[^\-_0-9a-zA-Z]+/_/g;
    my $outFasta = "$$settings{outdir}/$genus/$species/$acc.fasta";
    my $defline  = "$acc|kraken:taxid|$taxid";

    logmsg "Writing $outFasta";
    make_path(dirname($outFasta));
    open(my $fh, ">", $outFasta) or die "ERROR: could not write to fasta $outFasta: $!";
    print $fh ">$defline\n$seq\n";
    close $fh;

    push(@fasta, $outFasta);
  }

  return (\@fasta, \@err) if(wantarray);
  return \@fasta;
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

sub command{
  my($command) = @_;
  
  my $maxTries = 10;
  my $numTries = 0;
  do{{
    system($command);

    my $exit_code = $? >> 8;
    if($exit_code){
      logmsg "ERROR on command (numTries: $numTries):\n  $command";
      sleep 1;
    } else {
      last;
    }
  }} while($numTries++ < $maxTries);

}

# Read all sequences in a fasta file into a hash
# with values just being sequence and not Seq object.
sub readSeqs{
  my($file,$settings)=@_;
  my %seq;
  my $numSeqs = 0;

  # Use the lh3 method to read fasta files
  open(my $seqFh, "<", $file) or die "ERROR: could not open $file for reading: $!";
  my @aux = undef;
  my ($id, $seq);
  my ($n, $slen, $comment, $qlen) = (0, 0, 0);
  while ( ($id, $seq, undef) = readfq($seqFh, \@aux)) {
    $seq{$id}=$seq;
    $numSeqs++;

    if($numSeqs > 200){
      logmsg "DEBUG: only reading $numSeqs seqs";
      last;
    }
  };
  return \%seq;
}

# Read fq subroutine from Andrea which was inspired by lh3
sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!(@$aux)); # remove deprecated 'defined'
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my $name = /^.(\S+)/? $1 : '';
    my $comm = /^.\S+\s+(.*)/? $1 : ''; # retain "comment"
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $seq, $comm, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq, $comm);
}

sub usage{
  print
  "Usage: $0 [options] spreadsheet.tsv

  --outdir     ''  Output directory of Kalamari database
  --numcpus     1  How many threads
  --bufferSize 10  How many genomes to down at the same
                   time, per thread
  --tempdir        Directory for temporary files, if you would
                   but default in TMPDIR
  --and            (currently not used) 
                   Download additional files. Multiple --and
                   flags are allowed.
                   Possible values: protein, nucleotide
                   where either protein or nucleotide will
                   return files with CDS entries.
                   E.g., $0 --and protein --and nucleotide
";
  exit 0;
}
