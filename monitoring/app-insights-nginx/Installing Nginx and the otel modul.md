# Configuring Nginx to send telemetry to App Insights

Nginx and Nginx Plus services can be configured to send telemetry to App Insights using the OpenTelemetry Collector. The OpenTelemetry Collector is a vendor-agnostic implementation of the OpenTelemetry protocol (OTLP) that can receive, process, and export telemetry data.

There are the main steps to configure Nginx to send telemetry to App Insights:

1. Create an App Insights resource in Azure and get the connection string.

2. Install and configure the OpenTelemetry Nginx exporter module

    NGINX Provides intructions for this here: https://docs.nginx.com/nginx/admin-guide/dynamic-modules/opentelemetry/

    This is what a sample configuration looks like:
    ```bash

    # This loads the OpenTelemetry module
    load_module modules/ngx_otel_module.so;
    user  nginx;
    worker_processes  auto;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;

        keepalive_timeout  65;

        # This configures the name of this service in the telemetry
        otel_service_name nginx-api-gw;

        # This tells the Nginx exporter to send telemetry to the OpenTelemetry Collector
        # hosted on the same machine (ex. localhost)
        otel_exporter {
            endpoint localhost:4317;
        }

        server {
        listen 80;

        # This turns on the open telemetry feature
        otel_trace on;
        otel_trace_context propagate;
        

        location / {
            proxy_pass http://backend-url:8080;
        }

    }

    }
    ```


3. Install and configure the OpenTelemetry Collector for App Insights

    Every Collector release includes APK, DEB and RPM packaging for Linux amd64/arm64/i386 systems.
    Those packages can be found here:
    https://github.com/open-telemetry/opentelemetry-collector-releases/releases

    You can find the default configuration in /etc/otelcol/config.yaml after installation.
    
    The following example is for an Ubuntu system, but similar steps can be followed for other distributions.
    ```bash
        
    # Ensure wget is installed
    sudo apt update
    sudo apt-get -y install wget

    # Download the application collector
    wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.117.0/otelcol-contrib_0.117.0_linux_amd64.deb

    # Install the application collector
    sudo dpkg -i otelcol-contrib_0.117.0_linux_amd64.deb

    # Drop a configuration file
    # Make sure to update the connection string
    # with the one from your App Insights Resource
    cat <<EOF | sudo tee /etc/otelcol-contrib/config.yaml
    receivers:
    otlp:
        protocols:
        grpc:
        http:
    otlp/2:
        protocols:
        grpc:
            endpoint: 0.0.0.0:55690
    exporters:
    azuremonitor:
        connection_string: "InstrumentationKey=xxxx;IngestionEndpoint=https://eastus2-3.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus2.livediagnostics.monitor.azure.com/;ApplicationId=xxxx"
    service:
    pipelines:
        traces:
        receivers: [otlp]
        exporters: [azuremonitor]
    EOF

    # Start and enable the application collector
    sudo systemctl enable --now otelcol-contrib

    # Check the status
    sudo systemctl status otelcol-contrib

    ```







