# Contributing

There are many ways to contribute to this project and so here are a couple of ways to contribute.
Contributions will almost always result in a pull request.
Contributions must pass the automated testing.

**Note for Contributors:** GitHub Actions workflows on pull requests from first-time contributors require manual approval from repository maintainers before they can run. This is a security feature. Your workflows will show as "Awaiting approval" until a maintainer reviews and approves them. See [docs/CI_APPROVAL_ISSUE.md](docs/CI_APPROVAL_ISSUE.md) for more details.

## Add a taxon

To add a taxon, add it to src/nodes.dmp and src/names.dmp.
If it is present in the NCBI taxonomy, please use that identifier.
Please adhere to the [NCBI taxonomy format specification](https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump_readme.txt).
For names.dmp, the scientific name field is required.

Step 2 for adding a taxon is also adding representative chromosome(s).
See the section below for details.
You cannot add a taxon to this project without a representative chromosome.

## Add a chromosome

Add an entry to either src/chromosomes.tsv or src/plasmids.tsv.
The format is four columns, separated by tab:

* scientific name or similar
* NCBI nucleotide accession
* taxonomy ID
* parent taxonomy ID

The taxonomy IDs in each line must be represented in names.dmp and nodes.dmp in the folder src/taxonomy.

New nucleotide entries must be

* Trusted - subject matter experts must agree that this is a representative genome for the taxon
* Completed - no gaps
* Nonredundant - for the most part, most taxa are not represented by multiple assemblies

Note: some species such as _Vibrio cholerae_ have multiple chromosomes.
These can be denoted with multiple lines, one per nucleotide accession.

## Other contributions

Please make a new issues ticket on GitHub and describe the potential contribution.

