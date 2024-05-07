#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use File::Temp qw/tempdir/;

...;

my %diff = (
  # Shigella as a subspecies of E. coli
  620 => {
    parent   => 562,
    tax_rank => 'subspecies',
  },
  # wontfix: Yersinia pestis has already been relocated to a species complex
  # wontfix: Bacillus anthracis has already been relocated to a species complex
  # Add Listeria monocytogenes lineages
  9000000 => {
    name      => 'Listeria monocytogenes lineage I',
    parent    => 1639,
  },
  9000001 => {
    name      => 'Listeria monocytogenes lineage II',
    parent    => 1639,
  },
  9000002 => {
    name      => 'Listeria monocytogenes lineage III',
    parent    => 1639,
  },
  9000003 => {
    name      => 'Listeria monocytogenes lineage IV',
    parent    => 1639,
  },
  # Listeria grayi subspecies
  9000012 => {
    name      => 'Listeria grayi subsp. grayi',
    parent    => 1641,
  },
  9000013 => {
    name      => 'Listeria grayi subsp. murrayi',
    parent    => 1641,
  },
  # Add C. bot groups
  9000004 => {
    name      => 'Clostridium botulinum group I',
    parent    => 1491,
  },
  9000005 => {
    name      => 'Clostridium botulinum group II',
    parent    => 1491,
  },
  # Add V. cholerae serogroups
  9000006 => {
    name      => 'Vibrio cholerae serogroup O141',
    parent    => 666,
  },
  9000007 => {
    name      => 'Vibrio cholerae serogroup O75 cluster 1',
    parent    => 666,
  },
  9000008 => {
    name      => 'Vibrio cholerae serogroup O75 cluster 2',
    parent    => 666,
  },
  # Salmonella
  9000009 => {
    name      => 'Salmonella enterica subsp. VIII',
    parent    => 28901,
  },
  9000010 => {
    name      => 'Salmonella enterica subsp. IIa',
    parent    => 28901,
  },
  9000011 => {
    name      => 'Salmonella enterica subsp. IIb',
    parent    => 28901,
  },
  9000014 => {
    name      => 'Salmonella enterica subsp. IIIa',
    parent    => 28901,
  },
  9000015 => {
    name      => 'Salmonella enterica subsp. IIIb',
    parent    => 28901,
  },
  9000016 => {
    name      => 'Salmonella enterica subsp. IX',
    parent    => 28901,
  },
  9000017 => {
    name      => 'Salmonella enterica subsp. X',
    parent    => 28901,
  },
);

my @nodesHeader = qw(tax_id parent tax_rank embl_code division_id inherited_div_flag genetic_code_id inherited_genetic_code_flag mitochondrial_genetic_code_id inherited_mitochondrial_genetic_code_flag genbank_hidden_flag hidden_subtree_root_flag comments);
my @namesHeader = qw(tax_id name unique_name name_class);

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(indir=s outdir=s intsv=s@ maxentries=i help)) or die $!;
  usage() if($$settings{help});
  $$settings{maxentries} ||= 0;
  $$settings{tempdir} = tempdir("$0.XXXXXX", CLEANUP => 1, TMP => 1);

  my $indir = $$settings{indir} or die "ERROR: need --indir";
  my $outdir = $$settings{outdir} or die "ERROR: need --outdir";
  my $intsvs = $$settings{intsv}  or die "ERROR: need --intsv. Multiples are allowed";
  mkdir $outdir if(!-d $outdir);

  # Find the taxonomic IDs that are in the Kalamari spreadsheets
  my $kalamariTaxids = taxidsFromKalamari($intsvs, $settings);
  my $filteredIndir  = filterTaxonomy($kalamariTaxids, $indir, $settings);
  
  convertTaxonomy(\%diff, $filteredIndir, $outdir, $settings);
  
  return 0;
}

