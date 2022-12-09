package com.felizlabs;
import java.io.IOException;

import com.azure.core.credential.AccessToken;
import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.*;

import reactor.core.publisher.Mono;

public class App 
{
    public static void main( String[] args ) throws IOException
    {
      // The default credential first checks environment variables for configuration
      // If environment configuration is incomplete, it will try managed identity
      //
      // run az login for testing in development onprem
      System.out.println ("Starting...");

      String Client_Id = System.getenv("AZURE_CLIENT_ID");
      if (null != Client_Id ) {
        System.out.println ("Using Client ID "+Client_Id);
      }
      
      String Scopes = new String();
      
      if (args.length > 0) {
        Scopes = args[0];
      } else {
        Scopes = "https://management.azure.com/.default" ;
      }
    
      System.out.println ("Using Scope "+ Scopes);

     
      ManagedIdentityCredential miCred = new ManagedIdentityCredentialBuilder()
                                                .clientId(Client_Id)
                                                .build();

      AzureCliCredential azCliCred = new AzureCliCredentialBuilder()
                                                .build();
      
      ChainedTokenCredential defaultCredential = new ChainedTokenCredentialBuilder()
                                                .addFirst(miCred)
                                                .addLast(azCliCred)
                                                .build();

      TokenRequestContext tokenRequest = new TokenRequestContext().addScopes(Scopes);
      Mono<AccessToken> token = defaultCredential.getToken(tokenRequest);
      
      System.out.println(token.block().getToken());

      System.out.println("\n"+"Press Any Key to continue");
      System.in.read();

    }
}
