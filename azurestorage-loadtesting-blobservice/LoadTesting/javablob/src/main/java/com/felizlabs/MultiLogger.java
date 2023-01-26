package com.felizlabs;

import java.util.ArrayList;

import org.slf4j.Logger;

public class MultiLogger {

   Logger logger;
   ArrayList<String> messages=new ArrayList<String>();

   public MultiLogger(Logger logger){
        this.logger = logger;
   } 

   public void info(String message){
        logger.info("-------------" + message + "--------------");
        messages.add(message);
   }

   public void clear(){
        messages.clear();
   }

   public String getMessages() {
    return String.join("\r\n",messages);
   }

}
