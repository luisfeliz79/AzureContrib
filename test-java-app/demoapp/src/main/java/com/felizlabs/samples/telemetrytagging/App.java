package com.felizlabs.samples.telemetrytagging;


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
   


            while (true) {
                logger.info("Hello World! This is a log message.");
                try {
                    Thread.sleep(5000);
                } catch (InterruptedException e) {
                    logger.error("Thread was interrupted", e);
                }


            }
    }
      
}
