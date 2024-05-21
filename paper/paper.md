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
    affiliation: 3
  - name: Monica S. Im
    affiliation: 1
  - name: Grant Williams
    affiliation: 1
  - name: Jessica Halpin
    affiliation: 1
  - name: Gerardo A. Gómez
    affiliation: 3
  - name: Katie Roache
    affiliation: 3
  - name: Zuzana Kucerova
    affiliation: 1
  - name: Shatavia Morrison
    affiliation: 1
  - name: Cheryl L. Tarr
    affiliation: 1
  - name: Andrew Page
    affiliation: 4
  - name: Henk C. Den Bakker
    affiliation: 2
  - name: Heather A. Carleton
    affiliation: 1
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

## Summary

Kalamari is a comprehensive resource that represents genomes from a diverse organisms of public health concern. It aims to provide researchers and public health professionals with easy access to high quality genomic references.

## Statement of Need

Public Health laboratories sequence whole genomes daily for genomic epidemiology, ie, to track pathogen spread [@armstrong2019pathogen].
Usually, this is in the form of whole genome sequencing (WGS) from cultures,
but it can come from reflect cultures from samples like stool,
or could be actual metegenomics samples [@huang2017metagenomics].
In isolate WGS samples, one might want to perform a quality check to make sure that the sample is not contaminated and is virtually 100% the target sample.
In metagenomics samples, one might want to classify all reads that confidently match a reference taxonomy database.

Other similar databases exist such as RefSeq [@o2016reference] or The Genome Taxonomy Database (GTDB) [@parks2022gtdb].
However ironically due to their advantages of being so comprehensive,
they become disadvantageous for our specific purposes: 1) The databases become too large and slower to query and 2) The results suffer in sensitivity to species [@nasko2018refseq] and therefore become less informative for pathogen surveillance.

Therefore, we sought to find representative genomes of relevant pathogens, their hosts in case of a foodborne infection, and even genomes of common contaminants.
These genomes can be used for contamination detection and for metagenomic analysis.

## Features

Kalamari is comprised of three major components:
GenBank accessions, custom taxonomy, and software to utilize the accessions and taxonomy.

### accessions

The genomes in Kalamari are not housed in the repo itself.
Instead, NCBI accessions are in a tab-separated values (tsv) file describing chromosomes, and another tsv for plasmids.
The tsv files have a header line with the following columns: `scientificName` (genus and species), `nuccoreAcc` (GenBank accession), `taxid` (NCBI or Kalamari Taxonomy ID), and `parent` (the parent taxonomy ID).
Most genomes in the database are bacterial pathogens or related organisms.
All chromosomes and plasmids must be complete, i.e., no contig breaks,
and they come from trusted sources, e.g., FDA-ARGOS [@sichtig2019fda] or the NCTC 3000 collection [@dicks2023nctc3000], or have been provided and reviewed by a CDC subject matter expert.

In addition to bacterial genomes, there are some viral or protist pathogens such as SARS-CoV-2 and _Cryptosporidium_, and several host organisms. The animal hosts include but are not limited to chicken, human, and squid. The plant hosts include fava beans, tomato, and cabbage.
Most hosts are very large in size and so only the mitochondrial genomes are included as markers.
Also due to the magnitude of possible hosts for foodborne infections,
only a relative select few are included to represent many other possibilities.
For example, tomato chosen to represent the family of tomatoes, potatoes, eggplant, and tobacco;
tuna was selected to represent a variety of fish species.

We also obtained the list of plasmids from the Mob-Suite project [@robertsonMobsuite].
We clustered them at 97% average nucleotide identity (ANI) [@lindsey2023rapid].
For each cluster, the taxonomy identifier was raised to the lowest common tier of taxonomy.
For example, if a cluster of plasmids were identified in both _Escherichia coli_ and _Salmonella enterica_, then taxonomy identifiers for all the plasmids in the cluster were changed to their common family, Enterobacteriaceae.
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

### taxonomy

Kalamari uses the NCBI Taxonomy database as a baseline.
Then, it has a files to either delete (`delnodes.txt`), or
add taxa (`names.dmp` and `nodes.dmp`).
`names.dmp` and `nodes.dmp` are standardized files that are described in NCBI Taxonomy [@10.1093/nar/gkr1178].
In one special case for _Shigella_, the taxon is deleted
and then re-added as a subspecies for _Escherichia coli_.
Other notable additions include lineages for _Listeria_,
groups for _Clostridium botulinum_,
and new subspecies for _Salmonella enterica_.

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
Most commonly, we use Kalamari to customize databases for Kraken1 [@wood2014kraken] or Kraken2 [@wood2019improved].
Building the Kraken database has been implemented in `buildKraken1.sh`
and in `buildKraken2.sh`.
However, other descriptions for building databases such as for BLAST [@camacho2009blast+]
or Mash [@ondov2016mash] can be found in the documentation .

For singular genomes, a metagenomic database is useful for quality control because
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

## References
