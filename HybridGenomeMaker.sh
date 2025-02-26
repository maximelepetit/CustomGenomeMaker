#!/bin/bash



set -e  # Exit immediately if a command exits with a non-zero status.

####
# Script to create FASTA and GTF files for an exogenous sequence,
# and merge it with a reference genome (downloaded the latest release from Ensembl or provided by the user).
####

# Function to display script usage
usage() {
    echo "$(date) usage: sh $0 -sequence_file -speciesName -outDir [-fasta -gtf]"
    echo "    -sequence_file : Path to the exogenous sequence file (FASTA or tab-delimited text)"
    echo "    -speciesName : Name of the species (e.g., 'Gallus_gallus')"
    echo "    -outDir : Output directory for storing results"
    echo "    -fasta : (Optional) Path to a custom reference FASTA file"
    echo "    -gtf : (Optional) Path to a custom reference GTF file"
    exit 1
}



# Function to transform and capitalize species name
transform_and_capitalize() {
    echo "${1// /_}" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2));}print}'
}

# Parse command line options
if [[ $# -lt 6 || $# -gt 10 ]]; then
    usage
fi

while [[ -n "$1" ]]; do
    case "$1" in
        -sequence_file) sequence_file="$2"; shift ;;
        -speciesName) speciesName="$2"; shift ;;
        -outDir) outDir="$2"; shift ;;
        -fasta) customFasta="$2"; shift ;;
        -gtf) customgtf="$2"; shift ;;
        *) echo "$(date) Unknown option: $1"; usage ;;
    esac
    shift
done

# Transform and validate species name
if [[ -n "${speciesName}" ]]; then
    if [[ ! "${speciesName}" =~ ^[a-zA-Z_[:space:]]+$ ]]; then
        echo "❌ Error: Species name must contain only letters or underscores."
        exit 1
    else
        speciesName=$(transform_and_capitalize "${speciesName}")
        echo "✅ Species: ${speciesName}"
    fi
fi






# Validate input sequence file
if [ ! -f "$sequence_file" ]; then
    echo "❌ Error: Input file '$sequence_file' not found."
    exit 1
fi

# Set output directory
output_directory="$outDir/${speciesName}"

# Ensure output directory exists
if [[ -d "$output_directory/custom" || -d "$output_directory/tmp" ]]; then
    rm -rf "$output_directory/custom" "$output_directory/tmp"
    mkdir -p "$output_directory/custom" "$output_directory/tmp/fasta" "$output_directory/tmp/gtf"
    echo "✅ Output directory set to: $output_directory"
else 

    mkdir -p "$output_directory/custom" "$output_directory/tmp/fasta" "$output_directory/tmp/gtf"
    echo "✅ Output directory set to: $output_directory"
fi


# Définir les fichiers de sortie
fasta_tmp_sequence="${output_directory}/tmp/fasta/sequence.fasta"
gtf_tmp_sequence="${output_directory}/tmp/gtf/sequence.gtf"


echo "🔹 Detecting file format..."
extension="${sequence_file##*.}"
if [[ "$extension" =~ ^(fa|fasta)$ ]]; then
    echo "📌 FASTA format detected."
    format="fasta"
elif [[ "$extension" =~ ^(txt|tab)$ ]]; then
    echo "📌 Tab-delimited format detected."
    format="tab"

else
    echo "❌ Error: Unsupported file format: .$extension"
    usage

fi


# Determine FASTA and GTF files based on custom or Ensembl download if provided
if [[ -n "$customFasta" && -n "$customGtf" ]]; then
    fasta="$customFasta"
    gtf="$customGtf"
