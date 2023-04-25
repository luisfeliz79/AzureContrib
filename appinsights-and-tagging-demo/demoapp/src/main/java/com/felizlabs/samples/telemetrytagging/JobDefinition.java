package com.felizlabs.samples.telemetrytagging;

public class JobDefinition {

    private String jobName;
    private String fileName;

    public JobDefinition(String jobName, String fileName) {
        this.jobName = jobName;
        this.fileName = fileName;
        
    }

    public String getjobName(){ return jobName; }
    public void setjobName(String jobName) { this.jobName = jobName; }     
    
    public String getfileName(){ return fileName; }
    public void setfileName(String fileName) { this.fileName = fileName; }     

}
