#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__  = "Henk den Bakker"
__version__ = "1.1"
__credits__ = ["Henk den Bakker", "Lee Katz"]
__date__    = "2021-08-20"

import os
import argparse

def main(args):

  #lets check ranks in file
  ranks = set()
  with open('src/taxonomy/nodes.dmp') as nodes:
      for line in nodes:
          line = line.strip().split('\t')
          ranks.add(line[4])

      
  lineage_graph =dict()
  ranks_dict = dict()
  scientific_name = dict()
  accession_taxid = dict()


  for tsv in args.tsv:
    with open(tsv) as data:
        for line in data:
            line = line.strip().split('\t')
            accession_taxid[line[1]] = line[2]

  #fill lineage_graph and ranks_dict

  with open(args.taxonomy + '/nodes.dmp') as nodes:
      for line in nodes:
          line = line.strip().split('\t')
          lineage_graph[int(line[0])] = int(line[2])
          ranks_dict[int(line[0])] = line[4]
      ranks_dict[1] = 'root'

  with open(args.taxonomy + '/names.dmp') as names: #scientific
      for line in names:
          if 'scientific' in line:
              line = line.strip().split('\t')
              scientific_name[int(line[0])] = line[2]
      scientific_name[1] = 'root'        

  def get_lineage(taxid, lineage_graph):
      lineage = [taxid]
      ancestor = 0
      while ancestor != 1:
          ancestor = lineage_graph[taxid]
          lineage.append(ancestor)
          taxid = ancestor
      lineage.reverse()
      return lineage


  paths = []

  for root, dirs, files in os.walk(args.fastadir):
      for file in files:
          if file.endswith(".fasta"):
              paths.append(os.path.join(root, file))

  outfile = open(args.outfile, 'w')

  for path in paths:
      accession = path.split('/')[-1].split('.')[0]
      try:
          taxid = accession_taxid[accession]
          lineage = get_lineage(int(taxid), lineage_graph)
          outfile.write(path + '\t' + ';'.join([scientific_name[i] for i in lineage]) + '\n')
      except KeyError:
          print('Could not find accession ' + accession + '. Check if it is present in you .tsv files')

  outfile.close()     

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Create the references file for Sepia. This is a two-column format with file path and taxonomy string separated by semicolons.")

  parser.add_argument('--version', action='version', version='%(prog)s 1.0')
  parser.add_argument("--taxonomy", "-t", metavar="taxdir", help="The directory with names.dmp and nodes.dmp", required=True) 
  parser.add_argument("--outfile", "-o", metavar="out.tsv", help="The sepia reference file", required=True) 
  parser.add_argument("--fastadir","-f", metavar="fastadir",help="The directory containing files with extension .fasta. The directory will be iteratively parsed.", required=True)
  parser.add_argument("tsv", metavar="kalamari.tsv", help="Kalamari tsv file(s)", nargs='+') 
  args = parser.parse_args()

  main(args)

