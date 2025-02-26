# HybridGenomeMaker

A bash script to merge exogenous sequences (e.g., transgenes, synthetic constructs) with a reference genome, generating standardized FASTA and GTF files for downstream analysis.

---

## Features
- Automatically downloads the latest reference genome/annotation from **Ensembl** (or uses users files).
- Supports both **FASTA** and **tab-delimited** input formats for exogenous sequences.
- Generates compliant GTF annotations for exogenous sequences.
- Outputs ready-to-use compressed (gzip) genome files.

---

## Prerequisites
- `bash` (tested on v4.4+)
- Common CLI tools: `wget`, `gunzip`, `awk`
- UNIX-like environment (Linux/macOS/WSL)

---

## Installation
```bash
git clone https://github.com/yourusername/hybrid-genome-maker.git
cd hybrid-genome-maker
chmod +x HybridGenomeMaker.sh
```
## Usage
### Basic Command

```bash
./HybridGenomeMaker.sh \
  -sequence_file <EXOGENOUS_SEQUENCE_FILE> \
  -speciesName "SPECIES_NAME" \
  -outDir <OUTPUT_DIRECTORY>
```
### Options 

| Parameter | Description |
| ----------- | ----------- |
| -sequence_file | Path to exogenous sequence file (FASTA or tab-delimited; **required**) |
| -speciesName | Species name (e.g., "Gallus_gallus"; **required**) | 
| -outDir | Output directory (**required**) | 
| -fasta | User reference FASTA file (Optional | 
| -gtf | User reference GTF file (Optional) | 


## Exogenous sequence Input File Formats

### Tab-Delimited Format

```
GFP    ATGGTGAGCAAGGGCGAGGAGCTGTTCACCGGGGTGGTGCCCATCCTGGTCGAGCTGGACGGCGACGTAAACGGCCACAAGTTCAGCGTGTCCGGCGAGGGCGAGGGCGATGCCACCTACGGCAAGCTGACCCTGAAGTTCATCTGCACCACCGGCAAGCTGCCCGTGCCCTGGCCCACCCTCGTGACCACCCTGACCTACGGCGTGCAGTGCTTCAGCCGCTACCCCGACCACATGAAGCAGCACGACTTCTTCAAGTCCGCCATGCCCGAAGGCTACGTCCAGGAGCGCACCATCTTCTTCAAGGACGACGGCAACTACAAGACCCGCGCCGAGGTGAAGTTCGAGGGCGACACCCTGGTGAACCGCATCGAGCTGAAGGGCATCGACTTCAAGGAGGACGGCAACATCCTGGGGCACAAGCTGGAGTACAACTACAACAGCCACAACGTCTATATCATGGCCGACAAGCAGAAGAACGGCATCAAGGTGAACTTCAAGATCCGCCACAACATCGAGGACGGCAGCGTGCAGCTCGCCGACCACTACCAGCAGAACACCCCCATCGGCGACGGCCCCGTGCTGCTGCCCGACAACCACTACCTGAGCACCCAGTCCGCCCTGAGCAAAGACCCCAACGAGAAGCGCGATCACATGGTCCTGCTGGAGTTCGTGACCGCCGCCGGGATCACTCTCGGCATGGACGAGCTGTACAAG
```

### FASTA Format

```
>GFP
ATGGTGAGCAAGGGCGAGGAGCTGTTCACCGGGGTGGTGCCCATCCTGGTCGAGCTGGACGGCGACGTAAACGGCCACAAGTTCAGCGTGTCCGGCGAGGGCGAGGGCGATGCCACCTACGGCAAGCTGACCCTGAAGTTCATCTGCACCACCGGCAAGCTGCCCGTGCCCTGGCCCACCCTCGTGACCACCCTGACCTACGGCGTGCAGTGCTTCAGCCGCTACCCCGACCACATGAAGCAGCACGACTTCTTCAAGTCCGCCATGCCCGAAGGCTACGTCCAGGAGCGCACCATCTTCTTCAAGGACGACGGCAACTACAAGACCCGCGCCGAGGTGAAGTTCGAGGGCGACACCCTGGTGAACCGCATCGAGCTGAAGGGCATCGACTTCAAGGAGGACGGCAACATCCTGGGGCACAAGCTGGAGTACAACTACAACAGCCACAACGTCTATATCATGGCCGACAAGCAGAAGAACGGCATCAAGGTGAACTTCAAGATCCGCCACAACATCGAGGACGGCAGCGTGCAGCTCGCCGACCACTACCAGCAGAACACCCCCATCGGCGACGGCCCCGTGCTGCTGCCCGACAACCACTACCTGAGCACCCAGTCCGCCCTGAGCAAAGACCCCAACGAGAAGCGCGATCACATGGTCCTGCTGGAGTTCGTGACCGCCGCCGGGATCACTCTCGGCATGGACGAGCTGTACAAG
```
## Example

### Example 1: Using Ensembl References

```
./HybridGenomeMaker.sh \
  -sequence_file my_sequence.txt \
  -speciesName "Gallus_gallus" \
  -outDir /path/to/results

```
### Example 2: User provided Genome/Annotation
```
./HybridGenomeMaker.sh \
  -sequence_file construct.fa \
  -speciesName "Xenopus_laevis" \
  -outDir /data/hybrid_genomes \
  -fasta /path/to/custom_genome.fa.gz \
  -gtf /path/to/custom_annotation.gtf.gz
```

## Output Structure

```
output_directory/
└── SPECIES_NAME/
    └── custom/
        ├── SPECIES_NAME.genome_sequence.fa.gz       # Merged FASTA
        └── SPECIES_NAME.annotation.gtf.gz           # Merged GTF
```

## Important Notes
1. Species Name Format: Use underscores instead of spaces (e.g., Homo_sapiens).
2. Ensembl Fallback: If primary assembly is unavailable, the script automatically downloads the toplevel genome.
3. GTF Biotype: Exogenous sequences are annotated as protein_coding by default (modify script if needed).


## Troubleshooting
### Common Issues 

* Species name must contain only letters or underscores:
Ensure no special characters or spaces in -speciesName.
* Input file not found:
Use absolute paths for input files (e.g., /home/user/data/sequence.txt).
* GTF validation errors:
Ensure custom GTF files follow ENSEMBL GTF format.

## Credits

Developed by Maxime Lepetit.
If using Ensembl references, please cite their publication.

License: 










