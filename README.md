
# icm-partner-devops

## Overview

Repository *icm-partner-devops* provides an *Azure DevOps Pipeline* template, which can be used by ICM projects, that are managed inside *Intershops Commerce Platform*. The template should be used as is. Any custom additions should be made outside of the template.

## How to use the pipeline template

Rename the `azure-pipelines.yml.tmpl` file to `azure-pipelines.yml` and add it to the root-directory of your icm-customization repository. After that, in Azure DevOps a new pipeline has to be created from this file.

## Important information:

Always refer to the `stable/v1` branch or a tag as the main/master branch is under constant development and breaking changes cannot be excluded. The `stable/v1` represents a branch that is backward compatible and does not contain any breaking changes.