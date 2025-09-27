#!/bin/bash -l
#SBATCH --job-name=STAR_index_creation    # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=8                 # Number of CPUs per task (adjust as needed)
#SBATCH --mem-per-cpu=20GB                # Memory per CPU core
#SBATCH --time=02:00:00                   # Time limit
#SBATCH --export=NONE                     # Export environment variables

conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories
REFERENCE=/group/sbs010/rli/referencegenome
OUTPUT_DIR=/group/sbs010/rli/referencegenome/gencode_files/starindex_gencode

# Create STAR index directory
mkdir -p $OUTPUT_DIR
echo "STAR directory is $OUTPUT_DIR"

# Set up log file
LOG_FILE=$OUTPUT_DIR/PROJ_001.RL-$SLURM_JOBID.log


# Run STAR to generate genome index
STAR --runThreadN 8 \
     --runMode genomeGenerate \
     --genomeDir $OUTPUT_DIR \
     --genomeFastaFiles $REFERENCE/gencode_files/GRCh38.primary_assembly.genome.fa \
     --sjdbGTFfile $REFERENCE/gencode_files/gencode.v46.annotation.gtf \
     --sjdbOverhang 99 \
     --outFileNamePrefix $OUTPUT_DIR/

# Print job finish time
echo "STAR index creation finished at $(date)"