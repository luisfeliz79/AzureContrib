package com.felizlabs;

import java.net.*;
import java.io.*;
import java.util.*;

public class WebUI extends Thread  {
  
     static final int port=80;
     static final String newLine="\r\n";
     MultiLogger logger;

     public WebUI(MultiLogger logger) {
        this.logger = logger;
     }
    
    
    public void run()
     {
      try
      {
       ServerSocket socket=new ServerSocket(port);
       
       
    
       while (true)
       {
        Socket connection=socket.accept();
    
        try
        {
         BufferedReader in=new BufferedReader(new InputStreamReader(connection.getInputStream()));
         OutputStream out=new BufferedOutputStream(connection.getOutputStream());
         PrintStream pout=new PrintStream(out);
    
         // read first line of request
         String request=in.readLine();
         if (request==null) continue;
    
         // we ignore the rest
         while (true)
         {
          String ignore=in.readLine();
          if (ignore==null || ignore.length()==0) break;
         }
    
         if (!request.startsWith("GET ") ||
             !(request.endsWith(" HTTP/1.0") || request.endsWith(" HTTP/1.1")))
         {
          // bad request
          pout.print("HTTP/1.0 400 Bad Request"+newLine+newLine);
         }
         else
         {
          String response=logger.getMessages();
          pout.print(
           "HTTP/1.0 200 OK"+newLine+
           "Content-Type: text/plain"+newLine+
           "Date: "+new Date()+newLine+
           "Content-length: "+response.length()+newLine+newLine+
           response
          );
         }
    
         pout.close();
        }
        catch (Throwable tri)
        {
         System.err.println("Error handling request: "+tri);
        }
       }
      }
      catch (Throwable tr)
      {
       System.err.println("Could not start server: "+tr);
      }
     }

}

