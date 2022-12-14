    cd '/mnt/c/kubectl-deployments/november-2021/'

### set minikube docker environment to host machine
<!-- if in minikube then execute in the shell where you plan to build the docker image, and then apply the kong-deployment.yaml file
this has to be done on every shell -->
    open wsl - ubuntu
    eval $(minikube docker-env)
    minikube docker-env | Invoke-Expression
    minikube addons enable ingress
    minikube service kong-proxy
    minikube tunnel --alsologtostderr

<!-- Incase ingress addon command has issues try -->
<!-- You shouldn't need this in a normal case -->
    minikube tunnel

### Fresh start
    minikube delete
    minikube start

### configs + secrets
    kubectl apply -f hydra/hydra-configmap.yaml
    kubectl apply -f hydra/hydra-secret.yaml

### DB for hydra
    kubectl apply -f hydra/hydradb-deployment.yaml
### Run migrations to create tables for hydra in the postgres database
    kubectl apply -f hydra/hydradb-migrations.yaml
    kubectl apply -f hydra/hydra-deployment.yaml
<!-- kubectl apply -f hydra/curl-server.yaml -->
    

### Build kong image with kong-oidc plugin
<!-- docker build -t kong-dbless . -->
    docker build -t kong-dbless kong-oidc/

    kubectl apply -f kong-oidc/kong-oidc-deployment.yaml

### Spawn a protected service
    kubectl apply -f kong-oidc/kong-oidc-plugin.yaml
    kubectl apply -f kong-oidc/kong-echo-withplugin.yaml

### Apply routing rules to the kong ingress for the protected service
    kubectl apply -f kong-oidc/kong-demo-ingress.yaml

### Expose this for minikube
    minikube service kong-proxy
    minikube tunnel --alsologtostderr

### Jaegar tracing
    kubectl apply -f jaegar/jaeger-all-in-one.yaml
<!-- edit hydra/hydra-deployment.yaml and kong-oidc/kong-demo-ingress.yaml -->
    kubectl apply -f hydra/hydra-deployment.yaml
    kubectl apply -f kong-oidc/kong-demo-ingress.yaml


### delete
    kubectl delete -f hydra/hydra-configmap.yaml
    kubectl delete -f hydra/hydra-secret.yaml
    kubectl delete -f hydra/hydradb-deployment.yaml
    kubectl delete -f hydra/hydradb-migrations.yaml
    kubectl delete -f hydra/hydra-deployment.yaml
<!-- delete the plugin, curl server and ingress-controller before as they are tied to kong -->
    kubectl delete -f kong-oidc/kong-oidc-plugin.yaml
    kubectl delete -f kong-oidc/kong-echo-withplugin.yaml
    kubectl delete -f kong-oidc/kong-demo-ingress.yaml
<!-- delete kong itself after its dependancies are killed -->
    kubectl delete -f kong-oidc/kong-oidc-deployment.yaml
<!-- delete jaegar -->
    kubectl delete -f jaegar/jaeger-all-in-one.yaml
<!-- delete konga -->
    kubectl delete -f konga/konga-deployment.yaml
