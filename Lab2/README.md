## 0. Install Docker 

install docker in ubunru ec2 instance 

```
curl -sSL https://get.docker.com/ | sh

sudo usermod -aG docker ubuntu

newgrp docker

```

## 1. Create a container registry for each service

The container registry is going to store the docker container images for both microservices we will deploy:

```
aws ecr create-repository --repository-name characters --region us-east-1
aws ecr create-repository --repository-name locations --region us-east-1
```

You will get output similar to this:

```
{
    "repository": {
        "registryId": "[your account ID]",
        "repositoryName": "characters",
        "repositoryArn": "arn:aws:ecr:us-east-1:[your account ID]:repository/characters",
        "createdAt": 1507564672.0,
        "repositoryUri": "[your account ID].dkr.ecr.us-east-1.amazonaws.com/characters"
    }
}
```

Take note of the `repositoryUri` value in each response, as you will need to use it later.

Now authenticate with your repository so you have permission to push to it:

- Run `aws ecr get-login --no-include-email --region us-east-1`
- You are going to get a massive output starting with `docker login -u AWS -p ...`
- Copy this entire output, paste, and run it in the terminal.

You should see `Login Succeeded`

&nbsp;

&nbsp;

## 2. Build your images and push them to your registries

 First build each service's container image:

```
docker build -t characters services/characters/.
docker build -t locations services/locations/.
```

Run `docker images` and verify that you see following two container images:

```
REPOSITORY                TAG                 IMAGE ID            CREATED              SIZE
locations                 latest              ef276a9ad40a        28 seconds ago       58.8 MB
characters                latest              702e42d339d9        About a minute ago   58.8 MB
```

Then tag the container images and push them to the repository:

```
docker tag characters:latest [your characters repo URI]:v1
docker tag locations:latest [your locations repo URI]:v1
```

Example:

```
docker tag characters:latest 209640446841.dkr.ecr.us-east-1.amazonaws.com/characters:v1
docker tag locations:latest 209640446841.dkr.ecr.us-east-1.amazonaws.com/locations:v1
```

Finally push the tagged images:

```
docker push [your characters repo URI]:v1
docker push [your locations repo URI]:v1
```

Example:

```
docker push 209640446841.dkr.ecr.us-east-1.amazonaws.com/characters:v1
docker push 209640446841.dkr.ecr.us-east-1.amazonaws.com/locations:v1
```

&nbsp;

&nbsp;

## 3. Modify deployment specification files

Modify the files at `recipes/locations.yml` and `recipes/characters.yml` to have the docker image URL from the last step (including the image tag).

Choose one of the following command line file editors to use:

- `nano recipes/locations.yml` (Easier to use editor. Just edit file and then press Control + O to write the file to disk, and Control + X to exit.)
- `vi recipes/locations.yml` (Advanced editor. Press `a` to enter insert mode, edit the file, then press Escape to exit edit mode. Type `:wq` to write the file to disk and quit.)

Whichever editor you use you need to change the `image` property to the URI of your docker image as shown below:

```
spec:
  containers:
  - name: locations
    image: 209640446841.dkr.ecr.us-east-1.amazonaws.com/locations:v1
    ports:
    - containerPort: 8081
```

Repeat this for both the locations deployment definition file and the characters deployment definition, putting the appropriate image URL in each file.

&nbsp;

&nbsp;

## 4. Apply the deployments to the Kubernetes cluster

Run the command to apply these two deployments to your Kubernetes cluster:

```
kubectl apply -f recipes/locations.yml
kubectl apply -f recipes/characters.yml
```

Then verify that the deployments have applied:

```
kubectl get deployments
```

You should see output similar to this:

```
NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
characters-deployment   2         2         2            0           7s
locations-deployment    2         2         2            2           7s
```

We also just created services for the pods, which serve as proxies that
will allow us to send traffic to the underlying pods wherever they may
be:

```
kubectl get services
```

You should see output similar to this:

```
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
characters-service   ClusterIP   100.64.79.235   <none>        8081/TCP   41s
kubernetes           ClusterIP   100.64.0.1      <none>        443/TCP    3h
locations-service    ClusterIP   100.64.78.26    <none>        8081/TCP   41s
```

&nbsp;

