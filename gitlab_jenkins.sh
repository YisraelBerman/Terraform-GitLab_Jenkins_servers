#!/bin/bash
jenkins_url="http://localhost:8080"
jenkins_user="admin"
jenkins_token=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
job_name="$PROJECTNAME"


# Prepare the credentials XML for a GitLab token
CREDENTIAL_XML=$(cat <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>gitlab-credentials-id</id>
  <description>GitLab Access Token as Password</description>
  <username>GitLab Token</username>  
  <password>$TOKEN</password>  
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
)
# Add the credentials to Jenkins
echo "Creating GitLab token credentials in Jenkins"
echo "$CREDENTIAL_XML" | sudo java -jar /var/lib/jenkins/jenkins-cli.jar -s "$jenkins_url" -auth "admin:$jenkins_token" create-credentials-by-xml system::system::jenkins "(global)"












# Define the Jenkins job configuration XML
job_config_xml=$(cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1400.v7fd111b_ec82f">
  <actions/>
  <description>A simple Jenkins job triggered by GitLab</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty>
      <abortPrevious>false</abortPrevious>
    </org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty>
    <com.dabsquared.gitlabjenkins.connection.GitLabConnectionProperty plugin="gitlab-plugin@1.8.1">
      <gitLabConnection></gitLabConnection>
      <jobCredentialId></jobCredentialId>
      <useAlternativeCredential>false</useAlternativeCredential>
    </com.dabsquared.gitlabjenkins.connection.GitLabConnectionProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.dabsquared.gitlabjenkins.GitLabPushTrigger plugin="gitlab-plugin@1.8.1">
          <spec></spec>
          <triggerOnPush>true</triggerOnPush>
          <triggerToBranchDeleteRequest>false</triggerToBranchDeleteRequest>
          <triggerOnMergeRequest>true</triggerOnMergeRequest>
          <triggerOnlyIfNewCommitsPushed>false</triggerOnlyIfNewCommitsPushed>
          <triggerOnPipelineEvent>false</triggerOnPipelineEvent>
          <triggerOnAcceptedMergeRequest>false</triggerOnAcceptedMergeRequest>
          <triggerOnClosedMergeRequest>false</triggerOnClosedMergeRequest>
          <triggerOnApprovedMergeRequest>true</triggerOnApprovedMergeRequest>
          <triggerOpenMergeRequestOnPush>never</triggerOpenMergeRequestOnPush>
          <triggerOnNoteRequest>true</triggerOnNoteRequest>
          <noteRegex>Jenkins please retry a build</noteRegex>
          <ciSkip>true</ciSkip>
          <skipWorkInProgressMergeRequest>true</skipWorkInProgressMergeRequest>
          <labelsThatForcesBuildIfAdded></labelsThatForcesBuildIfAdded>
          <setBuildDescription>true</setBuildDescription>
          <branchFilterType>All</branchFilterType>
          <includeBranchesSpec></includeBranchesSpec>
          <excludeBranchesSpec></excludeBranchesSpec>
          <sourceBranchRegex></sourceBranchRegex>
          <targetBranchRegex></targetBranchRegex>
                    <secretToken>$JENKINSTOKEN</secretToken>
          <cancelPendingBuildsOnUpdate>false</cancelPendingBuildsOnUpdate>
        </com.dabsquared.gitlabjenkins.GitLabPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3894.3896.vca_2c931e7935">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.2.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$GITURL</url>
          <credentialsId>gitlab-credentials-id</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/*</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>


EOF
)

# Create the Jenkins job using the defined XML
echo "$job_config_xml" | sudo java -jar /var/lib/jenkins/jenkins-cli.jar -s "$jenkins_url" -auth "admin:$jenkins_token" create-job "$job_name"

