# test nginx load balencer 
```
kubectl create -f nginx_deploy.yaml

kubectl create -f nginx_svc.yaml

```
# delete nginx load balencer

```
kubectl delete svc nginx-elb

kubectl delete deploy nginx

```
# create chatapp with load balencer
```
kubectl create -f kube_chat_deploy_and_svc.yaml

```