sub filterTaxonomy{
  my($kalamariTaxids, $indir, $settings) = @_;
  logmsg "TODO try to filter indir"; return $indir;
  my $filteredDir = "$$settings{tempdir}/taxdump";

  # Make a new input lineage file as described in 
  # example 4 in https://bioinf.shenwei.me/taxonkit/usage/#create-taxdump
  my $leavesFile = "$$settings{tempdir}/leaves.txt";
  open(my $leavesFh, ">", $leavesFile) or die "ERROR: could not write to $leavesFile: $!";
  for my $taxid(@$kalamariTaxids){
    print $leavesFh "$taxid\n";
  }
  close $leavesFh;

  # Run taxonkit to get lineages for each taxon
  my $lineagesFile = "$$settings{tempdir}/lineages.txt";
  system("cat $leavesFile | taxonkit lineage -o $lineagesFile -R -t");
  
  my @taxaRank = qw(superkingdom phylum class order family genus species subspecies);
  my %taxa;
  open(my $fh, $lineagesFile) or die "ERROR: could not read $lineagesFile: $!";
  while(my $line = <$fh>){
    chomp $line;
    my ($taxid, $englishLineage, $intLineage, $ranks) = split(/\t/, $line);
    my @ranks = split(/;/, $ranks);
    my @englishLineage = split(/;/, $englishLineage);
    my @intLineage = split(/;/, $intLineage);

    my %rank;
    for(my $i=0;$i<@intLineage;$i++){
      $rank{$ranks[$i]} = $englishLineage[$i];
    }
    $taxa{$taxid} = \%rank;

    #last if(keys(%taxa) >= 10);
  }
  close $fh;
  
  # Create a spreadsheet of the lineages
  my $lineageSpreadsheet = "$$settings{tempdir}/lineages.tsv";
  open(my $outFh, ">", $lineageSpreadsheet) or die "ERROR: could not write to $lineageSpreadsheet: $!";
  print $outFh join("\t", qw(id), @taxaRank)."\n";
  for my $taxid(sort{$a<=>$b} keys(%taxa)){
    my $F = $taxa{$taxid};
    print $outFh $taxid;
    for(my $i=0; $i<@taxaRank; $i++){
      my $value = $$F{$taxaRank[$i]} || "";
      print $outFh "\t".$value;
    }
    print $outFh "\n";
  }
  close $outFh;

  # Use taxonkit to import and dump
  system("taxonkit create-taxdump -A 1 $lineageSpreadsheet -O $filteredDir --field-accession-as-subspecies");

  return $filteredDir;
  system("ls -lh $filteredDir");
  system("cat $filteredDir/nodes.dmp");
  ...;

}

sub taxidsFromKalamari{
  my($intsv, $settings) = @_;
  my %taxid;
  for my $intsv(@$intsv){
    open(my $fh, $intsv) or die "ERROR: could not read $intsv: $!";
    my $header = <$fh>;
    chomp($header);
    my @header = split(/\t/,$header);
    while(<$fh>){
      chomp;
      my %F;
      @F{@header} = split(/\t/,$_);
      $taxid{$F{taxid}}++;
      $taxid{$F{parent}}++;
    }
    close $fh;
  }
  return [sort{$a <=> $b} keys(%taxid)];
}

sub convertTaxonomy{
  my($update, $indir, $outdir, $settings) = @_;

  my $namesFile = "$indir/names.dmp";
  my $nodesFile = "$indir/nodes.dmp";

  logmsg "Reading $namesFile";
  my $nodes = readNodesDmp($nodesFile, $settings);
  logmsg "Reading $nodesFile";
  my $names = readNamesDmp($namesFile, $settings);
  #logmsg "DEBUG with blank names/nodes"; my $nodes = {}; my $names = {};

  # Apply the changes
  for my $taxid(sort keys(%$update)){
    my $change = $$update{$taxid};
    if(!defined($$names{$taxid})){
      $$names{$taxid} = {
        tax_id  => $taxid,
        name    => $$change{name},
        name_class => 'scientific name',
        unique_name => '',
      };
      $$nodes{$taxid} = {
        tax_id   => $taxid,
        parent   => $$change{parent},
        tax_rank => $$change{tax_rank} || "no rank",

        embl_code => '',
        division_id => '0',
        inherited_div_flag => '1',
        genetic_code_id => '11',
        inherited_genetic_code_flag => '1',
        mitochondrial_genetic_code_id => '0',
        inherited_mitochondrial_genetic_code_flag => '1',
        genbank_hidden_flag => '0',
      };
    }

    # Update anything on nodes.dmp
    for my $key(qw(parent tax_rank)){
      if(defined($$change{$key})){
        $$nodes{$taxid}{$key} = $$change{$key};
      }
    }
    # Update anything on names.dmp
    for my $key(qw(name)){
      if(defined($$change{$key})){
        $$names{$taxid}{$key} = $$change{$key};
      }
    }
  }
  # DONE applying updates

  # Write the new nodes.dmp and names.dmp
  logmsg "Writing nodes.dmp and names.dmp to $outdir";
  writeNodesDmp($nodes, "$outdir/nodes.dmp", $settings);
  writeNamesDmp($names, "$outdir/names.dmp", $settings);

  return 0;
}

