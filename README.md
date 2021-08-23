# kong-hydra
A kubernetes-based setup to create an environment with [ory/hydra](https://github.com/ory/hydra) as the OIDC provider and [kong](https://konghq.com/kong/) as the gateway and ingress controller that validates access token for each request.

## Step-by-step kubernetes commands to spawn the required services

> Create a config-map for hydra related configurations

`kubectl apply -f hydra/hydra-configmap.yaml`

> Create relevant secrets for hydra to work (such as db password etc)
> (NOTE: name is still hydradb for secrets. TODO)

`kubectl apply -f hydra/hydra-secret.yaml`

> Start the database that hydra can connect to (note that for non-minikube environements, you would just create a database resource and pass that in as a volume)

`kubectl apply -f hydra/hydradb-deployment.yaml`

> Run a job that runs the migration script for the database so that hydra works as expected

`kubectl apply -f hydra/hydradb-migrations.yaml`

> Start a pod with ory hydra

`kubectl apply -f hydra/hydra-deployment.yaml`


>// Since minikube docker context is inside its own container, we need to allow docker images that we've built to be accessible inside minikube's own container.
>// NOTE: if in minikube then execute in the shell where you plan to build the docker image, and then apply the kong-deployment.yaml file)
>// NOTE2: this has to be done on every shell

`eval $(minikube docker-env)`
> For windows this would be

`minikube docker-env | Invoke-Expression`

> Build kong image with kong-oidc plugin and relevant configs
> (This is assuming that the terminal context is inside the project director)
> Don't forget the '`.`' at the end

`docker build -t kong-dbless .`

> Create a pod with kong-gateway
> NOTE: for non-minikube environments, remember to change the ImagePullPolicy from Never to Always and give a valid repository URL

`kubectl apply -f kong-oidc-deployment.yaml`

> Create the OIDC plugin for kubernetes

`kubectl apply -f kong-oidc-plugin.yaml`

> Create an example service with the kubernetes OIDC plugin

`kubectl apply -f kong-echo-withplugin.yaml`

> Create a UI that can help control and manage kong gateway (this is more useful incase of kong with db)

`kubectl apply -f konga/konga-deployment.yaml`

> Create an ingress controller so that the paths can be controller appropriately. The OIDC plugin can also be enabled for services at ingress instead of kubernetes service level as well
> For minikube remember to enable ingress addon first via `minikube addons enable ingress`

`kubectl apply -f kong-demo-ingress.yaml`

To access your environment outside the minikube environment, allow this via

`minikube service -n kong kong-proxy`
(choose the 127.0.0.1:<firstport>)

To generate a token you can use the given curlService pod (or use the POSTMAN script which I'll add later)
> Create a Token
```
// Start a pod in the kubernetes network to test if hydra is working as intended
kubectl apply -f hydra/curl-server.yaml

// Exec into the curl service pod
// You can get <pod_name_of_curl_server> by `kubectl get po` and taking the name of the one for the curl service
kubectl exec -it <pod_name_of_curl_server> /bin/bash

// This should be run in bash from inside the curlService pod
// This creates the OIDC client for which the token will be created for
curl --location --request POST 'http://hydra-service:9001/clients' \
--header 'Content-Type: application/json' \
--data-raw '{
  "client_id": "someconsumer",
  "client_name": "consumerName",
  "client_secret": "somesecret",
  "client_uri":"example.com",
  "owner":"example.com",
  "grant_types": [
    "client_credentials"
  ],
  "scope":"merchant offline_access offline openid",
  "redirect_uris": [
    "http://example.com"
  ],
  "response_types": [
    "token",
    "code"
  ],
  "token_endpoint_auth_method":"client_secret_post"
}'

//Get a valid token
curl --location --request POST 'http://hydra-service:9000/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id=someconsumer' \
--data-urlencode 'client_secret=somesecret' \
--data-urlencode 'scope=offline_access offline openid merchant'
```

You can now use this token to call the example echo service via
```curl
curl -i --location --request GET 'http://127.0.0.1:<port_number_from_minikube_exposed_service>/foo' --header 'Authorization: Bearer <access_token>'
```