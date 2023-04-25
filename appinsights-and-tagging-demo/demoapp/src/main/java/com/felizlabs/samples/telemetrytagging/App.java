package com.felizlabs.samples.telemetrytagging;


import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

// for Logger
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// for Micrometer
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Metrics;
import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.binder.jvm.JvmMemoryMetrics;
import io.micrometer.core.instrument.binder.system.ProcessorMetrics;


@SpringBootApplication
public class App 
{
    public static void main( String[] args )
    {
        
            // Using Logback for logging -- App Insights will automatically track this
            Logger logger = LoggerFactory.getLogger(App.class);

            // Define jobs
            List<JobDefinition> jobs = new ArrayList<>();
            jobs.add(new JobDefinition("test142mb","test142mb.txt"));
            //jobs.add(new JobDefinition("test142mb","test142mb.txt"));
            //jobs.add(new JobDefinition("test142mb","test142mb.txt"));
            
            // Work on the jobs
            for (JobDefinition job: jobs){

                String jobName   = job.getjobName()+System.currentTimeMillis();
                
                ///////////////////////////////////////////////////////////
                //                     FOR EACH JOB                      //
                //                SETUP TELEMETRY WITH TAGGING           //
                ///////////////////////////////////////////////////////////

                // Call our class that Initiates all the telemetry
                CustomTelemetry myteTelemetry = new CustomTelemetry(jobName);


                String fileName  = job.getfileName();                
              
                ADLSTest mytest = new ADLSTest(fileName,jobName,myteTelemetry);

                // Wait sometime before exiting so that our 
                // JVM metrics update a few times
                try {
                    Thread.sleep(60000*6);
                } catch (InterruptedException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }



            }
    }
      
}
