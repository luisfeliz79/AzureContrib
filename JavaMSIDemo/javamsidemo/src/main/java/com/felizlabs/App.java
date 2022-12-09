package com.felizlabs;
import java.io.IOException;

import com.azure.core.credential.AccessToken;
import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.*;

import reactor.core.publisher.Mono;
/**
 * Hello world!
 *
 */
public class App 
{
    public static void main( String[] args ) throws IOException
    {
      // The default credential first checks environment variables for configuration
      // If environment configuration is incomplete, it will try managed identity
      //
      // run az login for testing in development onprem
      System.out.println ("Starting...");

      String Client_Id = System.getenv("CLIENT_ID");
      if (null != Client_Id ) {
        System.out.println ("Using Client ID "+Client_Id);
      }
      


      // DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()
      //                                                   .managedIdentityClientId("832da921-fb91-4efc-8b36-54abce9a4e23")
      //                                                   .build();

      
      ManagedIdentityCredential miCred = new ManagedIdentityCredentialBuilder()
                                      .clientId(Client_Id).build();
      AzureCliCredential azCliCred = new AzureCliCredentialBuilder().build();
      
      ChainedTokenCredential defaultCredential = 
          new ChainedTokenCredentialBuilder()
              .addFirst(miCred)
              .addLast(azCliCred)
              .build();

      TokenRequestContext tokenRequest = new TokenRequestContext().addScopes("https://management.azure.com");
      Mono<AccessToken> token = defaultCredential.getToken(tokenRequest);
      
      System.out.println(token.block().getToken());

      //while (true) {
        System.in.read();
      //}
    //   ManagedIdentityCredential miCred = new ManagedIdentityCredentialBuilder().build();
    //   AzureCliCredential azCliCred = new AzureCliCredentialBuilder().build();
      
    //   ChainedTokenCredential defaultCredential = 
    //       new ChainedTokenCredentialBuilder()
    //           .addFirst(miCred)
    //           .addLast(azCliCred)
    //           .build();
    }
}
