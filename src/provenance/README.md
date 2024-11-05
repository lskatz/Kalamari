# Provanence

Need to get the provanence of each entry per reviewer2

## Convert to INSDC notation

```bash
module load Entrez
cat chromosomes.tsv | tail -n +2 | sed 's/ /_/g' | xargs -L 1 -P 2 bash -c 'insdc=$(esearch -db nuccore -query $1 | elink -target nuccore -name nuccore_nuccore_rsgb | efetch -format acc); if [ ! "$insdc" ]; then insdc="$1.1"; fi; insdc=${insdc%.*}; echo -e "$0\t$insdc\t$2\t$3"' > chromosomes.insdc.tsv
```

## Get the sources

Get sources of chromosomes

```bash
module load Entrez
grep -v taxid chromosomes.insdc.tsv | tail -n +2 | cut -f 2 | xargs -I {} sh -c 'esearch -db nuccore -query "{}" | efetch -format xml | xtract -pattern Bioseq-set -element Textseq-id_accession -block Auth-list_affil -element Affil_std_affil' > ncbi_general.tsv
```

Get the NCTC collection

```bash
esearch -db bioproject -query PRJEB6403 | elink -target assembly | elink -target nuccore | efetch -format acc > nctc3000.acc
```

Get the FDA-ARGOS collection

```bash
esearch -db bioproject -query PRJNA231221 | elink -target assembly | elink -target nuccore | efetch -format acc > fda-argos.acc
```

Get the NCBI reference genomes list: I went to <https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=1&reference_only=true>
and then downloaded the whole list (38603 genomes at the time).
I downloaded as a spreadsheet `ncbi_reference_genomes.txt`
and then converted with dos2unix and changed the extension to tsv.

Then, convert to an accessions list

```bash
cut -f 1 ncbi_reference_genomes.tsv | xargs -P 1 -n 1 bash -c 'esearch -db assembly -query $0 | elink -target nuccore | efetch -format acc' > ncbi.acc
```

Convert the NCBI references into INSDC contigs.
⚠ Took about three days to finish due to all the API calls and created a raw 89M file.
Sort/gzip turned it into 18M.

```bash
tail -n +2 ncbi_reference_genomes.tsv | cut -f 1 | xargs -n 1 -P 1 bash -c 'insdc=$(esearch -db assembly -query $0 | elink -target nuccore -name assembly_nuccore_insdc | efetch -format accn | tr "\n" "\t"); echo -e "$0\t$insdc";' | tee ncbi_ref.acc
sort ncbi_ref.acc | gzip -c9 > ncbi_ref.acc.gz && \
  rm -v ncbi_ref.acc
```

_NOTE_ This command probably would have saved me time if I turned it into a batch query and so I'm jotting it down.

```bash
datasets summary genome accession GCF_000006945.2 --report sequence --as-json-lines | dataformat tsv genome-seq --fields genbank-seq-acc
```

Check the assemblies spreadsheet on whether or not it is retrospecitively part of NCBI references

```bash
zcat assembly_summary_genbank.txt.gz | perl -F'\t' -lane 'print if($F[11] eq "Complete Genome" || $.==1);' > tmp.tsv
mv tmp.tsv assembly-complete.tsv
bash quick-ncbi-ref-check.sh Caulobacter vibrioides CP001340
# If found, add to ncbi_ref.acc.more
# If not found, see if there is different reference to add
```

## Translate

Translate certain entries into CDC, NCTC3000, FDA, or the NCBI list.
Make a sources field.

Add a sources field to the chromosomes.tsv from entrez search.

```bash
cat chromosomes.tsv | perl provenance.pl > sources.tsv
# or also to keep track of unknowns
cat chromosomes.insdc.tsv | perl provenance.pl | tee sources.tsv | grep UNKNOWN > unknown.tsv
```
