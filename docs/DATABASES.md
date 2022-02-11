# Database formatting instructions

Some sections are not filled out yet.  Contributions in the form of pull requests are welcome for instructions.

## Init

Start off with a few environmental variables, regardless of your target database.
If you have not already downloaded the Kalamari fasta files, please see the main [README](../README.md) file.

    # assuming source folder is "Kalamari", where you downloaded all fasta files
    VERSION=5.0  # or whichever version you are building
    CPUS=4       # Define how many threads to use
    SRC=Kalamari # The folder where fasta files were downloaded
    FASTA=$(find $SRC -name '*.fasta' | head -n 1) # input fasta file for querying
    
    # Make a fake fastq file
    FASTQ="$FASTA.fastq.gz"
    head -n 2 $FASTA | perl -e '$id=<>; $seq=<>; chomp($id, $seq); $qual="I" x length($seq); $id=~s/^>/@/; print "$id\n$seq\n+\n$qual\n";' | gzip -c > $FASTQ
   
## Different databases

Please follow the Init section before continuing. These instructions assume that you have already downloaded the Kalamari fasta files.

### Kraken with Kalamari (Steamed Kalamari)

#### Build

    DB=kraken1.kalamari_$VERSION

    mkdir -pv $DB
    cp -rv src/taxonomy $DB/taxonomy
    find $SRC -name '*.fasta' -exec kraken-build --db $DB --add-to-library {} \;
    kraken-build --db $DB --build --threads $CPUS
    # Optional: reduce the size of the database folder
    kraken-build --db $DB --clean
    du -shc $DB # view final size of database

#### Query

    # fasta input
    kraken --db kraken -output kraken.raw --fasta-input $FASTA
    # fastq input
    kraken --db kraken -output kraken.raw --fastq-input $FASTQ --gzip-compressed

### Kraken2 with Kalamari (Fried Kalamari)

#### Build

    DB=kraken2.kalamari_$VERSION

    mkdir -pv $DB
    cp -rv src/taxonomy $DB/taxonomy
    find $SRC -name '*.fasta' -exec kraken2-build --db $DB --add-to-library {} \;
    kraken2-build --db $DB --build --threads $CPUS
    # Optional: reduce the size of the database folder
    kraken2-build --db $DB --clean
    du -shc $DB # view final size of database

#### Query

    # Same command for either fasta or fastq
    kraken2 --db $DB --report kraken2.report --use-mpa-style --output kraken2.raw $FASTA
    kraken2 --db $DB --report kraken2.report --use-mpa-style --output kraken2.raw $FASTQ
    
### Sepia Kalamari

#### Build

    DB=kalamari_$VERSION.sepia
    # Create the Sepia references file with two columns: path, taxonomy
    python3 bin/generate_sepia_reference.py --taxonomy src/taxonomy -o sepia.ref.tsv --fastadir ./Kalamari src/chromosomes.tsv src/plasmids.tsv
    sepia build --index $DB --refs sepia.ref.tsv --kmer 41 --minimizer 31 --batch 300 --gamma 5.0 --threads $CPUS 
    ls -lhS $DB # view a directory representing the database    
    
#### Query

    sepia classify --index $DB --prefix test_kalamari --query $FASTQ
    # View the summary:
    # First column is the classification, second read count and third average kmer similarity
    sort -k2,2nr test_kalamari_summary.txt | head -n 20 | column -t

    # View taxonomic classification results per read
    zcat test_kalamari_classification.gz | head

### ColorID with Kalamari

### Mashed Kalamari

Using Mash version 2

    DB=Kalamari.msh

    find $SRC -name '*.fasta' -exec mash sketch {} \;
    find $SRC -name '*.msh' > $DB.fofn
    mash paste $DB -l $DB.fofn

### BLASTed Kalamari

#### Build

    DB=Kalamari.blast
    mkdir $DB

    find $SRC -name '*.fasta' -exec cat {} \; > $DB/kalamari.fasta
    makeblastdb -dbtype nucl -in $DB

#### Query

    blastn -query $FASTA -db Kalamari.blast/kalamari.fasta

### ANI Kalamari

#### Build

    # Can use the same folder; just add file of filename
    DB=$SRC/reference.fofn
    find $SRC -name '*.fasta' > $DB

#### Query

    fastANI --rl $DB -q $FASTA /dev/stdout

### mm Kalamari (mmSeqs2)

#### Build

    DB=$SRC.mmseqs2
    Kalamari]$ find $SRC -name '*.fasta' | xargs -n 100 gzip -c > $SRC.cat.gz
    mmseqs createdb Kalamari.cat.gz $DB

#### Query

    # need to create database out of your query fasta file
    mmseqs createdb $FASTA $FASTA.mmseqs2
    # The actual query:
    mmseqs search --threads 4 $FASTA.mmseqs2 $DB mmseqs2.out mmseqs2.tmp

