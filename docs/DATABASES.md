# Database formatting instructions

Some sections are not filled out yet.  Contributions in the form of pull requests are welcome for instructions.

## Init

Start off with a few environmental variables, regardless of your target database.

    # assuming source folder is "Kalamari", where you downloaded all fasta files
    VERSION=3.5  # or whichever version you are building
    CPUS=4       # Define how many threads to use
    SRC=Kalamari # The folder where fasta files were downloaded
    DB=Kalamari_v$VERSION
    
## Different databases

Please follow the Init section before continuing. These instructions assume that you have already downloaded the Kalamari fasta files.

### Kraken with Kalamari (Steamed Kalamari)
    
    mkdir -pv $DB/taxonomy
    cp -rv src/taxonomy_v$VERSION/* $DB/taxonomy
    gunzip -v $DB/taxonomy/*
    find $SRC -name '*.fasta' -exec kraken-build --db $DB --add-to-library {} \;
    kraken-build --db $DB --build --threads $CPUS
    # Optional: reduce the size of the database folder
    kraken-build --db $DB --clean
    du -shc $DB # view final size of database

### Kraken2 with Kalamari (Fried Kalamari)

    mkdir -pv $DB/taxonomy
    cp -rv src/taxonomy_v$VERSION/* $DB/taxonomy
    gunzip -v $DB/taxonomy/*
    find $SRC -name '*.fasta' -exec kraken2-build --db $DB --add-to-library {} \;
    kraken2-build --db $DB --build --threads $CPUS
    # Optional: reduce the size of the database folder
    kraken2-build --db $DB --clean
    du -shc $DB # view final size of database

### ColorID with Kalamari

### Mashed Kalamari

### BLASTed Kalamari

### ANI Kalamari
