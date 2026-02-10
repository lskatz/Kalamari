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

---

## Installation
To start using Kalamari, you'll need to complete the following steps:
1. [Export variables for NCBI API](#export-variables-for-ncbi-api)
2. Install Kalamari dependencies
    - Chose either [Conda](#installation-with-conda) (preferred) or [manual installation](#manual-installation).
3. [Download the databases](#download-the-databases)
4. [Build and filter the taxonomy directory](#build-and-filter-the-taxonomy-directory)

---

### Export Variables for NCBI API
NCBI edirect requests run considerably more smoothly when the following environment variables are set:
- `NCBI_API_KEY` 
- `EMAIL` 

Follow [these instructions](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities) to 
obtain an NCBI API key.
This key associates your edirect requests with your username.
Without it, edirect requests might be buggy.
After obtaining an NCBI API key, add it to your environment with

    export NCBI_API_KEY=unique_api_key

where `unique_api_key` is a unique hexadecimal number with characters from 0-9 and a-f.

You should also set your email address in the
`EMAIL` environment variable as edirect tries to guess it, which is an error prone process.
Add this variable to your environment with

    export EMAIL=my@email.address

using your own email address instead of `my@email.address`.

---

### Installation with `conda`

1. To get started, clone this repo locally:
```bash
git clone https://github.com/lskatz/Kalamari.git
```

2. Next create the Kalamari conda environment, then activate it.
```bash
conda create -n kalamari -c conda-forge -c bioconda kalamari
conda activate kalamari
```

---

### Manual installation

Manual installation is viable but less preferred.

1. Clone this repo locally:
```bash
git clone https://github.com/lskatz/Kalamari.git
```

2. Install dependencies:
   - Perl (5.x)
   - `wget` (or `curl`)
     - Debian/Ubuntu: `apt-get install wget`
   - [NCBI Entrez Direct](https://www.ncbi.nlm.nih.gov/books/NBK179288/) (`edirect`, `esearch`, etc.)
     - Install via your package manager
     - Debian/Ubuntu: `apt install ncbi-entrez-direct`
   - [taxonkit](https://github.com/shenwei356/taxonkit/releases)

---

### Download the databases
This step downloads the reference genome FASTA files for the Kalamari database.
The databases are downloaded using the information contained in `src/chromosomes.tsv` and `src/plasmids.tsv`.
These files represent the chromosome and plasmid databases, respectively.

Navigate to the directory where you cloned the repo. Installation can be done by running either of the following two scripts, 
based on your preferences.
Note that this step takes a while to complete.

**Option 1:** Download both the chromosome and plasmid databases with default settings:
```bash
bash bin/downloadKalamari.sh
```

**Option 2:** Choose which databases are downloaded and better control the process:
```bash
bash bin/downloadKalamari.pl [options] <database_tsv_file>
```
Run `perl bin/downloadKalamari.pl --help` for all options.

The `<database_tsv_file>` options include `src/chromosomes.tsv` and `src/plasmids.tsv`.
Alternatively, you can make a custom `tsv` by combining specific genomes into a file with the same 
header as `src/chromosomes.tsv`.

---

## Build and Filter the Taxonomy Directory
In this step, the script `buildTaxonomy.sh` uses the diffs in Kalamari to enhance the default NCBI taxonomy.
Next, `filterTaxonomy.sh` reduces the taxonomy files to just those found in Kalamari.

Run the following scripts:
```bash
bash bin/buildTaxonomy.sh
bash bin/filterTaxonomy.sh
```

---

## Database formatting instructions

[How to format and query databases](docs/DATABASES.md)


## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md)

## Citation

Katz LS, Griswold T, Lindsey RL, Lauer AC, Im MS, Williams G, Halpin JL, Gómez GA, Kucerova Z, Morrison S, Page A, Den Bakker HC, Carleton HA. 2025. "Kalamari: a representative set of genomes of public health concern." _Microbiol Resour Announc_ 14:e00963-24. <https://doi.org/10.1128/mra.00963-24>
