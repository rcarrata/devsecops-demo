set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare PRJ_PREFIX="demo"
declare COMMAND="help"

valid_command() {
  local fn=$1; shift
  [[ $(type -t "$fn") == "function" ]]
}

info() {
    printf "\n# INFO: $@\n"
}

err() {
  printf "\n# ERROR: $1\n"
  exit 1
}


while (( "$#" )); do
  case "$1" in
    start|promote|status)
      COMMAND=$1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      err "Error: Unsupported flag $1"
      ;;
    *)
      break
  esac
done

command.help() {
  cat <<-EOF
  Usage:
      demo [command] [options]

  Example:
      demo start

  COMMANDS:
      start                          Starts the deploy DEV pipeline
      promote                        Starts the deploy STAGE pipeline
      status                         Check the resources available for the demo
      help                           Help about this command
EOF
}

command.status() {

    info "## GOGS Server - Username/Password: gogs/gogs ##"
    GOGS=$(oc get route -n cicd gogs -o jsonpath='{.spec.host}')
    printf "https://$GOGS"
    echo ""

    info "## Nexus Server - Username/Password: admin/admin123 ##"
    NEXUS=$(oc get route -n cicd nexus -o jsonpath='{.spec.host}')
    printf "https://$NEXUS"
    echo ""

    info "## Sonarqube Server - Username/Password: admin/admin ##"
    SONARQUBE=$(oc get route -n cicd sonarqube -o jsonpath='{.spec.host}')
    printf "https://$SONARQUBE"
    echo ""

    info "## Reports Server - Username/Password: reports/reports ##"
    REPORTS=$(oc get route -n cicd reports-repo -o jsonpath='{.spec.host}')
    printf "https://$REPORTS"
    echo ""

    info "## ACS/Stackrox Server - Username/Password: admin/stackrox ##"
    ACS=$(oc get route -n stackrox central -o jsonpath='{.spec.host}')
    printf "https://$ACS"
    echo ""

    info "## ArgoCD Server - Username/Password: admin/[DEX] ##"
    ARGO=$(oc get route -n openshift-gitops openshift-gitops-server -o jsonpath='{.spec.host}')
    printf "https://$ARGO"
    echo ""
}

command.start() {
    info "## Executing Dev Pipeline... ##"
    oc create -f run/pipeline-build-dev-run.yaml -n cicd
    OCP_ROUTE=$(oc whoami --show-console)
    info "Check the pipeline in: \n$OCP_ROUTE/pipelines/ns/cicd/pipeline-runs"
    echo ""
}

command.promote() {
    info "## Executing Stage Pipeline... ##"
    oc create -f run/pipeline-build-stage-run.yaml -n cicd
    OCP_ROUTE=$(oc whoami --show-console)
    info "Check the pipeline in: \n$OCP_ROUTE/pipelines/ns/cicd/pipeline-runs"
    echo ""
}

main() {
  local fn="command.$COMMAND"
  valid_command "$fn" || {
    err "invalid command '$COMMAND'"
  }

  cd $SCRIPT_DIR
  $fn
  return $?
}

main
