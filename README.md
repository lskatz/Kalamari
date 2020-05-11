# Kalamari
A database of completed assemblies for metagenomics-related tasks

[![Creative Commons License v4](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](LICENSE.md)

## Download instructions

For usage, run `perl bin/downloadKalamari.pl --help`

    SRC=Kalamari
    perl bin/downloadKalamari.pl -o $SRC src/Kalamari_v3.5.tsv

### ...with plasmids

    SRC=Kalamari
    perl bin/downloadKalamari.pl -o $SRC src/Kalamari_v3.5.tsv src/development-plasmids.tsv

### taxonomy

The taxonomy files `nodes.dmp` and `names.dmp` are under `src/taxonomy-VER` 
where `VER` is the version of Kalamari.

## Database formatting instructions

[How to format databases](docs/DATABASES.md)

## Database usage

After you create your Kalamari database(s), here is [how to use them](docs/USAGE.md)

## Citation

Please refer to the ASM 2018 poster under docs
