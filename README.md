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
- `bash` (tested on v5.0.17)
- Common CLI tools: `wget`, `gunzip`, `awk`
- UNIX-like environment (Linux/macOS/WSL)

---

## Installation
```bash
git clone https://github.com/maximelepetit/HybridGenomeMaker.git
cd HybridGenomeMaker
chmod +x HybridGenomeMaker.sh
```

---

## Usage
### Basic Command

```bash
./HybridGenomeMaker.sh \
  -sequence_file <EXOGENOUS_SEQUENCE_FILE> \
  -speciesName <SPECIES_NAME> \
  -outDir <OUTPUT_DIRECTORY>
```
### Options 

| Parameter | Description |
| ----------- | ----------- |
| -sequence_file | Path to exogenous sequence file (FASTA or tab-delimited; **required**) |
| -speciesName | Species name (e.g., "Gallus_gallus"; **required**) | 
| -outDir | Output directory (**required**) | 
| -fasta | Path to user reference FASTA file (Optional) | 
| -gtf | Path to user reference GTF file (Optional) | 

---


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

---


## Example

### Example 1: Use the automatic download of Ensembl references
```
./HybridGenomeMaker.sh \
  -sequence_file "path/to/my_sequence.txt" \
  -speciesName "Gallus_gallus" \
  -outDir "/path/to/results"

```
### Example 2: User provided Genome/Annotation
```
./HybridGenomeMaker.sh \
  -sequence_file "path/to/my_sequence.fa" \
  -speciesName "Xenopus_laevis" \
  -outDir "/path/to/results" \
  -fasta "/path/to/user_genome.fa.gz" \
  -gtf "/path/to/user_annotation.gtf.gz"
```
---
## Output Structure

```
output_directory/
└── SPECIES_NAME/
    └── custom/
        ├── SPECIES_NAME_my_sequence.fa.gz       # Merged FASTA
        └── SPECIES_NAME_my_sequence.gtf.gz           # Merged GTF
```
It's highly recommend to check outputs FASTA and GTF files.

```
tail <(zcat /path/to/SPECIES_NAME_my_sequence.gtf.gz )
tail -n 50 <(zcat /path/to/SPECIES_NAME_my_sequence.fa.gz  )

```
---
## Important Notes
1. Species Name Format: Use underscores instead of spaces (e.g., Homo_sapiens).
2. Ensembl Fallback: If primary assembly is unavailable, the script automatically downloads the toplevel genome.
3. GTF Biotype: Exogenous sequences are annotated as protein_coding by default (modify script if needed).
   
---

## Troubleshooting
### Common Issues 
* If sequence_file is FASTA file, need to be .fa format (not gzipped).
* If users provides their own FASTA files and GTF files, they need to be gzipped 
* Species name must contain only letters or underscores:
Ensure no special characters or spaces in -speciesName.
* Input file not found:
Use absolute paths for input files (e.g., /home/user/data/sequence.txt).
* GTF validation errors:
Ensure custom GTF files follow ENSEMBL GTF format.

---

## Credits

Developed by Maxime Lepetit.

License: GPL-3.0










