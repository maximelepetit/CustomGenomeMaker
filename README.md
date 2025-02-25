# HybridGenomeMaker
This script generates a FASTA and GTF file for an exogenous nucleotide sequence (not present in the reference genome). Then, it integrates this sequence into the reference FASTA and GTF files of a specified organism.

Workflow:
1️⃣ Convert the exogenous sequence (provided in FASTA or tab-delimited text format) into a FASTA and GTF file.
2️⃣ Merge the exogenous sequence with the reference genome:

    If the user provides reference FASTA and GTF files, they are used.
    Otherwise, the script downloads the reference genome from Ensembl based on the specified species.

Inputs:

    -sequence_file: Path to the exogenous sequence file (FASTA or tab-delimited text).
    -speciesName: Target species name (e.g., Gallus gallus).
    -outDir: Output directory for storing results.
    -fasta (optional): Path to a custom reference FASTA file (if provided, no download needed).
    -gtf (optional): Path to a custom reference GTF file (if provided, no download needed).

Outputs:

    A FASTA and GTF file for the exogenous sequence.
    A merged FASTA and GTF file containing both the reference genome and the exogenous sequence.
