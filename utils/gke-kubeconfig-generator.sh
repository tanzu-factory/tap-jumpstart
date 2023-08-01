#!/bin/bash

# https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication

get_user_input() {
  local input_for=$1
  local input=""
  while [[ -z $input ]]; do
      read -p "input for $input_for: " input
  done
  echo $input
}


generate_gke_kubeconfig() {
  local CLUSTER_NAME=""
  local COMPUTE_ZONE=""
  local PROJECT_NAME=""
  local IAM_USER_NAME=""

  
  returnedValue=$(get_user_input "CLUSTER_NAME")
  if [[ -z $returnedValue ]]
  then
    printf "\nerror: received invalid value for CLUSTER_NAME\n"
    exit 1
  else
    CLUSTER_NAME=$returnedValue
    printf "\user-input CLUSTER_NAME=$CLUSTER_NAME\n"
  fi
  
  
  returnedValue=$(get_user_input "COMPUTE_ZONE")
  if [[ -z $returnedValue ]]
  then
    printf "\nerror: received invalid value for COMPUTE_ZONE\n"
    exit 1
  else
    COMPUTE_ZONE=$returnedValue
    printf "\user-input COMPUTE_ZONE=$COMPUTE_ZONE\n"    
  fi

  
  returnedValue=$(get_user_input "PROJECT_NAME")
  if [[ -z $returnedValue ]]
  then
    printf "\nerror: received invalid value for PROJECT_NAME\n"
    exit 1
  else
    PROJECT_NAME=$returnedValue
    printf "\user-input PROJECT_NAME=$PROJECT_NAME\n"
  fi
  
  
  returnedValue=$(get_user_input "IAM_USER_NAME")
  if [[ -z $returnedValue ]]
  then
    printf "\nerror: received invalid value for IAM_USER_NAME\n"
    exit 1
  else
    IAM_USER_NAME=$returnedValue
    printf "\user-input IAM_USER_NAME=$IAM_USER_NAME\n"
  fi

  local cluster_endpoint=$(gcloud container clusters describe $CLUSTER_NAME --zone=$COMPUTE_ZONE --project=$PROJECT_NAME --format="value(endpoint)")
  local ca_data=$(gcloud container clusters describe $CLUSTER_NAME --zone=$COMPUTE_ZONE --project=$PROJECT_NAME --format="value(masterAuth.clusterCaCertificate)")
      

  echo "apiVersion: v1
  kind: Config
  clusters:
  - name: $CLUSTER_NAME
    cluster:
      server: https://$cluster_endpoint
      certificate-authority-data: $ca_data
  users:
  - name: $IAM_USER_NAME
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        args:
        - --use_application_default_credentials
        command: gke-gcloud-auth-plugin
        installHint: Install gke-gcloud-auth-plugin for kubectl by following
          https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin
        provideClusterInfo: true
  contexts:
  - context:
      cluster: $CLUSTER_NAME
      user: $IAM_USER_NAME
    name: $CLUSTER_NAME
  current-context: $CLUSTER_NAME" > $CLUSTER_NAME-kubeconfig.yaml

}

generate_gke_kubeconfig