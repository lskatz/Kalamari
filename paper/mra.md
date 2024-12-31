---
title: 'Kalamari: A Representative Set of Genomes of Public Health Concern'
tags:
  - Genomics
  - Phylogenomics
  - Taxonomy
  - Public Health
  - Bioinformatics
bibliography: paper.bib
csl: asm.csl
---

_Running title_: Kalamari database

  Lee S. Katz^A,B,#^,
  Taylor Griswold^A^,
  Rebecca L. Lindsey^A^,
  A.C. Lauer^A^,
  Monica S. Im^A^,
  Grant Williams^A^,
  Jessica L. Halpin^A^,
  Gerardo A. Gómez^A^,
  Zuzana Kucerova^A^,
  Shatavia Morrison^A^,
  Andrew Page^C^,
  Henk C. Den Bakker^B^,
  Heather A. Carleton^A^

^A^Division of Foodborne Waterborne and Environmental Diseases, Centers for Disease Control and Prevention, Atlanta, GA, USA  
^B^Center for Food Safety, University of Georgia, Griffin, GA, USA  
^C^Theiagen Genomics, 1745 Shea Center Drive, Suite 400 Highlands Ranch, CO, 80129, USA  

**Corresponding author**:  
Lee S. Katz  
<gzu2@cdc.gov>  
Enteric Diseases Laboratory Branch, CDC  
1600 Clifton Rd. MS# H23-7  
Atlanta, GA 30333

\pagebreak

## Abstract

Kalamari is a resource that supports genomic epidemiology and pathogen surveillance.
It consists of representative genomes and common contaminants.
Kalamari also contains a custom taxonomy and software for downloading and formatting the data.

## Announcement

Public Health laboratories sequence microbial pathogens daily for many applications including genomic epidemiology [@armstrong2019pathogen],
species identification [@lindsey2023rapid],
and metagenomic analysis [@huang2017metagenomics].
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
and clustered them at 97% average nucleotide identity using edlb_ani_mummer v1 with default options [@lindsey2023rapid].
For each cluster, the taxonomy identifier was raised to the lowest common tier of taxonomy.
For example, if a cluster of plasmids were identified in both _Escherichia coli_ and _Salmonella enterica_, then taxonomy identifiers for all the plasmids in the cluster were changed to their common family, _Enterobacteriaceae_.
As a result, any taxonomic signature from these plasmids
is both specific enough to the target taxon and general enough to help avoid any misidentifications.

Finally, it is important to mention that the chromosomes of three significant pathogens are not included in the list of chromosomes, but their plasmids are listed:
_Shigella_, _Yersinia pestis_, and _Bacillus anthracis_.
These taxa have chromosome backbones with very high identity to
_E. coli_, _Y. pseudotuberculosis_, and _B. cereus_, respectively.
If these chromosomes were present in a metagenomics analysis,
then any matches against, e.g., _B. cereus_, would match against multiple species thereby giving less helpful genus-level results, e.g., _Bacillus_.
Instead with the current design of Kalamari, a user would receive results
for both _B. cereus_ and _B. anthracis_, giving a more informative signal.

### Taxonomy

Kalamari uses the NCBI Taxonomy database as a baseline [@10.1093/nar/gkr1178].
There are a few crucial modifications.
We reassign _Shigella_ as a subspecies for _E. coli_.
Other notable additions include lineages for _Listeria_,
groups for _Clostridium botulinum_,
and new subspecies for _S. enterica_.

## Data availability

To download the accessions in the tsv files, there is an included script
`downloadKalamari.pl` that accesses GenBank with its software, Entrez Direct [@kans2016entrez].
Accessions reside in FigShare at
10.6084/m9.figshare.26980546
and 10.6084/m9.figshare.26980549,
and in the GitHub repo, at <https://github.com/lskatz/kalamari>.
Chromosome accessions are available at <https://github.com/lskatz/Kalamari/blob/master/src/chromosomes.tsv>,
and plasmid accessions are available at <https://github.com/lskatz/Kalamari/blob/master/src/plasmids.tsv>.

## Acknowledgements

This work was made possible through support from the Advanced Molecular Detection (AMD) Initiative at the Centers for Disease Control and Prevention.
The opinions expressed by the authors do not necessarily reflect the opinions of Centers for Disease Control and Prevention.

Thank you to Dr. Cheryl L. Tarr for helpful discussions and scientific input.
Thank you to Katie Roache for genome sequencing, helpful discussions, and scientific input.

## References
