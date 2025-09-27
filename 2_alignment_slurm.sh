#!/bin/bash -l
#SBATCH --job-name=star_align             # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=12                # Number of CPUs per task
#SBATCH --mem=64GB                        # Total memory (RAM) required
#SBATCH --time=12:00:00                   # Time limit (hh:mm:ss)
#SBATCH --export=NONE                     # Export environment variables

echo "Job started at $(date)"

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/PROJ_001.RL/1_trimming_2
OUTPUT=/group/sbs010/rli/PROJ_001.RL/2_alignment
REFGENOME=/group/sbs010/rli/referencegenome/starindex_gencode

# Create SCRATCH directory
mkdir -p $SCRATCH

echo "SCRATCH directory is $SCRATCH"

# Set up log file
LOG_FILE=$SCRATCH/star_alignment-$SLURM_JOBID.log
cd $SCRATCH

cp $INPUT/*.merged_val_1.fq.gz $SCRATCH
cp $INPUT/*.merged_val_2.fq.gz $SCRATCH

# Run STAR alignment for each pair of reads
for READ1 in $SCRATCH/*_R1.merged_val_1.fq.gz; do
    # Extract sample name
    SAMPLE_NAME=$(basename $READ1 | sed 's/_R1.merged_val_1.fq.gz//')

    # Define the corresponding R2 filename
    READ2="${SCRATCH}/${SAMPLE_NAME}_R2.merged_val_2.fq.gz"

    echo "Processing sample: $SAMPLE_NAME"
    echo "READ1: $READ1"
    echo "READ2: $READ2"

    # Align with STAR
     STAR --runThreadN 12 \
         --runMode alignReads \
         --genomeDir $REFGENOME \
         --readFilesIn $READ1 $READ2 \
         --readFilesCommand zcat \
         --outFileNamePrefix $SCRATCH/$SAMPLE_NAME \
         --outSAMtype BAM SortedByCoordinate \
         --outSAMattributes NH HI AS NM MD XS \
         --quantMode TranscriptomeSAM GeneCounts
    echo "Alignment complete for sample: $SAMPLE_NAME"

    mv $SCRATCH/${SAMPLE_NAME}*.out.bam $OUTPUT/
    mv $SCRATCH/${SAMPLE_NAME}*.out $OUTPUT/
    mv $SCRATCH/${SAMPLE_NAME}*.out.tab $OUTPUT/  
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "STAR alignment job finished at $(date)"