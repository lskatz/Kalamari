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
Kalamari consists of representative genomes, including bacterial, viral, and protist pathogens, plus host organisms, and common contaminants.
Kalamari also contains a custom taxonomy based on the NCBI Taxonomy database and specialized software for database construction and analysis.

## Announcement

Public Health laboratories sequence microbial pathogens daily for genomic epidemiology, i.e., to track pathogen spread [@armstrong2019pathogen].
Usually, this surveillance is in the form of whole genome sequencing (WGS) from single cultures,
but it can come from reflex cultures from samples like stool,
or could be from metagenomic samples [@huang2017metagenomics].
In single isolate WGS samples, one might want to perform a quality check to ensure that the sample is not contaminated and is virtually 100% of the target organism.
In metagenomic samples, one might want to confirm that all reads confidently match a reference taxonomy database.

Other databases exist such as RefSeq [@o2016reference] or The Genome Taxonomy Database (GTDB) [@parks2022gtdb],
but due to their so comprehensive nature,
they are disadvantageous for our specific purposes.
The disadvantages include 1) The databases become too large and slower to query and 2) The results suffer in sensitivity to species [@nasko2018refseq], and thus become less informative for pathogen surveillance.

Therefore, we sought to find representative genomes of relevant pathogens, their hosts in case of a foodborne infection, and genomes of common contaminants.
These genomes can be used for contamination detection and for metagenomic analysis.

### Implementation

Kalamari is comprised of three major components:
GenBank accessions, custom taxonomy, and software to utilize the accessions and taxonomy.

#### Accessions

NCBI accessions are in a tab-separated values (tsv) file describing chromosomes, and another tsv for plasmids.
The tsv files have a header line with the following columns: `scientificName` (genus and species), `nuccoreAcc` (GenBank accession), `taxid` (NCBI or Kalamari Taxonomy ID), and `parent` (the parent taxonomy ID).
Most genomes in the database are bacterial pathogens or related organisms.
All chromosomes and plasmids must be complete, i.e., no contig breaks,
and obtained from trusted sources, e.g., FDA-ARGOS [@sichtig2019fda] or the NCTC 3000 collection [@dicks2023nctc3000], or provided and reviewed by a CDC subject matter expert.

In addition to bacterial genomes, Kalamari incorporates some viral or protist pathogens such as SARS-CoV-2 and _Cryptosporidium_, and several host organisms. The animal hosts include but are not limited to chicken, human, and squid. The plant hosts include fava beans, tomato, and cabbage.
Most host genomes are very large in size and so only the mitochondrial genomes are included as markers.
Also, due to the magnitude of possible hosts and food vehicles,
only a relative select few are included to represent many other possibilities.
For example, tomato was chosen to represent the family _Solanaceae_ which includes tomatoes, potatoes, eggplant, and tobacco;
tuna was selected to represent one genus of fish species, but other fish taxa are included too.

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

#### Taxonomy

Kalamari uses the NCBI Taxonomy database as a baseline.
Then, it has files to either delete (`delnodes.txt`), or
add taxa (`names.dmp` and `nodes.dmp`).
The `.dmp` file format is described in NCBI Taxonomy [@10.1093/nar/gkr1178].
In one special case for _Shigella_, the taxon is deleted
and then re-added as a subspecies for _Escherichia coli_.
Other notable additions include lineages for _Listeria_,
groups for _Clostridium botulinum_,
and new subspecies for _Salmonella enterica_.

## Data availability

To download the accessions in the tsv files, there is an included script
`downloadKalamari.pl` that accesses GenBank with its software, Entrez Direct [@kans2016entrez].
This perl script optimizes the API calls with Entrez Direct by combining multiple accessions in each invocation and by running Entrez Direct concurrently.
`downloadKalamari.pl` has been wrapped in `downloadKalamari.sh` to invoke the perl script with routine options such as the output location.

Building the custom taxonomy is encoded in `buildTaxonomy.sh`, which 1) downloads the NCBI Taxonomy database, 2) deletes taxa (`delnodes.txt`), and then 3) adds taxa (`names.dmp`, `nodes.dmp`).
Optionally, a user can run `filterTaxonomy.sh` to build a reduced taxonomy that only keeps taxa and their lineages in the Kalamari database.
This can result in a much smaller directory size and hypothetically faster downstream analyses.

## Example Usage

Kalamari can be used where most metagenomic analyses are used.
Most commonly, we use Kalamari to customize databases for Kraken1 [@wood2014kraken] or Kraken2 [@wood2019improved].
Building the Kraken database has been implemented in `buildKraken1.sh`
and in `buildKraken2.sh`.
However, other descriptions for building databases such as for BLAST+ [@camacho2009blast]
or Mash [@ondov2016mash] can be found in the documentation.

For single genomes, a metagenomic database is useful for quality control because
a user can have a null hypothesis that the sample is a metagenomic sample with a singular taxon.
An alternate hypothesis of contamination can be supported when conflicting taxa are detected by the database.
Therefore, a data scientist could use Kalamari as a way to detect contamination.
For metagenomes, the database is useful as intended, to detect which taxa are present in a sample.

A more concise example is shown

```bash
# Set up the environment
export PATH=$PATH:$(realpath kalamari/bin)
# Understand where the output files are
KALAMARI_VER=$(downloadKalamari.pl --version)
OUTDIR="kalamari/share/kalamari-$KALAMARI_VER"

# after installing Kalamari
downloadKalamari.sh
# => files are now in $OUTDIR/kalamari
buildTaxonomy.sh
# => files are now in $OUTDIR/taxonomy
filterTaxonomy.sh
# => files are now in $OUTDIR/taxonomy/filtered

# Load kraken1 into the environment
buildKraken1.sh
# => files are now in $OUTDIR/kalamari-kraken

# Unload Kraken1 and then load Kraken2 into the environment
buildKraken2.sh
# => files are now in $OUTDIR/kalamari-kraken2
```

## Acknowledgements

This work was made possible through support from the Advanced Molecular Detection (AMD) Initiative at the Centers for Disease Control and Prevention.
The opinions expressed by the authors do not necessarily reflect the opinions of Centers for Disease Control and Prevention.

Thank you to Dr. Cheryl L. Tarr for helpful discussions and scientific input.
Thank you to Katie Roache for genome sequencing, helpful discussions, and scientific input.

## References
