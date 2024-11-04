# Kalamari

A database of completed assemblies for metagenomics-related tasks

## Synopsis

Kalamari is a database of completed and public assemblies, backed by trusted institutions.
These assemblies can be further used in formatted databases such as Kraken or Blast.

### Prerequisites & Recommendations

Requirements:

- clone this repo locally `git clone https://github.com/lskatz/Kalamari.git`
- NCBI entrez-utilities set of tools `edirect`, `esearch`, etc.
  - install via your package manager
  - debian/ubuntu: `apt install ncbi-entrez-direct` 

Optional, but recommended:

- `NCBI_API_KEY` environmental variable
- `EMAIL` environmental variable

Ensure that you have the [NCBI API key](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities).
This key associates your edirect requests with your username.
Without it, edirect requests might be buggy.
After obtaining an NCBI API key, add it to your environment with

    export NCBI_API_KEY=unique_api_key_goes_here

where `unique_api_key_goes_here` is a unique hexadecimal number with characters from 0-9 and a-f.

You should also set your email address in the 
`EMAIL` environment variable as edirect tries to guess it, which is an error prone process.
Add this variable to your environment with

    export EMAIL=my@email.address
 
using your own email address instead of `my@email.address`.

## Download instructions

First, build the taxonomy.
The script `buildTaxonomy.sh` uses the diffs in Kalamari to enhance the default NCBI taxonomy.
Next, `filterTaxonomy.sh` reduces the taxonomy files to just those found in Kalamari.
`filterTaxonomy.sh` uses `taxonkit` and so this needs to be in your
environment before starting.

    bash bin/buildTaxonomy.sh
    bash bin/filterTaxonomy.sh

To download the chromosomes and plasmids, use the `.tsv` files, respectively, with `downloadKalamari.pl`.
Run `downloadKalamari.pl --help` for usage.
However, to download the files to a standard location,
please simply use `downloadKalamari.sh` which uses
`downloadKalamari.pl` internally.

    bash bin/downloadKalamari.pl

## Database formatting instructions

[How to format and query databases](docs/DATABASES.md)

## Further description

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

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md)

## Citation

Please refer to the ASM 2018 poster under docs.
