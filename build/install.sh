#!/bin/bash
# Make sure you are logged into docker registry incase your are pushing images with variable PUSHDOCKER=yes
# Set IMAGEPULLPOLICY to Never if you want to use local build images - Work in progress
#Ubuntu version used : ami-0567e0d2b4b2169ae

#Ref: https://gist.github.com/jonsuh/3c89c004888dfc7352be

RUNCOLOR='\033[1;34m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

export PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

export PUBLIC_DNS=`curl http://169.254.169.254/latest/meta-data/public-hostname`

export SLEEPTIME=1

sleep $SLEEPTIME

export DATE=$(date "+%Y-%m-%d-%H-%M-%S")

export BASEDIR=$PWD

# If you want to push to repo then make sure PUSHDOCKER set to yes and IMAGEPULLPOLICY set to Always
# You need to docker login to push to docker hub. Initial run of script will fail, but do docker login and run script again 
# or install docker with apt and do docker login . Additional checks not enabled in this version. But feature request possible :) 

# If you are using local build images then make sure variable PUSHKIND set to yes and IMAGEPULLPOLICY to Never
export PUSHKIND=yes

# Set CREATECLUSTER to yes to create cluster. Still script check for existance of cluster
export CREATECLUSTER=yes

export CLUSTERNAME=raylytic

export IMAGEPULLPOLICY=Never

export MASTERREPONAME=ajais

echo "${RUNCOLOR}Setting up kind${NOCOLOR}"

sleep $SLEEPTIME

if [ "$(which kind)" = "/usr/bin/kind" ];
then
    echo "${GREEN}kind is already available${NOCOLOR}"
else
    curl -Lo $BASEDIR/kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
    chmod +x $BASEDIR/kind
    cp $BASEDIR/kind /usr/bin/
fi

echo "${RUNCOLOR}Setting up kubectl${NOCOLOR}"
sleep $SLEEPTIME

if [ "$(which kubectl)" = "/usr/bin/kubectl" ];
then
    echo "${GREEN}kubectl is already available${NOCOLOR}"
else
    curl -Lo $BASEDIR/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod 755 $BASEDIR/kubectl
    cp $BASEDIR/kubectl /usr/bin/
fi

echo "${RUNCOLOR}Setting up Docker${NOCOLOR}"

sleep $SLEEPTIME

apt update
apt install -y docker.io

#Ref: https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster
#kubectl port-forward --address 0.0.0.0 service/service_name 30000:80

echo "${RUNCOLOR}Building kind Cluster conf file${NOCOLOR}"

sleep $SLEEPTIME

cat <<EOF > $BASEDIR/kind-config.yml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTERNAME
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

CLUSTERS=$(kind get clusters| grep raylytic)

if [ -z "$CLUSTERS" ]
then
      echo "${RUNCOLOR}No Clusters found${NOCOLOR}"
      CREATECLUSTER=yes
else
      echo "${RUNCOLOR}Cluster found${NOCOLOR}"
      CREATECLUSTER=no
fi


if [ $CREATECLUSTER = "no" ] ; then
   echo "No Cluster creation"
else
   clustersstatus=$(kind get clusters | grep $CLUSTERNAME)
   echo "${RUNCOLOR}Creating Cluster $CLUSTERNAME ${NOCOLOR}"
   sleep $SLEEPTIME
   kind create cluster --config=$BASEDIR/kind-config.yml
   kubectl apply -f https://github.com/datawire/ambassador-operator/releases/latest/download/ambassador-operator-crds.yaml
   kubectl apply -n ambassador -f https://github.com/datawire/ambassador-operator/releases/latest/download/ambassador-operator-kind.yaml
   kubectl wait --timeout=180s -n ambassador --for=condition=deployed ambassadorinstallations/ambassador
   echo "Cluster creation completed"
fi

#Ref: https://www.digitalocean.com/community/tutorials/how-to-build-and-deploy-a-flask-application-using-docker-on-ubuntu-18-04
#Ref: https://levelup.gitconnected.com/simple-api-using-flask-bc1b7486af88
#Ref: https://www.magalix.com/blog/implemeting-a-reverse-proxy-server-in-kubernetes-using-the-sidecar-pattern
echo "${RUNCOLOR}FHIR DB Deployment${NOCOLOR}"

