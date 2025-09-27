#!/bin/bash -l
#SBATCH --job-name=fina_QC      # Job name
#SBATCH --partition=work                         # Partition to use
#SBATCH --nodes=1                                # Number of nodes
#SBATCH --ntasks=1                               # Number of tasks
#SBATCH --cpus-per-task=4                        # Number of CPU cores per task
#SBATCH --mem=16GB                               # Memory allocation
#SBATCH --time=35:00:00                          # Time limit
#SBATCH --output=final_QC_%j.log  # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/mstentenbach/.conda/envs/PROJ_002.RL

# Set up directories and file paths
BAM_INPUT_DIR=/group/sbs010/mstentenbach/PROJ_002.RL/4_deduplicate_15B  # Path for deduplicated BAM files
BAM_INDEX_DIR=/group/sbs010/mstentenbach/PROJ_002.RL/5_bam_index_15B    # Path for index files
POST_TRIM_QC_DIR=/group/sbs010/mstentenbach/PROJ_002.RL/1.2_QC_post_trim_15B  # Path for post-trim QC
OUTPUT_DIR=/group/sbs010/mstentenbach/PROJ_002.RL/4.1_final_QC_15B  # Output directory
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID  # Scratch directory

# Create output and scratch directories
mkdir -p $OUTPUT_DIR
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"
# Copy cleaned BAM files and their index files to SCRATCH
for bam_file in $BAM_INPUT_DIR/*.clean.bam; do
    echo "Copying BAM file: $bam_file to $SCRATCH/"
    cp "$bam_file" "$SCRATCH/"
    
    # Construct the index file name and copy it
    base_name=$(basename "$bam_file" .clean.bam)
    index_file="$BAM_INDEX_DIR/${base_name}.clean.bam.bai"
    
    if [[ -f "$index_file" ]]; then
        echo "Copying index file: $index_file to $SCRATCH/"
        cp "$index_file" "$SCRATCH/"
    else
        echo "Index file $index_file not found." >> "${OUTPUT_DIR}/bamQC_log.txt"
    fi
done

# Run bamQC on the copied BAM files
echo "Running bamQC on cleaned BAM files..."
for bam_file in $SCRATCH/*.clean.bam; do
    index_file="$SCRATCH/$(basename "$bam_file" .clean.bam).clean.bam.bai"
    
    # Check if the index file exists
    if [[ -f "$index_file" ]]; then
        sample_name=$(basename "$bam_file" .clean.bam)  # Extract the sample name
        echo "Running bamQC for sample: $sample_name with BAM file $bam_file and index $index_file" >> "${OUTPUT_DIR}/bamQC_log.txt"
        
        Rscript -e "
            library(ATACseqQC)
            bamQC(
                bamfile = '$bam_file',
                index = '$index_file',
                mitochondria = 'chrM',
                outPath = file.path('$OUTPUT_DIR', paste0(basename('$bam_file'), '_bamQC')),
                doubleCheckDup = FALSE
            )
        " >> "${OUTPUT_DIR}/bamQC_log.txt" 2>&1
        
        echo "Finished bamQC for sample: $sample_name" >> "${OUTPUT_DIR}/bamQC_log.txt"
    else
        echo "Index file $index_file not found for $bam_file" >> "${OUTPUT_DIR}/bamQC_log.txt"
    fi
done

# Quality control with samtools flagstat
echo "Running samtools flagstat on BAM files..."
for bam_file in $SCRATCH/*.clean.bam; do
    samtools flagstat $bam_file > $OUTPUT_DIR/$(basename $bam_file .clean.bam)_flagstat.txt
done

# Quality control with Qualimap
echo "Running Qualimap on BAM files..."
for bam_file in $SCRATCH/*.clean.bam; do
    qualimap bamqc -bam $bam_file -outdir $OUTPUT_DIR/qualimap_$(basename $bam_file .clean.bam) -outformat HTML
done

# Run MultiQC to aggregate reports
echo "Running MultiQC to integrate reports..."
multiqc $OUTPUT_DIR $POST_TRIM_QC_DIR -o $OUTPUT_DIR/multiqc_report --verbose

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
