
# icm-partner-devops

## Overview

Repository *icm-partner-devops* provides an *Azure DevOps Pipeline* template, which can be used by ICM projects, that are managed inside *Intershops Commerce Platform*. The template should be used as is. Any custom additions should be made outside of the template.

## How to use the pipeline template

To use the pipeline template, add a file named `azure-pipelines.yml` to the root directory of your project with the following content:

```
# azure-pipelines.yml

resources:
  repositories:
    - repository: icm-partner-devops
      type: github
      endpoint: <GitHub Connection>
      name: intershop/icm-partner-devops
      ref: refs/heads/stable/v1

jobs:
  - template: ci-job-template.yml@icm-partner-devops
    parameters:
      <PARAMETER>

```
A more detailed example can be found in the `azure-pipelines.yml.tmpl` file.
After that, in Azure DevOps a new pipeline has to be created from this file.

## Parameters

| Parameter Name | Description | Default Value | Required |
|---|---|---|---|
| id | Identifies each job uniquely when ci-job-template.yml is used in a loop. Can only contain characters, numbers, and underscores. Also used to extend names of files published in extensions. |  |  |
| dependsOn | Enables an easy integration with custom jobs. The parameter will be passed as is to the 'dependsOn' property of the job. |  |  |
| condition | Enables an easy integration with custom jobs. The parameter will be passed as is to the 'condition' property of the job. |  |  |
| agentPool | Specifies the name of the agent pool. The pool name can't be hardcoded in the pipeline template. |  | Yes |
| dockerRepoICMServiceConnection | Name of the Service connection to the Docker repository |  | Yes |
| dockerRepoICM | Name of Docker repository, containing the ICM-customization product images. |  | Yes |
| artifactsFeed | Name of projects Maven repository. |  | Yes |
| acrServiceConnection | Name of the service connection to the ACR of the project. |  | Yes |
| acr | Repository in ACR including host name. |  | Yes |
| projectPath | Specifies the name of the repository. | '$(Build.Repository.Name)' | Yes |
| envPath | Name of the ci-configuration repository resource. When making adjustments, the 'directoriesConf' parameter must also be adjusted. | 'ci-configuration' | Yes |
| directoriesConf | Setting required system properties of the JVM. When making adjustments, the 'envPath' parameter must also be adjusted. | '-DlicenseDir=$(Pipeline.Workspace)/s/ci-configuration/license -DconfigDir=$(Pipeline.Workspace)/s/ci-configuration/environment' | Yes |
| repositoriesConf | Setting required project properties. | '-PrepoUser=PAT -PrepoPassword=$(System.AccessToken)' | Yes |
| gradleUserHome | Value of the GRADLE_USER_HOME variable. | '$(Pipeline.Workspace)/.gradle' | Yes |
| containerPrefix | Prefix of the GebTest containers. | '$(Build.Repository.Name)' | Yes |
| jobTimeoutInMinutes | Maximum job execution time. | 300 | Yes |
| jobContinueOnError | Specifies whether future jobs should run even if this job fails; defaults to 'false'. | false | Yes |
| runGebTest | Specifies whether all gebTest tasks should run; defaults to 'true'. | true | Yes |
| gebTestTasks | gradle gebTest tasks. | 'startSolrCloud startMailSrv startAS startWA startWAA rebuildSearchIndex gebTest' | Yes |
| gradleBuildTask | gradle build tasks. | 'startMSSQL dbPrepare test ishUnitTestReport -x=containerClean' | Yes |
| lockImages | pecify whether an image built based on a Git tag should be locked in the Azure container registry. | true |  |

## Important information:

Always refer to the `stable/v1` branch or a tag as the main/master branch is under constant development and breaking changes cannot be excluded. The `stable/v1` represents a branch that is backward compatible and does not contain any breaking changes.