&nbsp;

## 5. Create a load balancer in front of your pods

Now that the pods are running on the cluster, we still need a way for traffic from the public to reach them. In order to do this we will build an Nginx container that can route traffic to the containers, and then expose the Nginx to the public using a load balancer ingress.

__Build and push the Nginx image:__

```
aws ecr create-repository --repository-name nginx-router --region us-east-1
docker build -t nginx-router services/nginx/.
docker tag nginx-router:latest <your repo url>:v1
docker push <your repo url>:v1
```

__Modify the Nginx deployment file:__

Use the editor of your choice to edit the file at `recipes/nginx.yml` to have the URL of the Nginx image, exactly as you did in step #9 for the `locations` and `characters` services.

__Apply the deployment:__

```
kubectl apply -f recipes/nginx.yml
```

__Get the details of the load balancer:__

```
kubectl describe service nginx-router
```

You will see output like:

```
[ec2-user@ip-10-0-0-46 code]$ kubectl describe service nginx-router
Name:                     nginx-router
Namespace:                default
Labels:                   <none>
Annotations:              kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"nginx-router","namespace":"default"},"spec":{"ports":[{"port":80,"targetPort":...
Selector:                 app=nginx-router
Type:                     LoadBalancer
IP:                       100.69.165.186
LoadBalancer Ingress:     aa788cc64fc9911e7b8820e801320750-1559002290.us-east-1.elb.amazonaws.com
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31419/TCP
Endpoints:
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  1m    service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   1m    service-controller  Ensured load balancer
```

Make a note of the value listed for `LoadBalancer Ingress`. This is the DNS name that the application will be available to the public as.

&nbsp;

&nbsp;

## 6. Test the service

Make an HTTP request to the service on the DNS name from the last step. Note that it make take a minute or so before the load balancer ingress actually starts accepting traffic.

```
curl http://aa788cc64fc9911e7b8820e801320750-1559002290.us-east-1.elb.amazonaws.com/api/characters
curl http://aa788cc64fc9911e7b8820e801320750-1559002290.us-east-1.elb.amazonaws.com/api/locations
```

These two paths are each being served by their own container deployment in the Kubernetes cluster.

&nbsp;

&nbsp;

## 7. Scale a service

There are three pieces to this Kubernetes architecture that we can scale:

- The NGINX router deployment
- The `characters` deployment
- The `locations` deployment

Scaling a deployment is easy with the following command:

```
kubectl scale --replicas=3 deployments/characters-deployment
```

This will increase the number of `characters` containers to three, which you can verify using `kubectl get pods`:

```
characters-deployment-6c6846f98-m54bn   1/1       Running   0          38m
characters-deployment-6c6846f98-p4r6x   1/1       Running   0          38m
characters-deployment-6c6846f98-xcmld   1/1       Running   0          39s
locations-deployment-76c6657869-9slws   1/1       Running   0          40m
locations-deployment-76c6657869-zbkzz   1/1       Running   0          40m
nginx-router-d4dd9c94c-jxtfw            1/1       Running   0          15m
nginx-router-d4dd9c94c-wt7b5            1/1       Running   0          15m
```

You will now see three pods with the `characters` name, alongside the existing two for `locations` and `nginx-router`.

&nbsp;

## 8. Test API

&nbsp;

The external HTTP interface of the API has a basic spec:

- `GET /api/characters` - A list of all characters
- `GET /api/characters/:id` - Fetch a specific character by ID
- `GET /api/locations` - A list of all locations
- `GET /api/locations/:id` - Fetch a specific location by ID
- `GET /api/characters/by-location/:locationId` - Fetch all characters at a specific location
- `GET /api/characters/by-gender/:gender` - Fetch all characters of specified gender
- `GET /api/characters/by-species/:species` - Fetch all characters of specified species
- `GET /api/characters/by-occupation/:occupation` - Fetch all characters that have specified occupation

&nbsp;

## 9. Delete ECR
delete the ECR repositories that you created to store the microservice docker images:

```
aws ecr delete-repository --repository-name characters --force --region us-east-1
aws ecr delete-repository --repository-name locations --force --region us-east-1
aws ecr delete-repository --repository-name nginx-router --force --region us-east-1
```
