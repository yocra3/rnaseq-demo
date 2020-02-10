#!/bin/bash 
set -e 
set -u

annot=${1}
bam_file=${2}
pair_id=${3}

cufflinks --no-update-check -q -G $annot ${bam_file}
mv transcripts.gtf transcript_${pair_id}.gtf
