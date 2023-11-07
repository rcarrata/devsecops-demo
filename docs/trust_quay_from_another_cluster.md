## Add the private quay registry as a trusted registry in a secondary cluster
### Prerequisites
- Have a cluster up and running with this demo setup including the extend.sh portion (with local quay)
- Have a secondary cluster up and running where you want to also deploy images from the above quay
- Run the following export commands to make the below scripts easier to run:
  ```bash
  export QUAY_URL=<quay url>
  export QUAY_USER=<quay user>
  export QUAY_PASS=<quay password>
  export LOCAL_NS=<local namespace>
  ```
### Obtain default router certificate from primary cluster
```bash
oc get secret -n openshift-ingress router-certs-default -o jsonpath="{.data['tls\.crt']}" | base64 -d > tls.key
```
### Add tls.key to the secondary cluster as a trusted CA
Make sure to login to the secondary cluster before running these commands, and make sure you have the tls.key
from the above step in this folder.
```bash
oc create configmap registry-cas -n openshift-config \
--from-file=${QUAY_URL}=tls.key
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge
```

### Setup login credentials for the Service Account in the secondary cluster
This example is going to use the default service account
```bash
oc create secret docker-registry quay-robot-secret --docker-server=$QUAY_URL --docker-username=$QUAY_USER --docker-password=$QUAY_PASS -n $LOCAL_NS
oc secrets link default quay-robot-secret --for=pull,mount -n $LOCAL_NS
```
