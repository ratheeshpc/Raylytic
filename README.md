# Challenge DevOps Engineer - HAPI FHIR server Project

This project inclues docker compose file, Make file to start stop application:

## Prerequisites
- Make sure docker installed
- Make sure "make" installed
- Make sure git installed
- `We are achiving all these pre-requisite while creating the machine with Terraform.`


## Procedure
- Clone this repo [git clone https://github.com/ajaisreenilayam/Raylytic.git]

- Change directory to repo folder [cd Raylytic]
- run 
  - "make start" starts all services [Start all the services]
  - "make stops" stops all services [Stop all the services]

## Points to note
- We could use image hapiproject/hapi:latest as well 
- For custom build go to "hapi-fhir-jpaserver-starter" folder and make changes 
- Build your Docker images using "docker build -t <imagename:tag> . command

# Run in Kubernetes - in Draft
- run install.sh in your linux machine
- this will setup a single node kubernetes cluster using kind
- deployment YAML and Service YAML incoperated in install.sh

## Unistall.sh
- run uninstall.sh which will remove K8S cluster

## Links I used
- https://github.com/hapifhir/hapi-fhir-jpaserver-starter/blob/2e8c6a7082ee4a830bccfb37aa18520486b96c86/src/main/resources/hapi.properties
- https://gist.github.com/citizenrich/ef644ea195106a771717e8c234e525b3
- https://github.com/conceptant/synthea-fhir

## Helpful commands
- docker images | awk '{ print $3 }' | while read output; do docker rmi --force $output; done
- docker ps -a | awk '{ print $1 }' | while read output; do docker rm --force $output; done
- docker ps | awk '{ print $1 }' | while read output; do docker stop  $output; done
- sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
- docker run --rm -e SYNTHEA_SEED=<seed> -e SYNTHEA_SIZE=<num_records> -e FHIR_URL=<fhir_server_url> synthea/synthea-fhir