sleep $SLEEPTIME


cat <<EOF > fhir-server-db.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: fhir-server-db
  name: fhir-server-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: backend
    spec:
      containers:
      - image: postgres
        name: fhir-server-db
        env:
        - name: POSTGRES_PASSWORD
          value: "admin1234"
        - name: POSTGRES_USER
          value: "admin"
        - name: POSTGRES_DB
          value: "hapi"
        imagePullPolicy: Always
        resources: {}
status: {}
EOF

cat <<EOF > fhir-server-db-svc.yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: fhir-server-db
  name: fhir-server-db
spec:
  ports:
  - port: 5432
    protocol: TCP
    targetPort: 5432
  selector:
    app: fhir-server-db
status:
  loadBalancer: {}
EOF

cat <<EOF > fhir-server.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: fhir-server
  name: fhir-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fhir-server
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: fhir-server
    spec:
      containers:
      - image: hapi-fhir/hapi-fhir-jpaserver-starter
        name: frontend
        env:
        - name: profiles.active
          value: "r4"
        - name: fhir_version
          value: "R4"
        - name: spring.datasource.url
          value: "jdbc:postgresql://fhir-server-db:5432/hapi"
        - name: spring.datasource.username
          value: "admin"
        - name: spring.datasource.password
          value: "admin1234"
        - name: spring.datasource.driverClassName
          value: "org.postgresql.org.postgresql.Driver"
        imagePullPolicy: $IMAGEPULLPOLICY
        resources: {}
status: {}
EOF

cat <<EOF > fhir-server-svc.yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: fhir-server
  name: fhir-server
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: fhir-server
status:
  loadBalancer: {}
EOF

cat <<EOF > frontend-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: ambassador
  name: frontend-ingress
  namespace: default
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: fhir-server
            port:
              number: 80
        path: "/"
        pathType: Prefix
EOF

echo "${RUNCOLOR}Stage Docker push${NOCOLOR}"
sleep $SLEEPTIME

#Ref: https://iximiuz.com/en/posts/kubernetes-kind-load-docker-image/
if [ $PUSHKIND = "no" ]
then
   echo "No Image Push to KIND"
else
   echo "${GREEN}Pushing Image to KIND${NOCOLOR}"
   echo "${GREEN}Image name hapi-fhir/hapi-fhir-jpaserver-starter"
   kind load docker-image hapi-fhir/hapi-fhir-jpaserver-starter --name $CLUSTERNAME
fi

sleep $SLEEPTIME

export DEPLOYMENTNAME=fhir-server-db

deploy=$(kubectl get deployment | grep fhir-server-db)
if [ $? != 0 ]; then
    echo "No deployments"
    kubectl apply -f fhir-server-db.yaml
    kubectl apply -f fhir-server-db-svc.yaml
else
    echo "$DEPLOYMENTNAME exists, updating image"
    kubectl apply -f fhir-server-db.yaml
    kubectl apply -f fhir-server-db-svc.yaml
fi

export DEPLOYMENTNAME=fhir-server

echo "${RUNCOLOR}Installing/updating Deployment fhir-server"

sleep $SLEEPTIME


deploy=$(kubectl get deployment | grep $DEPLOYMENTNAME)
if [ $? != 0 ]; then
    echo "No deployments"
    kubectl apply -f fhir-server.yaml
    kubectl apply -f fhir-server-svc.yaml
    kubectl apply -f frontend-ingress.yaml
else
    echo "$DEPLOYMENTNAME exists, updating image"
    kubectl apply -f fhir-server.yaml
    kubectl apply -f fhir-server-svc.yaml
    kubectl apply -f frontend-ingress.yaml
fi

sleep $SLEEPTIME

sudo echo 'alias k=kubectl' >> /root/.bashrc
sudo echo 'complete -F __start_kubectl k' >> /root/.bashrc
sudo echo 'source <(kubectl completion bash)' >> /root/.bashrc

echo "${GREEN}All good now, Please access your application by using ${NOCOLOR}http://$PUBLIC_IP:8080/${GREEN} OR ${NOCOLOR}http://$PUBLIC_DNS:8080/${NOCOLOR}"
