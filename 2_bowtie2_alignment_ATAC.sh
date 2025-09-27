#!/bin/bash -l
#SBATCH --job-name=2Bowtie2_Align    # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4         # Number of CPU cores per task
#SBATCH --mem=32GB                  # Memory allocation
#SBATCH --time=20:00:00             # Time limit
#SBATCH --output=alignment_bowtie2_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
# Ensure that the reference index refers to the base name of your index files i.e.
# /reference_index/myindex would indicate index files of myindex.1.bt2, myindex.2.bt2 etc.
# In this case, the index files are named further down as genome_index as their header.
REFERENCE_INDEX=/group/sbs010/rli/referencegenome/bowtie2_index_gencode_2.5.4
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/1_trimming_2
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/2_alignment_2
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

echo "REFERENCE folder has:"
ls $REFERENCE_INDEX

# copy files to SCRATCH
cp $INPUT_DIR/*.fq.gz $SCRATCH

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

for i in $(ls $SCRATCH/*.R1.fq.gz | sed 's/.out.R1.fq.gz//g' | sort | uniq); do
    echo "Processing sample: $i"
    
    # Run Bowtie2 and align data with index
    # Alignment rates should be >90% if trimming is successful.
    bowtie2 -x $REFERENCE_INDEX/genome_index \
    -1 ${i}.out.R1.fq.gz \
    -2 ${i}.out.R2.fq.gz \
    -S ${i}.sam \
    -p 15 -X 1000
    
    if [ $? -ne 0 ]; then
        echo "Error running bowtie2 on ${i}"
        exit 1
    fi

# Move the SAM file to the output directory
mv $SCRATCH/*.sam $OUTPUT_DIR/

done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
