process FASTQSCREEN_FASTQSCREEN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastq-screen:0.15.3--pl5321hdfd78af_0':
        'biocontainers/fastq-screen:0.15.3--pl5321hdfd78af_0'}"

    input:
    tuple val(meta), path(reads)  // .fastq files
    tuple val(meta), path(database) // [[database_name,  database_notes], database_path]

    output:
    tuple val(meta), path("*.txt")     , emit: txt
    tuple val(meta), path("*.png")     , emit: png  , optional: true
    tuple val(meta), path("*.html")    , emit: html
    tuple val(meta), path("*.fastq.gz"), emit: fastq, optional: true
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ""
    // 'Database name','Genome path and basename','Notes'
    """
    fastq_screen --add_genome \\
        '$meta.database_name','$database_path','$meta.database_notes'

    fastq_screen
        --conf fastq_screen.conf \\
        --threads ${task.cpus} \\
        $reads \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqscreen: \$(echo \$(fastq_screen --version 2>&1) | sed 's/^.*FastQ Screen v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch test_1_screen.html
    touch test_1_screen.png
    touch test_1_screen.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqscreen: \$(echo \$(fastq_screen --version 2>&1) | sed 's/^.*FastQ Screen v//; s/ .*\$//')
    END_VERSIONS
    """

}
