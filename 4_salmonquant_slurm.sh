#!/bin/bash -l
#SBATCH --job-name=SalmonQuant            # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=20                 # Number of CPU cores per task
#SBATCH --mem=16GB                        # Memory allocation
#SBATCH --time=04:00:00                   # Time limit
#SBATCH --export=NONE                     # Export environment variables

echo "Job started at $(date)"

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories and file paths
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/PROJ_001.RL/3_featurecounts
OUTPUT_DIR=/group/sbs010/rli/PROJ_001.RL/4_quantification
TRANSCRIPTS=/group/sbs010/rli/referencegenome/gencode_files/GRCh38.primary_assembly.genome.fa

# Create SCRATCH directory
mkdir -p $SCRATCH

# Print directory paths
echo "SCRATCH directory is $SCRATCH"
echo "OUTPUT_DIR directory is $OUTPUT_DIR"
echo "TRANSCRIPTS file is $TRANSCRIPTS"

# Copy input files to SCRATCH
echo "Copying input files to SCRATCH directory..."
cp $INPUT/*Aligned.toTranscriptome.out.bam $SCRATCH/

# Set up log file
LOG_FILE=$SCRATCH/SalmonQuant-$SLURM_JOBID.log

# Change to SCRATCH directory
cd $SCRATCH

# Run Salmon quantification
echo "Running Salmon quantification..."
for i in *Aligned.toTranscriptome.out.bam; do
    SAMPLE_NAME="${i%%.*}"

    echo "Processing sample: $SAMPLE_NAME"

    # Construct the Salmon command
    salmon quant \
        -a $i \
        -t $TRANSCRIPTS \
        -l ISR \
        -p 20 \
        --seqBias \
        --gcBias \
        -o ${SAMPLE_NAME}.salmon
        
    # Rename quant.sf inside the Salmon output directory
    if [ -f ${SAMPLE_NAME}.salmon/quant.sf ]; then
        mv ${SAMPLE_NAME}.salmon/quant.sf ${SAMPLE_NAME}.salmon/${SAMPLE_NAME}_quant.sf
    else
        echo "Error: quant.sf file not found for $SAMPLE_NAME."
        exit 1
    fi
    # Cleanup: Remove the BAM file after quantification
    rm $i
done

# Move results to OUTPUT_DIR
echo "Moving results to OUTPUT_DIR..."
mv $SCRATCH/* $OUTPUT_DIR/


# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "Salmon quantification job finished at $(date)"

# Print job finish time
echo "Salmon quantification job finished at $(date)"