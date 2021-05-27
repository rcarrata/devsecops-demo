
# Add the tasks into the demo
oc apply -k tasks

# Add the argocd apps into the demo
oc apply -k pipelines

# Add the argoapps for dev, stage and prod
oc apply -k argocd

