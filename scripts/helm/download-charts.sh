#!/usr/bin/env bash

set -euEo pipefail

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-d] \
                [-c dir] [-g group] \
                [-r repository] [-t tag] \
                [chart1] [chart2...]

Downloads one or more charts. Looks in the repository for paths starting with
charts/chart1, charts/chart2, etc. and downloads all charts with a matching
tag. If no chart names are specified, all charts (charts/*) that match are
downloaded.

Available options:

-h, --help            Print this help and exit
-v, --verbose         Print script debug info
-d, --delete          Delete already downloaded charts if they exist
-c, --releases-cache  Location of release cache (defaults to RELEASES_CACHE env var)
-g, --group           Name of the group of charts (used when copying to release cache)
-r, --repository      Repository containing charts
-t, --tag             Tag of charts to download
EOF
}

msg() {
  echo >&2 -e "${1-}"
}

usage-err() {
  msg "$1"
  usage
  exit 2
}

parse-params() {
  # default values of variables set from params
  DELETE=0
  RELEASES_CACHE=${RELEASES_CACHE:-}
  GROUP=""
  REPOSITORY=""
  TAG=""
  CHARTS=()

  while [[ $# -gt 0 ]]; do
    case "${1-}" in
    -h | --help)           usage; exit 0 ;;
    -v | --verbose)        set -x ;;
    -d | --delete)         DELETE=1 ;;
    -c | --release-cache)  RELEASES_CACHE="${2-}"; shift ;;
    -g | --group)          GROUP="${2-}"; shift ;;
    -r | --repository)     REPOSITORY="${2-}"; shift ;;
    -t | --tag)            TAG="${2-}"; shift ;;
    -?*)                   usage-err "Unknown option: $1" ;;
    *)                     CHARTS+=("${1-}") ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${GROUP-}" ]] && usage-err "Missing required parameter: group"
  [[ -z "${REPOSITORY-}" ]] && usage-err "Missing required parameter: repository"
  [[ -z "${TAG-}" ]] && usage-err "Missing required parameter: tag"

  return 0
}

parse-params "$@"

if [[ ${#CHARTS[@]} -eq 0 ]]; then
  while read -r NAME; do
    CHARTS+=("$(basename "$NAME")")
  done < <(gcloud container images list --repository="$REPOSITORY/charts" --format="value(name)")
fi

if [[ ${#CHARTS[@]} -eq 0 ]]; then
  msg "No charts found in $REPOSITORY"
  exit 1
fi

TGZ_DIR=$RELEASES_CACHE/$GROUP-$TAG.tgz
CACHE_DIR=$RELEASES_CACHE/$GROUP-$TAG
if [[ $DELETE == 0 ]]; then
  if [[ -d "$TGZ_DIR" || -d "$CACHE_DIR" ]]; then
    msg "$TGZ_DIR or $CACHE_DIR already exists (use --delete to delete)"
    exit 1
  fi
else
  rm -rf "$TGZ_DIR" "$CACHE_DIR"
fi
mkdir -p "$TGZ_DIR" "$CACHE_DIR"

pushd "$TGZ_DIR" > /dev/null
for CHART in "${CHARTS[@]}"; do
  helm pull "oci://$REPOSITORY/charts/$CHART" --version "$TAG"
done
popd > /dev/null

pushd "$CACHE_DIR" > /dev/null
for CHART in "${CHARTS[@]}"; do
  tar xfz "$TGZ_DIR/$CHART-$TAG.tgz"
done
popd > /dev/null

echo ""
echo "Chart(s) available in the cache: $CACHE_DIR"
