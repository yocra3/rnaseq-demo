/*
 * Defines some parameters in order to specify the refence genomes
 * and read pairs by using the command line options
 */

baseDir = "./"

params.reads = "$baseDir/data/ggal/reads/ggal_gut_{1,2}.fq"
params.annot = "$baseDir/data/ggal/annotation.gff"
params.genome = "$baseDir/data/ggal/genome.fa"
params.outdir = 'results'

/* 
 * prints user convenience 
 */
println "R N A T O Y   P I P E L I N E    "
println "================================="
println "genome             : ${params.genome}"
println "annotat            : ${params.annot}"
println "reads              : ${params.reads}"

println "Pipeline details"
println "================================="
println "Manifest's pipeline version: $workflow.manifest.version"
println "Project : $workflow.projectDir"
println "Git info: $workflow.repository - $workflow.revision [$workflow.commitId]"
println "Cmd line: $workflow.commandLine"
println "Manifest's pipeline version: $workflow.manifest.version"


logf = file("$baseDir/${params.outdir}/log.txt")
logf.text = "Manifest's pipeline version: $workflow.manifest.version\n"
logf << "Project : $workflow.projectDir\n"
logf << "Git info: $workflow.repository - $workflow.revision [$workflow.commitId]\n"
logf << "Cmd line: $workflow.commandLine\n"



/*
 * get a file object for the given param string
 */
genome_file = file(params.genome)
annotation_file = file(params.annot)
 
/*
 * Step 1. Builds the genome index required by the mapping process
 */
process buildIndex {
    
    input:
    file genome from genome_file
     
    output:
    file 'genome.index*' into genome_index
       
    """
    bowtie2-build --threads ${task.cpus} ${genome} genome.index
    """
}

/*
 * Create the `read_pairs` channel that emits tuples containing three elements:
 * the pair ID, the first read-pair file and the second read-pair file 
 */
read_pairs = Channel.fromFilePairs(params.reads, flat: true)

/*
 * Step 2. Maps each read-pair by using Tophat2 mapper tool
 */
process mapping {
     
    input:
    file 'genome.index.fa' from genome_file 
    file genome_index from genome_index
    set pair_id, file(read1), file(read2) from read_pairs
 
    output:
    set pair_id, "tophat_out/accepted_hits.bam" into bam
 
    """
    tophat2 -p ${task.cpus} genome.index ${read1} ${read2}
    """
}

/*
 * Step 3. Assembles the transcript by using the "cufflinks" tool
 */
process makeTranscript {
    publishDir params.outdir, mode: 'copy'  
       
    input:
    file annot from annotation_file 
    set pair_id, file(bam_file) from bam
     
    output:
    set pair_id, file('transcript_*.gtf') into transcripts
 
    """
    cufflinks --no-update-check -q -p ${task.cpus} -G $annot ${bam_file}
    mv transcripts.gtf transcript_${pair_id}.gtf
    """
}

