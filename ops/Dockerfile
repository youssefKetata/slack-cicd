# filepath: c:\Users\PC6\projects\slack-cicd\ops\Dockerfile
# Use the official Jenkins LTS image as a base
FROM jenkins/jenkins:lts

# Switch to root user to install packages and modify groups
USER root

# Install prerequisites
RUN apt-get update && apt-get install -y lsb-release apt-transport-https ca-certificates curl gnupg

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI (only the client is needed)
RUN apt-get update && apt-get install -y docker-ce-cli

# Add jenkins user to the root group (GID 0) to access the docker socket
# (Based on ls -l output showing root:root ownership for the socket)
RUN usermod -aG root jenkins

# Switch back to the jenkins user
USER jenkins