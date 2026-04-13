#!/usr/bin/env bash
script_dir=$(dirname ${BASH_SOURCE[0]})

rm -f manifests.generated.yaml;

function update_helm_deps {
  APP_PATH="$1"
  # Loop over each dependency in Chart.yaml
  yq e '.dependencies[] | "\(.name)-\(.version).tgz"' "$APP_PATH/Chart.yaml" | while read -r chart_file; do
    if [ ! -f "$APP_PATH/charts/$chart_file" ]; then
      helm dependency update $APP_PATH --skip-refresh 2> /dev/null || helm dependency update $APP_PATH;
      return 0
    fi
  done
}

function generate {
    APP_PATH="$(dirname $1)";
    update_helm_deps $APP_PATH
    all_arg=""
    if [ "$2" == true ]; then
      all_arg="--set generateClusterObjects=true"
    fi;

    helm template $APP_PATH --values global.values.yaml --values $APP_PATH/values.yaml $all_arg >> manifests.generated.yaml;
}

all=false
cust=false
for i in "$@" ; do
    if [[ $i == "--all" ]] ; then
      all=true
    else
      cust=true
    fi
done

if [ "$cust" == false ]; then
  for FILE in $script_dir/*/values.yaml; do
    APP="$(basename $(dirname $FILE))";
    if [ $APP != '_argocd' ] && [ $APP != "--all" ]; then
      generate $FILE $all;
    fi
  done
else
  for svc in "$@"
  do
    if [ $svc != "--all" ]; then
      FILE="./$svc/values.yaml";
      generate $FILE $all;
    fi;
  done
fi;