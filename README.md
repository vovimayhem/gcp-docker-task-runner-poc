# gcp-docker-task-runner-poc
A POC on running docker processes in GKE with pubsub


### Uploading the service account keyfile to the K8 cluster

```
kubectl create secret generic gcp-docker-task-runner-poc-secrets --from-file=./service-account-key.json
```