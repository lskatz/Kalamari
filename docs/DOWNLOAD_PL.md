# Using `downloadKalamari.pl` Directly for Database Download

If you want both chromosome and plasmid databases, it is easiest to use `downloadKalamari.sh`, which is a wrapper for the Perl script `downloadKalamari.pl`. 

However, you can run `downloadKalamari.pl` directly if you want more control over the download process such as selecting which database to download (`chromosomes.tsv`, `plasmids.tsv`, or a custom `tsv`) or adjusting any of the following options:

```bash
Usage: downloadKalamari.pl [options] spreadsheet.tsv

  --outdir     ''  Output directory of Kalamari database
  --numcpus     1  Number of threads
  --bufferSize 10  Number of genomes downloaded simultaneously per thread
  --tempdir        Directory for temporary files (defaults to TMPDIR)
  --version        Print the version of Kalamari
```

If you do not plan to use the Kraken build scripts, you may specify any outdir. If no outdir is specified, `downloadKalamari.pl` will make a `Kalamari` subdirectory in the current working directory and output the files there.

## For Users Intending to Run Kraken
Some care needs to be taken when using the `downloadKalamari.pl` script if Kraken will be used downstream.

For best results, setting the outdir parameter to the location expected by the `buildKraken1.sh` and `buildKraken2.sh` scripts is necessary.

This is because:
- the `buildKraken1.sh` and `buildKraken2.sh` scripts expect the FASTA files to be located in a specific location, and
- the default outdir of `downloadKalamari.pl` is a `Kalamari/` subdirectory within the current working directory.

See the following instructions for users of either [Conda Installation](#running-with-a-conda-installation) or [Manual Installation](#running-with-a-manual-installation).

## Running with a Conda Installation

When Kalamari is installed via Conda, all scripts are placed on your `$PATH`, and the package data directory is installed inside the Conda environment.

The `buildKraken1.sh` and `buildKraken2.sh` scripts expect the FASTA files to be located in `${CONDA_PREFIX}/share/kalamari-<version>/kalamari/`. If you intend to utilize Kraken with the Kalamari database, specify this outdir when running `downloadKalamari.pl`.

To get the full path for `${CONDA_PREFIX}/share/kalamari-<version>/kalamari/`:
1. Activate the kalamari conda environment.
2. Run the following:
```bash
KALAMARI_VER=$(downloadKalamari.pl --version)
echo "${CONDA_PREFIX}/share/kalamari-${KALAMARI_VER}/kalamari/"
```

### Database `.tsv` files
The databases are downloaded using the information contained in `chromosomes.tsv` and `plasmids.tsv`.
These files represent the chromosome and plasmid databases, respectively.

With the conda installation, these files are located within `${CONDA_PREFIX}/src/`. To get the full path for either, run:
```bash
echo "${CONDA_PREFIX}/src/chromosomes.tsv"
echo "${CONDA_PREFIX}/src/plasmids.tsv"
```

### Example Usages
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

## Running with a Manual Installation

With manual installation, Kalamari packages files are located in the cloned local git repo.

The `buildKraken1.sh` and `buildKraken2.sh` scripts expect the FASTA files to be located in `<kalamari_cloned_repo>/share/kalamari-<version>/kalamari/`. If you intend to utilize Kraken with the Kalamari database, specify this outdir when running `downloadKalamari.pl`.

To get the `<version>` for the full path, run:
```bash
downloadKalamari.pl --version
```

### Database `.tsv` files
The databases are downloaded using the information contained in `<kalamari_cloned_repo>/src/chromosomes.tsv` and `<kalamari_cloned_repo>/src/plasmids.tsv`.
These files represent the chromosome and plasmid databases, respectively.

### Example Usages
To download only the chromosome database with intention to use `Kraken` later:
```bash
downloadKalamari.pl --outdir "path/to/<kalamari_cloned_repo>/share/kalamari-<version>/kalamari/" "path/to/<kalamari_cloned_repo>/src/chromosomes.tsv"
```

To download only the plasmid database with no intention to use `Kraken` later and no preference of outdir location:
```bash
downloadKalamari.pl "path/to/<kalamari_cloned_repo>/src/plasmids.tsv"
```


