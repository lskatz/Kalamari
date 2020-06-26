# Kalamari
A database of completed assemblies for metagenomics-related tasks

[![Creative Commons License v4](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](LICENSE.md)

## Synopsis

Kalamari is a database of completed and public assemblies, backed by trusted institutions.
Completed assemblies means that you do not have to worry about the database itself being contaminated with "rogue" contigs.
Additionally, most assemblies were obtained by subject matter experts (SMEs) at
Centers for Disease Control and Prevention (CDC).
Those not from CDC come from other trusted institutions or projects such as
FDA-ARGOS.
Most genomes are from species that are either studied or are common contaminants
in the Enteric Diseases Laboratory Branch (EDLB) at CDC.

Kalamari also comes with a custom taxonomy database such as defining
_Shigella_ as a subspecies of _Escherichia coli_
or defining the four lineages of _Listeria monocytogenes_.
These changes have been backed by trusted SMEs in EDLB.

## Download instructions

For usage, run `perl bin/downloadKalamari.pl --help`

    SRC=Kalamari
    perl bin/downloadKalamari.pl -o $SRC src/chromosomes.tsv

### ...with plasmids

    SRC=Kalamari
    perl bin/downloadKalamari.pl -o $SRC src/chromosomes.tsv src/plasmids.tsv

### taxonomy

The taxonomy files `nodes.dmp` and `names.dmp` are under `src/taxonomy-VER` 
where `VER` is the version of Kalamari.

## Database formatting instructions

[How to format databases](docs/DATABASES.md)

## Database usage

After you create your Kalamari database(s), here is [how to use them](docs/USAGE.md)

## Citation

Please refer to the ASM 2018 poster under docs
