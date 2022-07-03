!/bin/bash

echo "## Verify Starting Script"

pipeline_label="${1:-petclinic-build-dev}"
pipeline_namespace="${2:-s2i-python-cosign}"
cosign_secret_name="${3:-signing-secrets}"
writable_space="${3:-/test}"
tekton_secret_namespace="${4:-openshift-pipelines}"

#Can get Secrets Directly but will depend on Kubernetes Permission
# if [ ! -f ${writable_space}/cosign.key ]
# then
#    oc get secret/${cosign_secret_name} -n ${tekton_secret_namespace} -o jsonpath='{.data.cosign\.key}' | base64 -d > ${writable_space}/cosign.key
# fi

# if [ ! -f ${writable_space}/cosign.password ]
# then
#    oc get secret/${cosign_secret_name} -n ${tekton_secret_namespace} -o jsonpath='{.data.cosign\.password}' | base64 -d > ${writable_space}/cosign.password
# fi

# if [ ! -f ${writable_space}/cosign.pub ]
# then
#    oc get secret/${cosign_secret_name} -n ${tekton_secret_namespace} -o jsonpath='{.data.cosign\.pub}' | base64 -d > ${writable_space}/cosign.pub


printf "Will attempt to Verify Task Runs\n"
for taskrun in $(oc get taskrun -n ${pipeline_namespace} -o name)
do
  printf "\n"
  printf "Start Verification TaskRun ${taskrun}\n"
  TASKRUN_UID=$(oc get $taskrun -n ${pipeline_namespace} -o jsonpath='{.metadata.uid}')
  oc get $taskrun -n ${pipeline_namespace} -o jsonpath="{.metadata.annotations.chains\.tekton\.dev/signature-taskrun-$TASKRUN_UID}" > ${writable_space}/signature
  oc get $taskrun -n ${pipeline_namespace} -o jsonpath="{.metadata.annotations.chains\.tekton\.dev/payload-taskrun-$TASKRUN_UID}" | base64 -d > ${writable_space}/payload
  cosign verify-blob --key k8s://tekton-chains/${cosign_secret_name} --signature ${writable_space}/signature ${writable_space}/payload
  if [ "$?" -eq 0 ]
  then
    printf "Verified TaskRun ${taskrun}\n"
    printf "\n"
  else
    printf "Could not verify TaskRun ${taskrun}"
    printf "\n"
  fi
done