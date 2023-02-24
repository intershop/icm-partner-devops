
# icm-partner-devops

## Overview

Repository *icm-partner-devops* provides an *Azure DevOps Pipeline* template, which can be used by ICM projects, that are managed inside *Intershops Commerce Platform*. The template should be used as is. Any custom additions should be made outside of the template.

## How to use the pipeline template

Add a file `azure-pipelines.yml` to the root-directory of your project with following content. After that, in Azure DevOps a new pipeline has to be created from this file.


```yaml

  variables:
  # Library icm11-build-configuration is provided by Intershops DevOps Environment. It provides
  # the following variables:
  #  - BUILD_AGENT_POOL:                  name of the build agent pool
  #  - REPO_SERVICE_CONNECTION:           service connection to the customer ACR
  #  - REPO_PATH:                         host name and path of the customer ACR
  #  - INTERSHOP_REPO_SERVICE_CONNECTION: service connection to the Intershop container registry
  #  - INTERSHOP_REPO_PATH:               host name and path of the Intershop container registry
  #  - ARTIFACT_FEED:                     name of the icm artifacts feed
  - group: icm11-build-configuration
  # 
  - name:  isVersion
    value: $[startsWith(variables['Build.SourceBranch'], 'refs/tags/version')]

  # Create a repository resource to the Github repo, that is providing the centrally managed CI job.
  resources:
    repositories:
      - repository: icm-partner-devops
        type: github
        endpoint: INTERSHOP_GITHUB
        name: intershop/icm-partner-devops
        ref: main
      - repository: ci-configuration
        type: git
        name: <projectName>-ci-configuration
        ref: master

  # Define, when the pipeline should be triggered.
  # See https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/azure-repos-git?view=azure-devops&tabs=yaml#ci-triggers
  trigger:
    branches:
        include:
        - master
        - develop
        - release/*
        - feature/*
        - hotfix/*
    tags:
        include:
        - version/*

  # Run CI job. Additional custom stages/jobs might be added, see example below.
  stages:
  - stage: CI
    jobs:
      - template: ci-job-template.yml@icm-partner-devops
        parameters:
            # These parameters must not be changed. They are used to pass variables to the ci-job templaten, which
            # are defined by library icm11-build-configuration.
            agentPool:                          $(BUILD_AGENT_POOL)
            dockerRepoICMServiceConnection:     $(INTERSHOP_REPO_SERVICE_CONNECTION)
            dockerRepoICM:                      $(INTERSHOP_REPO_PATH)
            acrServiceConnection:               $(REPO_SERVICE_CONNECTION)
            acr:                                $(REPO_PATH)
            artifactsFeed:                      $(ARTIFACT_FEED)
		
```