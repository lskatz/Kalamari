#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 22 09:22:06 2020

@author: henkdenbakker
"""

import os

def main():

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


  with open('src/chromosomes.tsv') as data:
      for line in data:
          line = line.strip().split('\t')
          accession_taxid[line[1]] = line[2]

  with open('src/plasmids.tsv') as data:
      for line in data:
          line = line.strip().split('\t')
          accession_taxid[line[1]] = line[2]

  #fill lineage_graph and ranks_dict

  with open('src/taxonomy/nodes.dmp') as nodes:
      for line in nodes:
          line = line.strip().split('\t')
          lineage_graph[int(line[0])] = int(line[2])
          ranks_dict[int(line[0])] = line[4]
      ranks_dict[1] = 'root'

  with open('src/taxonomy/names.dmp') as nodes: #scientific
      for line in nodes:
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

  for root, dirs, files in os.walk("./"):
      for file in files:
          if file.endswith(".fasta"):
              paths.append(os.path.join(root, file))

  outfile = open('sepia_kalamari_reference.txt', 'w')

  for path in paths:
      accession = path.split('/')[-1].split('.')[0]
      try:
          taxid = accession_taxid[accession]
          lineage = get_lineage(int(taxid), lineage_graph)
          outfile.write(path + '\t' + ';'.join([scientific_name[i] for i in lineage]) + '\n')
      except KeyError:
          print('Could not find accession ' + accession + 'check if it is present in you .tsv files')

  outfile.close()     

if __name__ == "__main__":
  main()

