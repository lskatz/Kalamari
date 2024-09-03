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
    orcid: 0000-0002-2149-7971
  - name: Rebecca L. Lindsey
    affiliation: 1
    orcid: 0000-0002-2149-7971
  - name: A.C. Lauer
    orcid: 0000-0002-2924-758X
    affiliation: 3
  - name: Monica S. Im
    orcid: 0000-0002-4292-7598
    affiliation: 1
  - name: Grant Williams
    affiliation: 1
    orcid: 0000-0002-6033-485X
  - name: Jessica L. Halpin
    affiliation: 1
    orcid: 0000-0003-4108-7010
  - name: Gerardo A. Gómez
    affiliation: 3
    orcid: 0000-0002-1800-8321
  - name: Zuzana Kucerova
    affiliation: 1
    orcid: 0000-0002-7080-5715
  - name: Shatavia Morrison
    affiliation: 1
    orcid: 0000-0002-4658-5951
  - name: Andrew Page
    affiliation: 4
    orcid: 0000-0001-6919-6062
  - name: Henk C. Den Bakker
    affiliation: 2
    orcid: 0000-0002-4086-1580
  - name: Heather A. Carleton
    affiliation: 1
    orcid: 0000-0002-1017-8895
affiliations:
  - index: 1
    name: Division of Foodborne Waterborne and Environmental Diseases (DFWED), Centers for Disease Control and Prevention, Atlanta, GA, USA
  - index: 2
    name: Center for Food Safety, University of Georgia, Griffin, GA, USA
  - index: 3
    name: At the time of this work, DFWED, Centers for Disease Control and Prevention, Atlanta, GA, USA
  - index: 4
    name: Theiagen Genomics, 1745 Shea Center Drive, Suite 400 Highlands Ranch, CO, 80129, USA
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

## Abstract

Kalamari is a resource that supports genomic epidemiology and pathogen surveillance.
It consists of representative genomes and common contaminants.
Kalamari also contains a custom taxonomy and software for downloading and formatting the data.

## Announcement

Public Health laboratories sequence microbial pathogens daily for genomic epidemiology, i.e., to track pathogen spread [@armstrong2019pathogen].
Relevant databases exist such as RefSeq [@o2016reference] or The Genome Taxonomy Database (GTDB) [@parks2022gtdb].
However, due to their so comprehensive nature,
they are disadvantageous for our specific purposes:
either being too large and slower to query or loss of sensitivity to species [@nasko2018refseq], and thus become less informative for pathogen surveillance.

Therefore, we sought to find representative genomes of relevant pathogens, their hosts in case of a foodborne infection, and genomes of common contaminants.
We have also implemented a modified taxonomy and software to utilize the accessions and taxonomy.

### Accessions

Chromosomes and plasmids are in files describing each accession, scientific name, taxonomy ID (taxid), and the parent taxid.
Most genomes in the database are bacterial pathogens or related organisms.
All chromosomes and plasmids are complete, i.e., no contig breaks,
and obtained from trusted sources, e.g., FDA-ARGOS [@sichtig2019fda] or the NCTC 3000 collection [@dicks2023nctc3000], or provided and reviewed by a CDC subject matter expert.

We obtained the list of plasmids from the Mob-Suite project [@robertsonMobsuite]
and clustered them at 97% average nucleotide identity (ANI) [@lindsey2023rapid].
For each cluster, the taxonomy identifier was raised to the lowest common tier of taxonomy.
For example, if a cluster of plasmids were identified in both _Escherichia coli_ and _Salmonella enterica_, then taxonomy identifiers for all the plasmids in the cluster were changed to their common family, _Enterobacteriaceae_.
As a result, any taxonomic signature from these plasmids
is both specific enough to the target taxon and general enough to help avoid any misidentifications.

Finally, it is important to mention that the chromosomes of three significant pathogens are not included in the list of chromosomes, but their plasmids are listed:
_Shigella_, _Yersinia pestis_, and _Bacillus anthracis_.
These taxa have chromosome backbones with very high identity to
_Escherichia coli_, _Yersinia pseudotuberculosis_, and _Bacillus cereus_, respectively.
If these chromosomes were present in a metagenomics analysis,
then any matches against, e.g., _B. cereus_, would match against multiple species thereby giving less helpful genus-level results, e.g., _Bacillus_.
Instead with the current design of Kalamari, a user would receive results
for both _B. cereus_ and _B. anthracis_, giving a more informative signal.

### Taxonomy

Kalamari uses the NCBI Taxonomy database as a baseline [@10.1093/nar/gkr1178].
There are a few crucial modifications.
We reassign _Shigella_ as a subspecies for _Escherichia coli_.
Other notable additions include lineages for _Listeria_,
groups for _Clostridium botulinum_,
and new subspecies for _Salmonella enterica_.

## Data availability

To download the accessions in the tsv files, there is an included script
`downloadKalamari.pl` that accesses GenBank with its software, Entrez Direct [@kans2016entrez].
Accessions reside in the GitHub repo, at <https://github.com/lskatz/kalamari>.

## Acknowledgements

This work was made possible through support from the Advanced Molecular Detection (AMD) Initiative at the Centers for Disease Control and Prevention.
The opinions expressed by the authors do not necessarily reflect the opinions of Centers for Disease Control and Prevention.

Thank you to Dr. Cheryl L. Tarr for helpful discussions and scientific input.
Thank you to Katie Roache for genome sequencing, helpful discussions, and scientific input.

## References
