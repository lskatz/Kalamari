# Using `downloadKalamari.pl` with a Conda Installation

When Kalamari is installed via Conda, all scripts are placed on your `$PATH`, and the package data directory is installed inside the Conda environment.

If you want both chromosome and plasmid databases, it is easiest to use `downloadKalamari.sh`, which is a wrapper for the perl script `downloadKalamari.pl`.

However, you can run `downloadKalamari.pl` directly if you want more control over the download process such as which database to download (`chromosomes.tsv`, `plasmids.tsv`, or a custom `tsv`) or any of the below options:

```bash
Usage: downloadKalamari.pl [options] spreadsheet.tsv

  --outdir     ''  Output directory of Kalamari database
  --numcpus     1  Number of threads
  --bufferSize 10  Number of genomes downloaded simultaneously per thread
  --tempdir        Directory for temporary files (defaults to TMPDIR)
  --version        Print the version of Kalamari
```

## Database outdir nuances
The `buildKraken1.sh` and `buildKraken2.sh` scripts expect the FASTA files to be located in `${CONDA_PREFIX}/share/kalamari-<version>/kalamari/`. If you intend to utilize `Kraken` with the `Kalamari` database, specify this outdir when running `downloadKalamari.pl`.

To get the full path for `${CONDA_PREFIX}/share/kalamari-<version>/kalamari/`:
1. Activate the kalamari conda environment.
2. Run the following:
```bash
KALAMARI_VER=$(downloadKalamari.pl --version)
echo "${CONDA_PREFIX}/share/kalamari-${KALAMARI_VER}/kalamari/"
```

If you will not be using `Kraken`, you can specify any outdir. If no outdir is specified, `downloadKalamari.pl` will make a `Kalamari` subdirectory in the current working directory and output the files there.

## Database `.tsv` files
The databases are downloaded using the information contained in `chromosomes.tsv` and `plasmids.tsv`.
These files represent the chromosome and plasmid databases, respectively.

With the conda installation, these files are located within `${CONDA_PREFIX}/src/`. To get the full path for either, run:
```bash
echo "${CONDA_PREFIX}/src/chromosomes.tsv"
echo "${CONDA_PREFIX}/src/plasmids.tsv"
```

## Example Usage
For either example, start with conda environment activated and the version variable set:
```bash
conda activate kalamari
KALAMARI_VER=$(downloadKalamari.pl --version)
```

To download only the chromosome database with intention to use `Kraken` later:
```bash
downloadKalamari.pl --outdir "${CONDA_PREFIX}/share/kalamari-${KALAMARI_VER}/kalamari/" "${CONDA_PREFIX}/src/chromosomes.tsv"
```

To download only the plasmid database with no intention to use `Kraken` later and no preference of outdir location:
```bash
downloadKalamari.pl "${CONDA_PREFIX}/src/plasmids.tsv"
```