# Write the nodes.dmp file
sub writeNodesDmp{
  my($nodes, $outfile, $settings) = @_;
  open(my $outFh, ">", $outfile) or die "ERROR writing to $outfile: $!";
  print $outFh join("\t|\t", @nodesHeader)."\n";
  for my $taxid(sort {$a<=>$b} keys(%$nodes)){
    my $F = $$nodes{$taxid};
    for(my $i=0;$i<@nodesHeader;$i++){
      $$F{$nodesHeader[$i]} = '' if(!defined($$F{$nodesHeader[$i]}));
      print $outFh $$F{$nodesHeader[$i]}."\t|\t";
    }
    print $outFh "\n";
  }
  close $outFh;
}
# Write the names.dmp file
sub writeNamesDmp{
  my($names, $outfile, $settings) = @_;
  open(my $outFh, ">", $outfile) or die "ERROR writing to $outfile: $!";
  print $outFh join("\t|\t", @namesHeader)."\n";
  for my $taxid(sort {$a<=>$b} keys(%$names)){
    my $F = $$names{$taxid};
    for(my $i=0;$i<@namesHeader;$i++){
      $$F{$namesHeader[$i]} = '' if(!defined($$F{$namesHeader[$i]}));
      print $outFh $$F{$namesHeader[$i]}."\t|\t";
    }
    print $outFh "\n";
  }
  close $outFh;
}

sub readNodesDmp{
  my($dmp, $settings) = @_;
  my %tax;
  my @header = @nodesHeader;
  open(my $dmpFh,$dmp) or die "ERROR reading $dmp: $!";
  while(my $F=taxonomyIterator($dmpFh,$settings)){
    my $taxid = $$F[0];
    
    for(my $i=0;$i<@header;$i++){
      $tax{$taxid}{$header[$i]} = $$F[$i];
    }

    if($$settings{maxentries} && keys(%tax) >= $$settings{maxentries}){
      logmsg "DEBUG"; last;
    }

  }
  close $dmpFh;
  return \%tax;
}

# Modified from readDmpHashOfArr() b/c tax_id is not unique
# in names.dmp.
sub readNamesDmp{
  my($dmp, $settings) = @_;
  my %tax;
  my @header = @namesHeader;
  open(my $dmpFh,$dmp) or die "ERROR reading $dmp: $!";
  while(my $F=taxonomyIterator($dmpFh,$settings)){
    next if($$F[3] ne 'scientific name');

    # The entry's value will be an array with the ID
    # lopped off.
    my $taxid = $$F[0];
    for(my $i=0;$i<@header;$i++){
      $tax{$taxid}{$header[$i]} = $$F[$i];
    }
    
    if($$settings{maxentries} && keys(%tax) >= $$settings{maxentries}){
      logmsg "DEBUG"; last;
    }
  }
  close $dmpFh;
  return \%tax;
}

sub taxonomyIterator{
  my($fh,$settings)=@_;
  if(eof($fh)){
    return undef;
  }

  my @taxArr;
  my $line=<$fh>;
  chomp($line);
  while($line=~/\t?([^\|]+)\t?\|?/g){
    my $field = $1;
    $field =~ s/^\t|\t$//g;
    push(@taxArr, $field);
  }
  return \@taxArr;
}

sub usage{
  print "$0: builds a Kalamari taxonomy directory
  Usage: $0 [options]
  --indir      reqd  path to the NCBI taxonomy dump directory
  --outdir     reqd  path to the output directory
  --intsv      reqd  path to the input tsv file(s), formatted
                     like Kalamari tsv files. Multiple
                     files are allowed.
  --maxentries 0     Stop after this many entries in nodes 
                     and names [default: 0, no max]
  --help             This useful help menu
  \n";
  exit 0;
}
