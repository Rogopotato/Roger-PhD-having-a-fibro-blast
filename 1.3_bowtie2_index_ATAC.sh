#!/bin/bash -l
#SBATCH --job-name=Index_Bowtie2         # Job name
#SBATCH --partition=work                  # Partition to use
#SBATCH --nodes=1                        # Number of nodes
#SBATCH --ntasks=1                       # Number of tasks
#SBATCH --cpus-per-task=4                # Number of CPU cores per task
#SBATCH --mem=32GB                        # Memory allocation
#SBATCH --time=05:00:00                  # Time limit
#SBATCH --output=bowtie2_index_%j.log    # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/referencegenome/gencode_files
OUTPUT_DIR=/group/sbs010/rli/referencegenome/bowtie2_index_gencode_2.5.4

SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID
SCRATCH_FASTA=$SCRATCH/FASTA
SCRATCH_INDEX=$SCRATCH/INDEX

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
mkdir -p $SCRATCH_FASTA
mkdir -p $SCRATCH_INDEX
echo "SCRATCH directory is $SCRATCH"
echo "SCRATCH_FASTA directory is $SCRATCH_FASTA"
echo "SCRATCH_INDEX directory is $SCRATCH_INDEX"

ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/GRCh38.primary_assembly.genome.fa $SCRATCH_FASTA

# Verify files are copied
echo "Listing files in SCRATCH_FASTA directory..."
ls $SCRATCH_FASTA

# Build your index from a FASTA file. This can take over two hours so start it first.
# Ensure you use genome and transcript files from the same build!!! 
# This one comes from https://www.gencodegenes.org/human/release_46.html
bowtie2-build $SCRATCH_FASTA/GRCh38.primary_assembly.genome.fa $SCRATCH_INDEX/genome_index

mv $SCRATCH_INDEX/* $OUTPUT_DIR/

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
