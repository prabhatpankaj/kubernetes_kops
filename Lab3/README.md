# How To Install and Configure Kubernete Dashboard

* First run the yaml configuration of kops dashboard add-on:

```
wget https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.10.1.yaml
kubectl create -f v1.10.1.yaml

```

* Go to URL that got created:To get the URL:

```
kubectl cluster-info | grep master
```

Example URL:
https://api-yoururl.amazonaws.com

* Open url 

```
https://api-yoururl.amazonaws.com/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview?namespace=default

```
* To create a service account with access to default namespace

```
kubectl create serviceaccount dashboard -n default

```  
  
* To create a cluster role bind. Connecting service account and cluster level access

```
kubectl create clusterrolebinding dashboard-admin -n default \
--clusterrole=cluster-admin \
--serviceaccount=default:dashboard

```

* To get the login token that you will be asked on the URL:

```
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode 

```
* Default login credentials you can get by using following kops command in terminal:
Username: admin
Password: (using command)

```
kops get secrets kube --type secret -oplaintext 

```
