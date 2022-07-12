params.quantTool = "salmon"

include { SALMON } from "../processes/salmon"

workflow salmon_pe
{
    take:
        csv_channel

    main:
        fastq_channel = 
            csv_channel
                .map(row -> tuple "${row.SampleName}", file("${params.fastqDir}/${row.Read1}", checkIfExists:true), file("${params.fastqDir}/${row.Read2}", checkIfExists:true) )
                .groupTuple()
                
        SALMON(fastq_channel)
}

