#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : k8s_cluster_health.sh
# Description : Kubernetes cluster health dashboard and pod troubleshooter.
#               Identifies failing pods, node stats, warnings, and resource usage.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

NAMESPACE="--all-namespaces"
CHECK_ONLY_ERRORS=false

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -n <namespace>   Target Kubernetes namespace (Default: all namespaces)"
  echo "  -e               Show ONLY failing/unhealthy pods"
  echo "  -h               Show help message"
  echo ""
  echo "Examples:"
  echo "  $0               # Full cluster health check"
  echo "  $0 -n kube-system"
  echo "  $0 -e            # Quick check for failing pods"
  exit 1
}

while getopts "n:eh" opt; do
  case "$opt" in
    n) NAMESPACE="-n $OPTARG" ;;
    e) CHECK_ONLY_ERRORS=true ;;
    h) usage ;;
    *) usage ;;
  esac
done

if ! command -v kubectl &>/dev/null; then
  echo -e "${RED}Error: 'kubectl' CLI tool is not installed or not in PATH.${NC}"
  exit 1
fi

print_header() {
  echo -e "\n${BLUE}=====================================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}=====================================================${NC}"
}

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}          Kubernetes Cluster Health Check            ${NC}"
echo -e "${BLUE}          Author: Sanjeev Senapati                   ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Current Context
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "N/A")
echo -e "Current Context : ${MAGENTA}${CURRENT_CTX}${NC}"

if [ "$CHECK_ONLY_ERRORS" = false ]; then
  # 1. Node Status
  print_header "1. Node Status & Capacity"
  kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,ROLE:.metadata.labels.kubernetes\\.io/role,VERSION:.status.nodeInfo.kubeletVersion,KERNEL:.status.nodeInfo.kernelVersion 2>/dev/null || kubectl get nodes

  # Node Metrics if metrics-server available
  if kubectl top nodes &>/dev/null; then
    echo -e "\n${CYAN}--- Node CPU & Memory Utilization ---${NC}"
    kubectl top nodes
  fi
fi

# 2. Failing Pods (CrashLoopBackOff, Error, OOMKilled, Pending, High Restarts)
print_header "2. Pod Diagnostic Check (Failing / Unhealthy Pods)"
UNHEALTHY_PODS=$(kubectl get pods $NAMESPACE 2>/dev/null | awk 'NR>1 && ($3 != "Running" && $3 != "Completed" || $4 > 5) {print $0}')

if [ -z "$UNHEALTHY_PODS" ]; then
  echo -e "${GREEN}[OK] No unhealthy or high-restart pods detected.${NC}"
else
  echo -e "${RED}Found problematic pods:${NC}"
  echo -e "${YELLOW}NAMESPACE   NAME   READY   STATUS   RESTARTS   AGE${NC}"
  echo "$UNHEALTHY_PODS" | while read -r line; do
    echo -e "${RED}${line}${NC}"
  done
fi

if [ "$CHECK_ONLY_ERRORS" = false ]; then
  # 3. Top Pod Resource Usage
  if kubectl top pods $NAMESPACE &>/dev/null; then
    print_header "3. Top Pods by Resource Usage"
    echo -e "${CYAN}--- Top 5 CPU Consuming Pods ---${NC}"
    kubectl top pods $NAMESPACE --sort-by=cpu 2>/dev/null | head -n 6 || true
    echo -e "\n${CYAN}--- Top 5 Memory Consuming Pods ---${NC}"
    kubectl top pods $NAMESPACE --sort-by=memory 2>/dev/null | head -n 6 || true
  fi

  # 4. Recent Warning Events
  print_header "4. Recent Warning Events (Last 10)"
  EVENTS=$(kubectl get events $NAMESPACE --field-selector type=Warning --sort-by='.metadata.creationTimestamp' 2>/dev/null | tail -n 10)
  if [ -z "$EVENTS" ]; then
    echo -e "${GREEN}No recent warning events found.${NC}"
  else
    echo "$EVENTS"
  fi
fi

echo -e "\n${GREEN}Kubernetes check completed successfully.${NC}"
