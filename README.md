# Kalamari
A database of completed assemblies for metagenomics-related tasks

[![Creative Commons License v4](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](LICENSE.md)

## Download instructions

For usage, run `perl bin/downloadKalamari.pl --help`

    SRC=Kalamari
    perl bin/downloadKalamari.pl -o $SRC src/Kalamari_v3.5.tsv

## Database formatting instructions

Some sections are not filled out yet.  Contributions in the form of pull requests are welcome for instructions.

### Kraken with Kalamari

    # assume source folder is "Kalamari"
    VERSION=3.5 # or whichever version you are building
    DB=Kalamari_v$VERSION
    SRC=Kalamari
    
    mkdir -pv $DB/taxonomy
    cp -rv src/taxonomy_v$VERSION/* $DB/taxonomy
    gunzip -v $DB/taxonomy/*
    find $SRC -name '*.fasta' -exec kraken-build --db $DB --add-to-library {} \;
    kraken-build --db $DB --build --threads 4

### Kraken2 with Kalamari

### ColorID with Kalamari

### Mashed Kalamari

### BLASTed Kalamari

### ANI Kalamari
