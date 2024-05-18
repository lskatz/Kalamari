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
    affiliation: 1
  - name: Rebecca Lindsey
    affiliation: 1
  - name: Ana Lauer
  - name: Monica S. Im
    affiliation: 1
  - name: Grant Williams
    affiliation: 1
  - name: Jessica Halpin
    affiliation: 1
  - name: Gerardo A. Gómez
  - name: Katie Roache
  - name: Zuzana Kucerova
    affiliation: 1
  - name: Cheryl L. Tarr
    affiliation: 1
  - name: Andrew Page
  - name: Henk C. Den Bakker
    affiliation: 2
  - name: Heather A. Carleton
    affiliation: 1
affiliations:
  - index: 1
    name: Enteric Diseases Laboratory Branch (EDLB), Centers for Disease Control and Prevention, Atlanta, GA, USA
  - index: 2
    name: Center for Food Safety, University of Georgia, Griffin, GA, USA
date: "May 17, 2024"
bibliography: paper.bib
output:
  html_document:
    toc: no
    number_sections: no
    output:
        html_document:
            toc: no
            number_sections: no
            pandoc_args: [
                "--filter", "pandoc-citeproc",
                "--citeproc",
                "--csl", "apa.csl",
                "--bibliography", "paper.bib",
                "--metadata", "author-meta.yaml"
            ]
---

## Summary

Kalamari is a comprehensive resource that represents genomes from a diversity of organisms of public health concern. It aims to provide researchers and public health professionals with easy access to important genomic data.

## Statement of Need

Public Health utilizes genomics for infectious disease surveillance [@armstrong2019pathogen].
Laboratories sequence whole genomes daily to uncover where pathogens are and who they infect.
Usually, this is in the form of whole genome sequencing (WGS) from cultures,
but it can come from reflect cultures from samples like stool,
or could be actual metegenomics samples [@huang2017metagenomics].
In WGS samples, one might want to perform a quality check to make sure that the sample is not contaminated and is virtually 100% the target sample.
In metagenomics samples, one might want to classify all reads that match the sample's taxonomy.

Therefore, we sought to find representative genomes of relevant pathogens, their hosts in case of a foodborne infection, and even genomes of common contaminants.
These genomes can be used for contamination detection and for metagenomic analysis.

## Features

Kalamari is comprised of three major components:
GenBank accessions, custom taxonomy, and software to utilize the accessions and taxonomy.

### accessions

The genomes in Kalamari are not housed in the repo itself.
Instead, NCBI accessions are in a file describing chromosomes, and another for plasmids.
Each of these files follows a tab-separated values (tsv) custom format.
The tsv files have a header line with the following columns: `scientificName` (genus and species), `nuccoreAcc` (GenBank accession), `taxid` (NCBI or Kalamari Taxonomy ID), and `parent` (the parent taxonomy ID).
Most genomes in the database are bacterial pathogens or related organisms.
All chromosomes and plasmids must be complete, i.e., no contig breaks.

However, there are some pathogen exceptions such as SARS-CoV-2 and _Cryptosporidium_.
Additionally, there are several host organisms. The animal hosts include chicken, human, and squid. The plant hosts include fava beans, tomato, and cabbage.
Most hosts are very large in size and so only the mitochondrial genomes are included as markers.
Also due to the magnitude of possible hosts for foodborne infections,
only a relative select few are included to represent many other possibilities.
For example, tomato chosen to represent the family of tomatoes, potatoes, eggplant, and tobacco;
tuna was selected to represent a variety of fish species.

### taxonomy

Kalamari uses the NCBI Taxonomy database as a baseline.
Then, it has a files to either delete (`delnodes.txt`), or
add taxa (`names.dmp` and `nodes.dmp`).
`names.dmp` and `nodes.dmp` are standardized files that are described in NCBI Taxonomy [@10.1093/nar/gkr1178].
In one special case for _Shigella_, the taxon is deleted
and then re-added as a subspecies for _Escherichia coli_.

### software

To download the accessions in the tsv files, there is an included script
`downloadKalamari.pl` that accesses GenBank with its software, Entrez Direct [@kans2016entrez].
This perl script optimizes the API calls with Entrez Direct by combining multiple accessions in each invocation and by running Entrez Direct concurrently.
`downloadKalamari.pl` has been wrapped in `downloadKalamari.sh` to invoke the perl script with routine options such as the output location.

Building the custom taxonomy is encoded in `buildTaxonomy.sh`, which 1) downloads the NCBI Taxonomy database, 2) deletes taxa (`delnodes.txt`), and then 3) adds taxa (`names.dmp`, `nodes.dmp`).
Optionally, a user can run `filterTaxonomy.sh` to build a reduced taxonomy that only keeps taxa and their lineages in the Kalamari database.
This can result in a much smaller directory size and hypothetically faster downstream analyses.

## Example Usage

Kalamari can be used where most metagenomic analyses are used.
Most commonly, we use Kalamari as the source data for Kraken1 [@wood2014kraken] or Kraken2 [@wood2019improved].
Building the Kraken database has been implemented in `buildKraken1.sh`
and in `buildKraken2.sh`.
However, other descriptions for building databases such as for BLAST
or Mash can be found in the documentation [@camacho2009blast+].

For genomes, a metagenomic database is useful for quality control because
a user can have a null hypothesis that the sample is a metagenomic sample with a singular taxon.
An alternate hypothesis of contamination can be supported when conflicting taxa are detected by the database.
For metagenomes, the database is useful as intended, to detect which taxa are present in a sample.

## Acknowledgements

This work was made possible through support from the Advanced Molecular Detection (AMD) Initiative at the Centers for Disease Control and Prevention.
The opinions expressed by the authors do not necessarily reflect the opinions of Centers for Disease Control and Prevention.

## References
