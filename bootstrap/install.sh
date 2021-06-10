#!/bin/bash

#### Utils
PRJ_PREFIX="devsecops"
dev_prj="$PRJ_PREFIX-dev"
stage_prj="$PRJ_PREFIX-qa"
prod_prj="$PRJ_PREFIX-prod"
cicd_prj="cicd"

info() {
    printf "\n# INFO: $@\n"
}

#### Openshift GitOps + Openshift Pipelines
# Apply the Openshift GitOps subscription to install the operator
oc apply -k ./gitops-operator
sleep 30

# Apply the proper permissions to the gitops RBAC
oc apply -k ./gitops-rbac

# Wait with the job until the CRD of ArgoCD is available
oc wait --for=condition=complete --timeout=600s job/openshift-gitops-crd-wait job/openshift-gitops-crd-wait -n openshift-gitops

# Integrate Dex with Openshift GitOps / ArgoCD
oc patch subscription openshift-gitops-operator -n openshift-operators --type=merge -p='{"spec":{"config":{"env":[{"name":"DISABLE_DEX","Value":"false"}]}}}'
oc patch argocd openshift-gitops -n openshift-gitops --type=merge -p='{"spec":{"dex":{"openShiftOAuth":true},"rbac":{"defaultPolicy":"role:readonly","policy":"g, system:cluster-admins, role:admin","scopes":"[groups]"}}}'
oc patch argocd openshift-gitops -n openshift-gitops --type=merge -p='{"spec":{"server":{"insecure":true,"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Redirect","termination":"edge"}}}}}'

#### Openshift Namespaces and RBAC
# Deploy namespaces for CICD and DevSecOps Demo
info "Creating namespaces $cicd_prj, $dev_prj, $stage_prj"
oc apply -k ./ocp-ns

# Apply the OCP RBAC permissions to the ns
info "Configure service account permissions for pipeline"
oc policy add-role-to-user edit system:serviceaccount:$cicd_prj:pipeline -n $dev_prj
oc policy add-role-to-user edit system:serviceaccount:$cicd_prj:pipeline -n $stage_prj
oc policy add-role-to-user edit system:serviceaccount:$cicd_prj:pipeline -n $prod_prj
oc policy add-role-to-user system:image-puller system:serviceaccount:$dev_prj:default -n $cicd_prj
oc policy add-role-to-user system:image-puller system:serviceaccount:$stage_prj:default -n $cicd_prj
oc policy add-role-to-user system:image-puller system:serviceaccount:$prod_prj:default -n $cicd_prj

# TODO:
#oc apply -k ./ocp-rbac 

#### Deploy CICD Infrastructure components
# Deploy Nexus, Gogs and Sonar for CICD pipelines
info "Deploying CI/CD infra to $cicd_prj namespace"
oc apply -k ./infra-cicd
sleep 10

# Initialize the Git Repository in Gogs
# TODO: Convert them in Kustomize style
info "Initiatlizing git repository in Gogs and configuring webhooks"
GOGS_HOSTNAME=$(oc get route gogs -o template --template='{{.spec.host}}' -n $cicd_prj)
sed "s/@HOSTNAME/$GOGS_HOSTNAME/g" infra-config/gogs-configmap.yaml | oc create -f - -n $cicd_prj
oc rollout status deployment/gogs -n $cicd_prj

# Apply the github secret (only for GH)
# ./github-creds-gen/add-github-credentials-ask-for-pass.sh cicd rcarratala

#### Deploy Openshift Pipelines resources
info "Deploying pipeline and tasks to $cicd_prj namespace"
oc apply -f ../tasks -n $cicd_prj
oc apply -f ../pipelines/pipeline-build-pvc.yaml -n $cicd_prj
sed "s#https://github.com/siamaksade#http://$GOGS_HOSTNAME/gogs#g" ../pipelines/pipeline-build.yaml | oc apply -f - -n $cicd_prj

# Deploy the triggers of Openshift Pipelines and in Gogs
oc apply -f ../triggers -n $cicd_prj
oc create -f infra-config/gogs-init-taskrun.yaml -n $cicd_prj

#### Deploy Openshift GitOps / ArgoCD resources
# TODO: 
  info "Configure Argo CD"
cat << EOF > ../argocd/tmp-argocd-app-patch.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-spring-petclinic
spec:
  destination:
    namespace: $dev_prj
  source:
    repoURL: http://$GOGS_HOSTNAME/gogs/spring-petclinic-config
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stage-spring-petclinic
spec:
  destination:
    namespace: $stage_prj
  source:
    repoURL: http://$GOGS_HOSTNAME/gogs/spring-petclinic-config
EOF

oc apply -k ../argocd -n openshift-gitops

# Check if this rbac is still needed
oc policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n $dev_prj
oc policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n $stage_prj

#### Deploy ACS into Openshift
ansible-playbook acs deploy_only_acs.yaml

PIPELINE_TOKEN=$(oc get secret $(oc get sa pipeline -o jsonpath='{.imagePullSecrets[].name}') -o jsonpath='{.metadata.annotations.openshift\.io\/token-secret\.value}')

#TODO: Automate the creation of the Image Registry Token
# /main/apidocs#operation/PostImageIntegration
# Platform Configuration -> Integrations -> Generic Docker Registry -> New Integration 

# Integration Name: OCP Registry
# Types: Registry
# Endpoint: image-registry.openshift-image-registry.svc:5000
# Username: pipeline
# Password: "TOKEN"
# Disable TLS Certificate Validation (Insecure): Yes