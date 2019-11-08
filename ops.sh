#!/usr/bin/env bash

readonly VERSION="1.0.0"

PREFIX="${PREFIX:-$OKTA_USER}"
readonly PREFIX="${PREFIX:-$USER}"

PROJECT="${PROJECT:-ops}"

usage(){
    echo "USAGE: $(basename "$0") <ticket>"
    echo "Version $VERSION"
    exit 1
}

find_branch_contains(){
    git branch --all 2>/dev/null | grep "$*" | head -n1 | rev | cut -d '/' -f1 | tr -d ' ' | tr -d '*' | rev
}

branch_exists_contains(){
    git branch --all 2>/dev/null | grep "$*" -c &>/dev/null
}

main(){
    test $# -eq 1 || usage
    if ! git branch &>/dev/null;then
        echo "$(pwd) does not appear to be a git repo"
        exit 1
    fi

    project=$(grep -o "[[:alpha:]]\+" <<< $1 | tr '[:upper:]' '[:lower:]')
    project=${project:-$PROJECT}
    number=$(grep -o "[[:digit:]]\+" <<< $1)
    shift

    branch="${PREFIX}_${project}-${number}"
    echo "Looking for $branch"

    if branch_exists_contains $branch; then
        git checkout "$(find_branch_contains $branch)"
    else
        if test -n "$*"; then
            branch="$branch$*"
        else
            echo -n "Adding branch ${branch} - give it a description: "
            read words
            branch="${branch}-$(tr -d '\n' <<< $words | tr '[:space:]' '_')"
        fi

        git checkout -b "$branch"
    fi
}

test -z "$SOURCE_ONLY" && main $*
