package com.felizlabs.samples.telemetrytagging;


import java.util.ArrayList;
import java.util.List;

// for Logger
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class App 
{
    public static void main( String[] args )
    {
             
            // Using Logback for logging -- App Insights will automatically track this
            Logger logger = LoggerFactory.getLogger(App.class);

            if (null == System.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")  )  {
                logger.info("Missing Variable APPLICATIONINSIGHTS_CONNECTION_STRING\ntelemetry will not be ingested");
            }
    
            // Define a list of jobs
            List<JobDefinition> jobs = new ArrayList<>();
            jobs.add(new JobDefinition("merge-x-and-z-words","x.txt","z.txt"));

            jobs.add(new JobDefinition("merge-a-and-c-words","a.txt","c.txt"));

            
            // Work on the jobs
            logger.info("Entering Process Jobs loop");

            for (JobDefinition job: jobs){
                
                ///////////////////////////////////////////////////////////
                //                     FOR EACH JOB                      //
                //                SETUP TELEMETRY WITH TAGGING           //
                ///////////////////////////////////////////////////////////
                String jobName   = String.format("%s-%s",System.currentTimeMillis(),job.getjobName());        

                CustomTelemetry myteTelemetry = new CustomTelemetry(jobName);
            
              
                // Process a job
                ProcessJob mytest = new ProcessJob(job,myteTelemetry);




            }
    }
      
}
