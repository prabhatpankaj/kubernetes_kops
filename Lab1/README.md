
```
kubectl create -f nginx_deploy.yaml

kubectl create -f nginx_svc.yaml

kubectl create -f kube_chat_deploy_and_svc.yaml

kubectl delete svc nginx-elb

kubectl delete deploy nginx

```