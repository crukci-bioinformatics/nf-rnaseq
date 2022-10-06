params.quantTool = "salmon"

include { RNASEQREPORT } from "../processes/rnaseqreportprocess"

workflow report_wf
{
    take:
        report_ch
    
    main:
        RNASEQREPORT(report_ch)
}

