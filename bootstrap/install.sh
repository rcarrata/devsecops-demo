
# Apply the Openshift GitOps subscription to install the operator
oc apply -k ./gitops-operator

# Apply the proper permissions to the gitops RBAC
oc apply -k ./gitops-rbac

# Wait with the job until the CRD of ArgoCD is available
oc wait --for=condition=complete --timeout=600s job/openshift-gitops-crd-wait job/openshift-gitops-crd-wait -n openshift-gitops

oc apply -k ./ocp-ns

# Add the Service Account in the system:image-puller
oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n cicd-dev
oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n cicd-stage
oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n cicd-prod
oc policy add-role-to-user system:image-puller system:serviceaccount:cicd-dev:default -n cicd
oc policy add-role-to-user system:image-puller system:serviceaccount:cicd-stage:default -n cicd
oc policy add-role-to-user system:image-puller system:serviceaccount:cicd-prod:default -n cicd

oc apply -k ./ocp-rbac

# Deploy the infra for CICD pipelines
oc apply -k ./infra-cicd

# Apply the github secret
 ./add-github-credentials-ask-for-pass.sh cicd rcarratala