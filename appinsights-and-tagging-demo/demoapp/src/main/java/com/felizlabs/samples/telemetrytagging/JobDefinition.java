package com.felizlabs.samples.telemetrytagging;

public class JobDefinition {

    private String jobName;
    private String fileName1;
    private String fileName2;

    public JobDefinition( String jobName,String fileName1, String fileName2) {
        this.jobName = jobName;
        this.fileName1 = fileName1;
        this.fileName2 = fileName2;
        
    }

    public String getjobName(){ return jobName; }
    public void setjobName(String jobName) { this.jobName = jobName.toLowerCase() ; }     
    
    public String getfileName1(){ return fileName1; }
    public void setfileName1(String fileName) { this.fileName1 = fileName; }
    
    public String getfileName2(){ return fileName2; }
    public void setfileName2(String fileName) { this.fileName2 = fileName; }     

}
