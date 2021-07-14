#!/bin/bash

#### Utils
PRJ_PREFIX="devsecops"
dev_prj="$PRJ_PREFIX-dev"
stage_prj="$PRJ_PREFIX-qa"
prod_prj="$PRJ_PREFIX-prod"
cicd_prj="cicd"

info() {
    sleep 5
    printf "\n# INFO: $@\n"
}

#### Openshift GitOps + Openshift Pipelines
# Apply the Openshift GitOps subscription to install the operator
info "Install Openshift Pipelines and Openshift GitOps operators"
oc apply -k ./gitops-operator
info "Waiting until the operators are installed..."
sleep 70

# Apply the proper permissions to the gitops RBAC
info "Applying proper RBAC permissions"
oc apply -k ./gitops-rbac

# Wait with the job until the CRD of ArgoCD is available
oc wait --for=condition=complete --timeout=600s job/openshift-gitops-crd-wait job/openshift-gitops-crd-wait -n openshift-gitops

# Integrate Dex with Openshift GitOps / ArgoCD
# FIX: Add role:admin to the dex
info "Integrate Dex with Openshift GitOps and apply the proper permissions"
oc patch subscription openshift-gitops-operator -n openshift-operators --type=merge -p='{"spec":{"config":{"env":[{"name":"DISABLE_DEX","Value":"false"}]}}}'
oc patch argocd openshift-gitops -n openshift-gitops --type=merge -p='{"spec":{"dex":{"openShiftOAuth":true},"rbac":{"defaultPolicy":"role:admin","policy":"g, system:cluster-admins, role:admin","scopes":"[groups]"}}}'
oc patch argocd openshift-gitops -n openshift-gitops --type=merge -p='{"spec":{"server":{"insecure":true,"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Redirect","termination":"edge"}}}}}'

#### Openshift Namespaces and RBAC
# Deploy namespaces for CICD and DevSecOps Demo
info "Creating namespaces $cicd_prj, $dev_prj, $stage_prj"
oc apply -k ./ocp-ns

# Apply the OCP RBAC permissions to the ns
info "Configure service account permissions for pipeline"
oc policy add-role-to-user edit system:serviceaccount:$cicd_prj:pipeline -n $dev_prj
oc policy add-role-to-user edit system:serviceaccount:$cicd_prj:pipeline -n $stage_prj
oc policy add-role-to-user system:image-puller system:serviceaccount:$dev_prj:default -n $cicd_prj
oc policy add-role-to-user system:image-puller system:serviceaccount:$stage_prj:default -n $cicd_prj

# TODO: Finish properly the RBAC
#oc apply -k ./ocp-rbac

#### Deploy CICD Infrastructure components
# Deploy Nexus, Gogs and Sonar for CICD pipelines
info "Deploying CI/CD infra to $cicd_prj namespace"
oc apply -k ./infra-cicd
sleep 10

# Config the ArgoCD/Openshift-GitOps Route and credentials
ARGOPASS=$(oc get secret/openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}')
cat infra-config/argocd-env-secret.yaml | ARGOPASS=$ARGOPASS envsubst | oc create -f - -n $cicd_prj
oc apply -f infra-config/argocd-env-cm.yaml -n $cicd_prj # The internal openshift gitops route is always the same

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
sed "s#https://github.com/rcarrata#http://$GOGS_HOSTNAME/gogs#g" ../pipelines/pipeline-build-dev.yaml | oc apply -f - -n $cicd_prj
sed "s#https://github.com/rcarrata#http://$GOGS_HOSTNAME/gogs#g" ../pipelines/pipeline-build-stage.yaml | oc apply -f - -n $cicd_prj

# Deploy the triggers of Openshift Pipelines and in Gogs
info "Apply triggers for the pipelines"
oc apply -f ../triggers -n $cicd_prj
oc create -f infra-config/gogs-init-taskrun.yaml -n $cicd_prj

#### Deploy Openshift GitOps / ArgoCD resources
# TODO:
info "Configure Argo CD Projects and Applications"
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
info "Adding RBAC to the GitOps ns"
oc policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n $dev_prj
oc policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n $stage_prj

#### Deploy ACS into Openshift
info "Deploy ACS into Openshift and Apply Security Policies"
ansible-playbook acs/deploy_only_acs.yaml

#### Create the Registry Integration between ACS and Openshift Internal Registry
# TODO: Automate using Ansible
info "Generate the Registry Integration between ACS and Openshift Internal Registry"

# TODO: make this more simpler
PIPELINE_TOKEN=$(oc get secret -n cicd $(oc get sa -n cicd pipeline -o jsonpath='{.secrets[*]}' | jq -r .name | grep token) -o jsonpath='{.data.token}' | base64 -d)

CENTRAL_ROUTE=$(oc get route -n stackrox central -o jsonpath='{.spec.host}')

curl -X POST -k -H \
'Authorization: Basic YWRtaW46c3RhY2tyb3g=' \
https://$CENTRAL_ROUTE/v1/imageintegrations \
--data @<(cat <<EOF
{
    "name": "OCP Registry",
    "type": "docker",
    "clusters": [],
    "categories": ["REGISTRY"],
    "docker": {
      "endpoint": "image-registry.openshift-image-registry.svc:5000",
      "username": "pipeline",
      "password": "$PIPELINE_TOKEN",
      "insecure": true
    },
    "autogenerated": false,
    "clusterId": "",
    "skipTestIntegration": false
}
EOF
)

info "\n### DevSecOps demo installed OK. Please go ahead and check the status with ./status.sh script\n"
