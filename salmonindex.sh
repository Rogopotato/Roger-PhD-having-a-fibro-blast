#!/bin/bash -l
#SBATCH --job-name=SalmonIndex            # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=8                 # Number of CPU cores per task
#SBATCH --mem=16GB                        # Memory allocation
#SBATCH --time=02:00:00                   # Time limit
#SBATCH --output=salmon_index_%j.log      # Standard output log file

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories and file paths
SCRATCH_DIR=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/referencesalmon/fa # Path to the transcript FASTA file
OUPUT_INDEX=/group/sbs010/rli/referencesalmon/salmon_index # Directory where the Salmon index will be created

# Create SCRATCH directory and OUTPUT_INDEX directory
mkdir -p $SCRATCH_DIR
mkdir -p $OUTPUT_INDEX

# Copy the transcript FASTA file to the SCRATCH directory
cp $INPUT/gencode.v46.transcripts.fa $SCRATCH_DIR

# Change to SCRATCH directory
cd $SCRATCH_DIR

# Define output directory for Salmon index
SALMON_INDEX_DIR=$SCRATCH/salmon_index
mkdir -p $SALMON_INDEX_DIR

# Build Salmon index
echo "Building Salmon index..."
ls $SCRATCH_DIR
salmon index -t gencode.v46.transcripts.fa -i $SALMON_INDEX_DIR -p 8

# Check for successful completion
if [ $? -eq 0 ]; then
    echo "Salmon index creation completed successfully."
else
    echo "Error: Salmon index creation failed." >&2
    exit 1
fi

# Move results to OUTPUT_DIR
echo "Moving results from  to OUTPUT_DIR..."

if [ -d "$$SALMON_INDEX_DIR" ]; then
    mv $$SALMON_INDEX_DIR $OUTPUT_INDEX/
else
    echo "Error: Salmon index directory $SCRATCH_DIR does not exist." >&2
    exit 1
fi

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH_DIR

# Print job finish time
echo "Salmon index job finished at $(date)"
