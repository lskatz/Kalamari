---
title: 'Kalamari: A Representative Set of Genomes of Public Health Concern'
tags:
  - Genomics
  - Phylogenomics
  - Taxonomy
  - Public Health
  - Bioinformatics
authors:
  - name: Lee S. Katz
    orcid: 0000-0002-2533-9161
    affiliation: "1, 2"
  - name: Taylor Griswold
  - name: Rebecca Lindsey
  - name: Ana Lauer
  - name: Monica S. Im
  - name: Grant Williams
  - name: Jessica Halpin
  - name: Gerardo A. Gómez
  - name: Katie Roache
  - name: Zuzana Kucerova
  - name: Cheryl L. Tarr
  - name: Andrew Page
  - name: Henk C. Den Bakker
    affiliation: 2
  - name: Heather A. Carleton
affiliations:
  - index: 1
    name: Enteric Diseases Laboratory Branch (EDLB), Centers for Disease Control and Prevention, Atlanta, GA, USA
  - index: 2
    name: Center for Food Safety, University of Georgia, Griffin, GA, USA
date: "May 17, 2024"
bibliography: paper.bib
---

## Summary

Kalamari is a comprehensive resource that represents genomes from a diversity of organisms of public health concern. It aims to provide researchers and public health professionals with easy access to important genomic data.

## Statement of Need

Public Health utilizes genomics for infectious disease surveillance (ref pulsenet).
Laboratories sequence whole genomes daily to uncover where pathogens are and who they infect.
Usually, this is in the form of whole genome sequencing (WGS) from cultures (ref),
but it can come from reflect cultures from samples like stool (ref?),
or could be actual metegenomics samples (ref: Huang et al 2017).
In WGS samples, one might want to perform a quality check to make sure that the sample is not contaminated and is virtually 100% the target sample.
In metagenomics samples, one might want to classify all reads that match the sample's taxonomy.

Therefore, we sought to find representative genomes of relevant pathogens and even those of common contaminants.
These genomes can be used for contamination detection and for metagenomic analysis.

## Features

Kalamari is comprised of three major components:
GenBank accessions, custom taxonomy, and software to utilize the accessions and taxonomy.

### accessions

The genomes in Kalamari are not housed in the repo itself.
Instead, NCBI accessions are in a file describing chromosomes, and another for plasmids.
Each of these files follows a tab-separated values (tsv) custom format.
The tsv files have a header line with the following columns: `scientificName` (genus and species), `nuccoreAcc` (GenBank accession), `taxid` (NCBI or Kalamari Taxonomy ID), and `parent` (the parent taxonomy ID).

### taxonomy

Kalamari uses the NCBI Taxonomy database as a baseline.
Then, it has a files to either delete (`delnodes.txt`), or
add taxa (`names.dmp` and `nodes.dmp`).
In one special case for _Shigella_, the taxon is deleted
and then re-added as a subspecies for _Escherichia coli_.

### software

## Example Usage

Provide a brief example of how to use the software.

## Acknowledgements

Acknowledge any funding sources or individuals who have contributed to the project.

## References
