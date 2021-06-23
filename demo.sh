
# Add the tasks into the demo
printf "\n#### Starting DevSecOps Demo! \n"
printf "\n## Executing Dev Pipeline... ##\n"
oc create -f pipelinerun/pipeline-build-dev-run.yaml -n cicd
OCP_ROUTE=$(oc whoami --show-console)
printf "$OCP_ROUTE/pipelines/ns/cicd/pipeline-runs"
printf "\n"

printf "\n## GOGS Server - Username/Password: gogs/gogs ##\n"
GOGS=$(oc get route -n cicd gogs -o jsonpath='{.spec.host}')
printf "https://$GOGS"
printf "\n"

printf "\n## Nexus Server - Username/Password: admin/admin123 ##\n"
NEXUS=$(oc get route -n cicd nexus -o jsonpath='{.spec.host}')
printf "https://$NEXUS"
printf "\n"

printf "\n## Sonarqube Server - Username/Password: admin/admin ##\n"
SONARQUBE=$(oc get route -n cicd sonarqube -o jsonpath='{.spec.host}')
printf "https://$SONARQUBE"
printf "\n"

printf "\n## Reports Server - Username/Password: reports/reports ##\n"
REPORTS=$(oc get route -n cicd reports-repo -o jsonpath='{.spec.host}')
printf "https://$REPORTS"
printf "\n"

printf "\n## ACS/Stackrox Server - Username/Password: admin/stackrox ##\n"
ACS=$(oc get route -n stackrox central -o jsonpath='{.spec.host}')
printf "https://$ACS"
printf "\n"

printf "\n## ArgoCD Server - Username/Password: admin/[DEX] ##\n"
ARGO=$(oc get route -n openshift-gitops openshift-gitops-server -o jsonpath='{.spec.host}')
printf "https://$ARGO"
printf "\n"