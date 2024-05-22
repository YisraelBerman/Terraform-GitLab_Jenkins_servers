#!/bin/bash
set -x

sudo apt-get update -y
echo installing JAVA
sudo apt-get install -y openjdk-11-jdk

# Install Java if not already installed, and check the installation
if type java; then 
    echo Java is already installed; 
    java -version; 
else 
    echo Java is not installed, attempting installation; 
    sudo apt-get install -y openjdk-11-jdk; 
fi
java -version || { echo Failed to install Java; exit 1; }

echo installing Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo ufw allow 22
sudo ufw allow 8080
sudo ufw --force enable

echo copying password to file
while ! sudo systemctl is-active --quiet jenkins; do sleep 1; done

sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /home/ubuntu/jenkins_initial_admin_password.txt

echo "Setting up Jenkins..."

JENKINS_URL="http://localhost:8080"

echo "Downloading Jenkins CLI..."
if curl -s http://localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar; then
    echo "Download successful."
else
    echo "Failed to download Jenkins CLI jar. Is Jenkins running and accessible on http://localhost:8080?"
    exit 1
fi

echo "Moving Jenkins CLI jar to the Jenkins home directory..."
sudo cp jenkins-cli.jar /var/lib/jenkins/jenkins-cli.jar

echo "Retrieving Jenkins initial admin password..."
if PASS=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword); then
    echo "Password retrieved successfully."
else
    echo "Failed to retrieve the initial admin password. Check permissions and file existence."
    exit 1
fi

echo "Installing Jenkins plugins..."

PLUGINS=(
    git
    timestamper
    ws-cleanup
    cloudbees-folder
    antisamy-markup-formatter
    build-timeout
    credentials-binding
    gitlab-plugin
    workflow-aggregator
    github-branch-source
    pipeline-github-lib
    pipeline-graph-view
    mailer
    email-ext
    ssh-slaves
    matrix-auth
    pam-auth
    ldap
)

# Loop through each plugin and install it using the Jenkins CLI
for plugin in "${PLUGINS[@]}"; do
    echo "Installing plugin: $plugin..."
    if ! sudo java -jar /var/lib/jenkins/jenkins-cli.jar -s "$JENKINS_URL" -auth "admin:$PASS" install-plugin "$plugin"; then
        echo "Failed to install $plugin plugin. Check Jenkins CLI logs for errors."
        exit 1
    fi
done

echo "All plugins installed successfully."

echo "Restarting Jenkins to activate the installed plugins..."
if sudo java -jar /var/lib/jenkins/jenkins-cli.jar -s "$JENKINS_URL" -auth "admin:$PASS" restart; then
    echo "Jenkins is restarting..."
else
    echo "Failed to restart Jenkins. Check Jenkins CLI logs for errors."
    exit 1
fi

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
while ! curl -sSf $JENKINS_URL/login > /dev/null; do
    echo "Waiting for Jenkins..."
    sleep 5
done

sleep 30

# Add Jenkins credentials
echo "Creating Jenkins credentials"
CREDENTIAL_XML=$(cat <<EOF
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@1.18.1">  <scope>GLOBAL</scope>
  <id>my-credential-id</id>
  <description>SSH credentials for Jenkins agent</description>
  <username>ubuntu</username>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
    <privateKey>$(cat /tmp/your_key.pem)</privateKey>
   </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF
)
echo "$CREDENTIAL_XML" | sudo java -jar /var/lib/jenkins/jenkins-cli.jar -s "$JENKINS_URL" -auth "admin:$PASS" create-credentials-by-xml system::system::jenkins "(global)"

sleep 30


# Agent XML using heredoc syntax as well
echo "Adding Jenkins agent"
AGENT_XML=$(cat <<EOF
<slave>
  <name>my-ssh-agent</name>
  <description>SSH Build Agent</description>
  <remoteFS>/home/ubuntu/jenkins-agent</remoteFS>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy\$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.31.2">
    <host>agent_ip_here</host>
    <port>22</port>
    <credentialsId>my-credential-id</credentialsId>
    <javaPath>/usr/bin/java</javaPath>
  </launcher>
  <label>linux ssh</label>
  <nodeProperties/>
  <userId>admin</userId>
</slave>
EOF
)
echo "$AGENT_XML" | sudo java -jar /var/lib/jenkins/jenkins-cli.jar -s "$JENKINS_URL" -auth "admin:$PASS" create-node

echo "Jenkins setup completed successfully."
