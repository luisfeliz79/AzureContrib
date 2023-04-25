package com.felizlabs.samples.telemetrytagging;

// for Logger
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

// Micrometer
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Metrics;
import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.binder.jvm.JvmMemoryMetrics;
import io.micrometer.core.instrument.binder.system.ProcessorMetrics;

// for Open Telemetry Spans/Dependecy tracking
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;

// For Open Telemetry Custom Metrics
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.api.metrics.LongHistogram;
import io.opentelemetry.api.metrics.Meter;

public class CustomTelemetry {

        public Logger logger;
        private Span span;
        private String jobName;
        private LongCounter inputLines;
        private LongCounter outputLines;
        private LongHistogram readTransferSpeed;
        private LongHistogram writeTransferSpeed;
        private LongHistogram readTransferTime;
        private LongHistogram writeTransferTime;
        MeterRegistry registry;
        

    public CustomTelemetry(String jobName) {
            // Default Constructor
            this.jobName = jobName;

            // Initiate Telemetry sources

            // Logback
                // Using Logback for logging -- App Insights will automatically ingest this
                this.logger = LoggerFactory.getLogger(CustomTelemetry.class);
                // Add property jobName to your calls to logger
                MDC.put("jobName", jobName);

            // OpenTelemetry
            // Using OTEL Libraries for CustomMetrics and dependency tracking
            // App Insights will automatically ingest this
                Tracer tracer = GlobalOpenTelemetry.getTracer("OTEL.AzureMonitor.Demo") ;
                //Start a span and tag jobName on dependencies            
                this.span = tracer.spanBuilder(jobName).startSpan();
                AttributeKey jobNameAttributeKey = AttributeKey.stringKey("jobName");
                span.setAttribute(jobNameAttributeKey, jobName);
                span.makeCurrent();

            
            // JVM Metrics
            // Using Micrometer metrics for JVM metrics and custom metrics
            // App Insights will ingest telemetry sent to the Global Registry
                this.registry = Metrics.globalRegistry;
                // CPU and Memory metrics using Micrometer with tagging
                Tags tags = Tags.of("jobName", jobName);
                new ProcessorMetrics(tags).bindTo(registry);
                new JvmMemoryMetrics(tags).bindTo(registry);


            // Custom Metrics
            // For Custom Metrics we can use OpenTelemetry functions
            // Create your own functions for each Custom Metric
            // App Insights will automatically ingest this
                Meter meter = GlobalOpenTelemetry.getMeter("OTEL.AzureMonitor.Demo");
                inputLines = meter.counterBuilder("lines.read").build();
                outputLines = meter.counterBuilder("lines.written").build();
                readTransferSpeed =  meter.histogramBuilder("read.speed").ofLongs().setUnit("kb").build();
                writeTransferSpeed = meter.histogramBuilder("write.speed").ofLongs().setUnit("kb").build();
                readTransferTime = meter.histogramBuilder("read.time").ofLongs().setUnit("ms").build();
                writeTransferTime = meter.histogramBuilder("write.time").ofLongs().setUnit("ms").build();

       

    }

    public void TrackReadSpeed(Long speed){
        readTransferSpeed.record(speed,Attributes.of(AttributeKey.stringKey("jobName"), this.jobName));
    }

    public void TrackWriteSpeed(Long speed){           
        writeTransferSpeed.record(speed,Attributes.of(AttributeKey.stringKey("jobName"), this.jobName));
    }
    
    public void TrackReadTransferTime(Long time){
        readTransferTime.record(time,Attributes.of(AttributeKey.stringKey("jobName"), this.jobName));
    }

    public void TrackWriteTransferTime(Long time){      
        writeTransferTime.record(time,Attributes.of(AttributeKey.stringKey("jobName"), this.jobName));
    }

    public void TrackLinesRead(){
        inputLines.add(1,Attributes.of(AttributeKey.stringKey("jobName"), this.jobName));
    }

    public void TrackLineWritten(){
        outputLines.add(1,Attributes.of(AttributeKey.stringKey("jobName"), this.jobName));
    }
}
