# Kalamari

## Synopsis

[![DOI](https://zenodo.org/badge/181688179.svg)](https://doi.org/10.5281/zenodo.13900883)

Kalamari is a database of completed and public assemblies, backed by trusted institutions.
These assemblies can be further used in formatted databases such as Kraken or Blast.

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

## Installation

### conda

The preferred method to install is with Conda. 
1. To get started, clone this repo locally:
```bash
git clone https://github.com/lskatz/Kalamari.git
```

2. Next create a new conda environment, install Kalamari, then activate the environment.
```bash
conda create -n kalamari
conda install -c bioconda kalamari
conda activate kalamari
```

3. Installation of `taxonkit` is required to complete the next step.
Go to [the latest release](https://github.com/shenwei356/taxonkit/releases) and 
download the appropriate version for your system. 
Confirm the tool is functioning in your environment before continuing.

4. Navigate to the directory where you cloned the repo, then install the databases.
This is a lengthy step.

```bash
bash bin/buildTaxonomy.sh
bash bin/filterTaxonomy.sh
```

### Manual installation

Manual installation is viable but less preferred.

Requirements:

- clone this repo locally `git clone https://github.com/lskatz/Kalamari.git`
- NCBI entrez-utilities set of tools `edirect`, `esearch`, etc.
  - install via your package manager
  - debian/ubuntu: `apt install ncbi-entrez-direct`

#### Download instructions

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

    perl bin/downloadKalamari.pl --help

### Optional, but recommended, for either installation type

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

## Database formatting instructions

[How to format and query databases](docs/DATABASES.md)


## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md)

## Citation

Katz LS, Griswold T, Lindsey RL, Lauer AC, Im MS, Williams G, Halpin JL, Gómez GA, Kucerova Z, Morrison S, Page A, Den Bakker HC, Carleton HA. 2025. "Kalamari: a representative set of genomes of public health concern." _Microbiol Resour Announc_ 14:e00963-24. <https://doi.org/10.1128/mra.00963-24>
