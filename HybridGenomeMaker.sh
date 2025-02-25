#!/bin/bash


set -e  # Arrête le script en cas d'erreur
set -u  # Empêche l'utilisation de variables non définies


####
# Script2
###
# Goals: Create FASTA and GTF files from a text file containing a nucleotide sequence and optionally use custom or downloaded files.
#
# Inputs:
# - -sequence_file: Full path to the sequence file.
# - -fasta: (Optional) Path to a custom .fa file or downloaded from Ensembl.
# - -gtf: (Optional) Path to a custom .gtf file or downloaded from Ensembl.
# - -speciesName: Species name (e.g., "Gallus_gallus").
# - -outDir: Directory where output will be created.
#
# Output:
# - GTF and FASTA files of the nucleotide sequence created in the specified output directory.
###




usage() {
    echo "$(date) usage: sh $0 -sequence_file -speciesName -outDir [-fasta -gtf]
    -sequence_file :  Full path to the sequence file 
    -fasta : (Optional) path to custom .fa file
    -gtf : (Optional) path to custom .gtf file
    -speciesName : Specie Name
    -outDir : Directory where reference will be created
    "
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
        -fasta) customFasta="$2"; shift ;;
        -gtf) customGtf="$2"; shift ;;
        -speciesName) speciesName="$2"; shift ;;
        -outDir) outDir="$2"; shift ;;
        *) echo "$(date) Unknown option: $1"; usage ;;
    esac
    shift
done

# Transform and validate species name
if [[ -n "${speciesName}" ]]; then
    if [[ ! "${speciesName}" =~ ^[a-zA-Z_[:space:]]+$ ]]; then
        echo "$(date) - Species name must contain only letters or underscores (Mus musculus, mus musculus, mus_musculus)"
        exit 1
    else
        speciesName=$(transform_and_capitalize "${speciesName}")
        echo "$(date) - Species: ${speciesName}"
    fi
fi

# Set output directory
output_directory="$outDir/${speciesName}"




# Vérifier si le fichier d'entrée existe
if [ ! -f "$sequence_file" ]; then
    echo "Erreur : le fichier d'entrée '$sequence_file' est introuvable."
    exit 1
fi


# Ensure output directory exists
if [[ -d "$output_directory/custom" || -d "$output_directory/tmp" ]]; then
    rm -rf "$output_directory/custom" "$output_directory/tmp"
    mkdir -p "$output_directory/custom" "$output_directory/tmp/fasta" "$output_directory/tmp/gtf"
else 


    echo "Output directory '$output_directory/' does not exist. Creating it."
    mkdir -p "$output_directory/custom" "$output_directory/tmp/fasta" "$output_directory/tmp/gtf"
fi


# Définir les fichiers de sortie
fasta_tmp_sequence="${output_directory}/tmp/fasta/sequence.fasta"
gtf_tmp_sequence="${output_directory}/tmp/gtf/sequence.gtf"


# Détection du format du fichier (tabulé ou FASTA)
extension="${sequence_file##*.}"
if [[ "$extension" =~ ^(fa|fasta)$ ]]; then
    echo "📌 Extension .$extension détectée : FASTA"
    format="fasta"
elif [[ "$extension" =~ ^(txt|tab)$ ]]; then
    echo "📌 Extension .$extension détectée : tabulé"
    format="tab"

else
    echo "Mauvais format détecté: .$extension"
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




# Traitement du fichier d'entrée
if [ "$format" == "tab" ]; then
    while IFS=$'\t' read -r sequence_name sequence; do
        # Vérifier que la ligne contient bien une séquence valide
        if [[ -z "$sequence_name" || -z "$sequence" ]]; then
            echo "⚠️ Ligne invalide détectée, elle sera ignorée."
            continue
        fi
        # Ajouter la séquence au fichier FASTA
        echo ">$sequence_name" >> "$fasta_tmp_sequence"
        echo "$sequence" >> "$fasta_tmp_sequence"

        # Calculer la longueur de la séquence
        length=${#sequence}

        # Ajouter l'annotation dans le fichier GTF
        echo -e "$sequence_name\tunknown\tgene\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\ttranscript\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\texon\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"

        echo "✅ Séquence $sequence_name ajoutée."
    done < "$sequence_file"
else

# Initialisation des fichiers de sortie
    > "$fasta_tmp_sequence"  # Crée un fichier vide
    > "$gtf_tmp_sequence"  # Crée un fichier vide

    sequence_name=""
    sequence=""

    while IFS= read -r line; do

        if [[ ${line} == ">"* ]]; then
            # Si une séquence précédente existe, l'ajouter
           if [[ -n "$sequence_name" ]]; then
            # Ajout de la séquence au fichier .fa
            echo ">$sequence_name" >> "$fasta_tmp_sequence"
            echo "$sequence" >> "$fasta_tmp_sequence"

            # Création des annotations GTF
            length=${#sequence}
            echo -e "$sequence_name\tunknown\tgene\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
            echo -e "$sequence_name\tunknown\ttranscript\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
            echo -e "$sequence_name\tunknown\texon\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        fi
        # Récupérer le nom de la nouvelle séquence (en retirant le '>' et tout ce qui suit l'espace)
        sequence_name=$(echo "$line" | cut -d ' ' -f 1 | sed 's/>//')
        sequence=""
        else
        # Ajouter la ligne à la séquence en cours (en supprimant les éventuels retours à la ligne)
            sequence+=$(echo "$line" | tr -d '\n')
        fi
    done < "$sequence_file"

    # Ajouter la dernière séquence
   # Traitement de la dernière séquence
    if [[ -n "$sequence_name" ]]; then
        # Ajout de la séquence au fichier .fa
        echo ">$sequence_name" >> "$fasta_tmp_sequence"
        echo "$sequence" >> "$fasta_tmp_sequence"

        # Création des annotations GTF
        length=${#sequence}

        echo -e "$sequence_name\tunknown\tgene\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\ttranscript\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
        echo -e "$sequence_name\tunknown\texon\t1\t$length\t.\t+\t.\tgene_id \"$sequence_name\"; transcript_id \"$sequence_name\"; gene_name \"$sequence_name\"; gene_biotype \"protein_coding\";" >> "$gtf_tmp_sequence"
    fi
fi

echo "🎉 FASTA and GTF files for the custom sequence successfully generated."


echo "🎉 FASTA and GTF files for the custom sequence successfully generated."

# Move and concatenate generated files to custom directory
if [[ -n "$fasta" ]]; then
    if [[ "$fasta" == *.gz ]]; then
        cp "$fasta" "$output_directory/custom/$(basename "$fasta" .fa.gz)_$(basename "$sequence_file" .txt).fa.gz"

        gunzip -f "$output_directory/custom/${speciesName}_$(basename "$sequence_file" .txt).fa.gz"
    else
        cp "$fasta" "$output_directory/custom/${speciesName}_$(basename "$sequence_file" .txt).fa"
    fi
    cat "$fasta_tmp_sequence" >> "$output_directory/custom/${speciesName}_$(basename "$sequence_file" .txt).fa"
fi

if [[ -n "$gtf" ]]; then
    if [[ "$gtf" == *.gz ]]; then
        cp "$gtf" "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf.gz"
        gunzip -f "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf.gz"
    else
        cp "$gtf" "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf"
    fi
    cat "$gtf_tmp_sequence" >> "$output_directory/custom/$(basename "$gtf" .gtf.gz)_$(basename "$sequence_file" .txt).gtf"
fi

# Clean up temporary directory
rm -rf "$output_directory/tmp"

echo "🧹 Temporary files removed."

echo "✅ Script execution completed successfully."