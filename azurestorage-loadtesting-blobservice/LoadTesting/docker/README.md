# Creating and running a docker container

  ```bash
  Note: Requires Java runtime, Maven, and Docker, and an Azure Linux virtual machine with the Managed Identity enabled.

  # Compile the code
  cd source/javablob
  mvn compile
  mvn package
  mvn install dependency:copy-dependencies

  # Create the container
  cd source
  sudo docker build -t javablob .
  
  # run it
  sudo docker run javablob &