#!/bin/bash -l
#SBATCH --job-name=FeatureCounts         # Job name
#SBATCH --partition=work                  # Partition to use
#SBATCH --nodes=1                        # Number of nodes
#SBATCH --ntasks=1                       # Number of tasks
#SBATCH --cpus-per-task=12                # Number of CPU cores per task
#SBATCH --mem=16GB                       # Memory allocation
#SBATCH --time=01:00:00                  # Time limit
#SBATCH --export=NONE                    # Export environment variables

echo "Job started at $(date)"

# Activate Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories and file paths
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/PROJ_001.RL/2_alignment
OUTPUT_DIR=/group/sbs010/rli/PROJ_001.RL/3_featurecounts
GTF_FILE=/group/sbs010/rli/referencegenome/gencode_files/gencode.v46.basic.annotation.gtf

# Create SCRATCH and OUTPUT_DIR directories
mkdir -p $SCRATCH
mkdir -p $OUTPUT_DIR

# Print directory paths
echo "SCRATCH directory is $SCRATCH"
echo "OUTPUT_DIR directory is $OUTPUT_DIR"

# Copy input files to SCRATCH
echo "Copying input files to SCRATCH directory..."
cp $INPUT/*Aligned.sortedByCoord.out.bam $SCRATCH

# Change to SCRATCH directory
cd $SCRATCH

# Run featureCounts for each BAM file
echo "Running featureCounts..."
for i in *Aligned.sortedByCoord.out.bam; do
     SAMPLE_NAME="${i%%.*}"
    
    # Construct the output file name
    OUTPUT_FILE="${SAMPLE_NAME}.feature_counts.txt"
    
    # Run featureCounts for the current BAM file
    featureCounts -T 12 -O -p -g gene_id -t exon -a $GTF_FILE -o $OUTPUT_FILE $i
done

# Move results to OUTPUT_DIR
echo "Moving results to OUTPUT_DIR..."
mv $SCRATCH/*.feature_counts.txt $OUTPUT_DIR/


# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "FeatureCounts job finished at $(date)"