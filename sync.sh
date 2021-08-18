#!/bin/bash

set -o pipefail
set -eu

PREV_VERSION=`sed -n '/^ENV/,/^$/s/\(.*SYNDESIS_VERSION\)\([ =]\)\([0-9a-zA-Z\.-]\+\)\(.*\)/\3/p' Dockerfile`
CURRENT_VERSION=
SCM_URL=https://code.engineering.redhat.com/gerrit/syndesisio/syndesis
DRY_RUN=false

display_usage() {
    cat <<EOT
This script syncs files from the upstream project into the dist-git repository.
Files that require manual intervention are flagged, and others are copied in
place.

Usage: sync.sh [options] -c <current-syndesis-tag>

with options:
-d, --dry-run     Run in dry-run (non-destructive) mode
-h, --help        This help message
-p, --prev        Previous version of syndesis. Default is extracted from
                  Dockerfile.
EOT
}

strip_prod_version() {
    local version=$1

    local strippedVersion=${version%%-redhat*}
    strippedVersion=${strippedVersion%%-temporary*}

    echo $strippedVersion
}

main() {

    while [ $# -gt 0 ]
    do
        arg="$1"

        case $arg in
          -h|--help)
            display_usage
            exit 0
            ;;
          -c|--current)
            shift
            CURRENT_VERSION="syndesis-`strip_prod_version $1`"
            ;;
          -d|--dry-run)
            DRY_RUN=true
            ;;
          -p|--prev)
            shift
            PREV_VERSION="$1"
            ;;
          *)
            echo "Unknown argument: $1"
            display_usage
            exit 1
            ;;
        esac
        shift
    done

    if [ -z "$CURRENT_VERSION" ]
    then
        echo "ERROR: Current version must be specified."
        exit 1
    fi

    PREV_VERSION=syndesis-`strip_prod_version $PREV_VERSION`

    if [ ! -d syndesis ]
    then
        if ! git clone -q $SCM_URL
        then
            echo "ERROR: Could not clone $SCM_URL"
            exit 1
        fi
    fi

    pushd `basename $SCM_URL` > /dev/null

    if ! git checkout -q $CURRENT_VERSION
    then
        echo "ERROR: Could not check out $CURRENT_VERSION"
        popd
        exit 1
    fi

    diff_files=`git diff --name-only $PREV_VERSION app/meta/src/main/fabric8-includes`

    if [ -z $diff_files ]
    then
        echo "No files changed since previous version."
        popd > /dev/null
        exit 0
    fi

    for file in $diff_files
    do
        filename=`basename $file`

        echo "Copying file $file."
        if [ "$DRY_RUN" == "false" ]
        then
            cp $file ../${filename#app/meta/src/main/fabric8-includes/*}
        fi
    done

    popd > /dev/null
}

main $*
