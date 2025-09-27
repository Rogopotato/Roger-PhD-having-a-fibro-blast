#!/bin/bash -l
#SBATCH --job-name=fastp_trim          # Job name
#SBATCH --partition=work                 # Partition to use
#SBATCH --nodes=1                       # Number of nodes
#SBATCH --ntasks=1                      # Number of tasks
#SBATCH --cpus-per-task=4               # Number of CPU cores per task
#SBATCH --mem=16GB                       # Memory allocation
#SBATCH --time=8:00:00                 # Time limit
#SBATCH --output=fastp_trim_%j.log        # Standard output log file
#SBATCH --error=fastp_trim_%j.err          # Standard error log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/rawdata/rawdata_03102024_ATAC
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/1_trimming_2
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/*.fastq.gz $SCRATCH

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Trimming with fastp
# This will remove lower quality Phred score sequences as well as adapters; Nextera and PolyG for our ATAC
for i in $(ls $SCRATCH/*_R1.fastq.gz | sed 's/_R1.fastq.gz//g' | cut -f1 | sort | uniq); do
    echo "processing $i"
    fastp -i ${i}_R1.fastq.gz -I ${i}_R2.fastq.gz -o $i.out.R1.fq.gz -O $i.out.R2.fq.gz
    echo "$i processed at $(date)"
done

mv $SCRATCH/*out.R1.fq.gz $OUTPUT_DIR/
mv $SCRATCH/*out.R2.fq.gz $OUTPUT_DIR/

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"