else
    echo "$(date) - Trying to download files from Ensembl..."
    ensembl_species="${speciesName,,}"

    # Download FASTA file
    request_fasta_fd="ftp://ftp.ensembl.org/pub/current_fasta/${ensembl_species}/dna/"
    genome_filename="*.dna.primary_assembly.fa.gz"

    wget -r -np -nd -q -P "$output_directory/tmp/fasta" -A "$genome_filename" "$request_fasta_fd" || {
        echo "$(date) - Primary assembly file not found. Trying to download toplevel file..."
        genome_filename="*.dna.toplevel.fa.gz"
        wget -r -np -nd -q -P "$output_directory/tmp/fasta" -A "$genome_filename" "$request_fasta_fd" || {
            echo "$(date) - Failed to download DNA file from Ensembl."
            exit 1
        }
    }
    fasta=$(find "$output_directory/tmp/fasta" -name "$genome_filename" | head -n 1)

    # Download GTF file
    echo "$(date) - Trying to download GTF file from Ensembl..."
    gtf_filename="*[0-9].gtf.gz"
    request_gtf_fd="ftp://ftp.ensembl.org/pub/current_gtf/${ensembl_species}/"
    wget -r -np -nd -q -P "$output_directory/tmp/gtf" -A "${gtf_filename}" "$request_gtf_fd" || {
        echo "$(date) - Failed to download GTF file from Ensembl."
        exit 1
    }
    gtf=$(find "$output_directory/tmp/gtf" -name "$gtf_filename" | head -n 1)
fi




# Process input sequence file
echo "🔹 Processing input sequence file..."
if [ "$format" == "tab" ]; then
    while IFS=$'\t' read -r sequence_name sequence; do
        if [[ -z "$sequence_name" || -z "$sequence" ]]; then
            echo "⚠️ Skipping invalid line."
            continue
        fi

        echo ">$sequence_name" >> "$fasta_tmp_sequence"
        echo "$sequence" >> "$fasta_tmp_sequence"

        length=${#sequence}


        echo -e "$sequence_name\tunknown\tgene\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\ttranscript\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\texon\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"

        echo "✅ Adding sequence $sequence_name."
    done < "$sequence_file"
else

    > "$fasta_tmp_sequence"  
    > "$gtf_tmp_sequence"  

    sequence_name=""
    sequence=""

    while IFS= read -r line; do

        if [[ ${line} == ">"* ]]; then
           if [[ -n "$sequence_name" ]]; then
            echo ">$sequence_name" >> "$fasta_tmp_sequence"
            echo "$sequence" >> "$fasta_tmp_sequence"

            length=${#sequence}
            echo -e "$sequence_name\tunknown\tgene\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
            echo -e "$sequence_name\tunknown\ttranscript\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
            echo -e "$sequence_name\tunknown\texon\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        fi
        sequence_name=$(echo "$line" | cut -d ' ' -f 1 | sed 's/>//')
        sequence=""
        else
            sequence+=$(echo "$line" | tr -d '\n')
        fi
    done < "$sequence_file"

    if [[ -n "$sequence_name" ]]; then
        echo ">$sequence_name" >> "$fasta_tmp_sequence"
        echo "$sequence" >> "$fasta_tmp_sequence"

        length=${#sequence}

        echo -e "$sequence_name\tunknown\tgene\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\ttranscript\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\texon\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
    fi
fi

echo "🎉 FASTA and GTF files for the custom sequence successfully generated."


# Move and concatenate generated files to custom directory
if [[ -n "$fasta" ]]; then
    if [[ "$fasta" == *.gz ]]; then
        cp "$fasta" "$output_directory/custom/$(basename "$fasta" .fa.gz)_$(basename "$sequence_file" .txt).fa.gz"
        gunzip -f "$output_directory/custom/$(basename "$fasta" .fa.gz)_$(basename "$sequence_file" .txt).fa"
    else
        cp "$fasta" "$output_directory/custom/${speciesName}_$(basename "$sequence_file" .txt).fa"
    fi
    cat "$fasta_tmp_sequence" >> "$output_directory/custom/$(basename "$fasta" .fa.gz)_$(basename "$sequence_file" .txt).fa"
    gzip "$output_directory/custom/$(basename "$fasta" .fa.gz)_$(basename "$sequence_file" .txt).fa"
fi

if [[ -n "$gtf" ]]; then
    if [[ "$gtf" == *.gz ]]; then
        cp "$gtf" "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf.gz"
        gunzip -f "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf.gz"
    else
        cp "$gtf" "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf"
    fi
    cat "$gtf_tmp_sequence" >> "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf"
    gzip "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf"
fi

# Clean up temporary directory
rm -rf "$output_directory/tmp"

echo "🧹 Temporary files removed."

echo "🎉 Process completed! Output files stored in: $output_directory/custom"