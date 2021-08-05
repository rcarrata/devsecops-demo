## Pipelines Resources

The pipelines and tasks are located in this folder:

[Openshift Pipelines](../bootstrap/roles/ocp4-install-pipelines/templates)

The ArgoCD Apps are located in:

[ArgoCD Resources](../bootstrap/roles/ocp4-config-gitops/templates)

## Pipeline used in the Dev Stage

In the dev environment the following pipeline is used:

* [Dev pipeline](../bootstrap/roles/ocp4-install-pipelines/templates/pipeline-build-dev.yaml.j2)

Check it out!

## Source Clone

- Step for cloning the source code using the workspace designed to persist and share the environment within the whole CICD process

<img align="center" width="750" src="pics/result0.png">

## Dependency Report

<img align="center" width="750" src="pics/result2.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-dependency-report.yaml.j2)

<img align="center" width="750" src="pics/result1_1.png">

## Code Analysis (Sonarqube)

<img align="center" width="750" src="pics/result2.png">

<img align="center" width="750" src="pics/result3.png">

<img align="center" width="750" src="pics/result4.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-mvn.yaml.j2)

## Unit Tests

<img align="center" width="750" src="pics/result5.png">

NOTE: Sometimes there are some random failures that are caused by maven. Rerun the pipeline and check that run OK.

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-mvn.yaml.j2)

## Code Analysis

<img align="center" width="750" src="pics/result6.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-mvn.yaml.j2)

## Release App

<img align="center" width="750" src="pics/result7.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-mvn.yaml.j2)

## Build Image

<img align="center" width="750" src="pics/result8.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-s2i-java-11.yaml.j2)

## Image Scan

<img align="center" width="750" src="pics/result9.png">

- In the logs of this step is there a direct link to the image scan in ACS. Copy and paste it in another tab in order to get more information about the scanned image.

<img align="center" width="750" src="pics/result10.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-image-scan-task.yaml.j2)

## Image Check

* Fail CI due to a policy

<img align="center" width="750" src="pics/result11.png">

* Non Failing (just Warning)

<img align="center" width="750" src="pics/result12.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-rox-image-check.yaml.j2)

## Deployment Check

* Fail CI due to a Deployment Policy

<img align="center" width="750" src="pics/result13.png">

* Non Failing (just Warning)

<img align="center" width="750" src="pics/result14.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-rox-deployment-check.yaml.j2)

## Update Deployment

<img align="center" width="750" src="pics/result15.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-git-update-deployment.yaml.j2)

## Wait Application

<img align="center" width="750" src="pics/result16.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-argo-sync-and-wait.yaml.j2)

## Performance Tests Clone

<img align="center" width="750" src="pics/result17.png">

## Pentesting Tests using Zap Proxy

<img align="center" width="750" src="pics/result18.png">

<img align="center" width="750" src="pics/result18_1.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-zap-proxy.yaml.j2)

## Performance Tests using Gatling

<img align="center" width="750" src="pics/result19.png">

<img align="center" width="750" src="pics/result19_1.png">

[Link to Task](../bootstrap/roles/ocp4-install-pipelines/templates/task-gatling.yaml.j2)

## Slack Notifications

<img align="center" width="750" src="pics/result20_2.png">

<img align="center" width="750" src="pics/result20.png">

<img align="center" width="750" src="pics/result20_1.png">

NOTE: this is a manual tasks. WIP to automated.
