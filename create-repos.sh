#!/bin/sh
# This is a comment!

# Enter your username here if not stored locally (will then request password)
# GITHUB_USER=$(git config user.name) || "kelly-keating"
# GITHUB_PASSWORD=

COHORT="kotare-2019"

# Repos you want to clone (make sure you match the name on eda-challenges)
REPOS=("enspiraled")

EDA_ORG="https://github.com/dev-academy-challenges"
STUDENT_ORG="https://github.com/$COHORT"



function clone_repos {

    echo "Starting script\n"
    read -p "Github username: " GITHUB_USER
    read -sp "Github password: " GITHUB_PASSWORD
    echo "Awesome sauce!\n\n"


    for repo in "${REPOS[@]}"; do
        clone_repo
        make_new_repo 
        push_repo
        protect_master
    done

    echo "\nDone :)"
}


#### COPY EXISTING REPO

function clone_repo {

    echo "Copying repo $repo - $EDA_ORG/$repo.git\n"

    # if remote exists, otherwise
    ( git ls-remote $EDA_ORG/$repo.git -q ) && ( git clone $EDA_ORG/$repo.git ) || ("$repo  -  No such repo $EDA_ORG/$repo.git")
}


#### MAKE NEW REPO ON STUDENT GITHUB

function make_new_repo {

    echo "\nCreating repo $repo on Github\n"

    # TO ADD: "description": "This is your repository description",
    new_repo_data='{"name":"'"$repo"'"}'

    # curl at github api
    ( curl --user $GITHUB_USER:$GITHUB_PASSWORD -X POST --data "$new_repo_data" https://api.github.com/orgs/$COHORT/repos > /dev/null ) && ( echo "\nSuccessfully created repo $repo" )
}



#### PUSH A FULL COPY OF REPO

function push_repo {

    cd $repo

    allBranches=$(git branch -r)
    allBranches=${allBranches#*origin/HEAD -> origin/master}

    for branch in $allBranches; do
        push_branch ${branch#*origin/}
    done

    cd ..
    rm -rf $repo
}


function push_branch {

    branch=$1
    echo "\nCopying branch $branch"

    git checkout $branch
    git push $STUDENT_ORG/$repo.git $branch
}


#### PROTECT MASTER

function protect_master {

    echo "\nUpdating master permissions\n"

    # This is the branch permissions so that only admin can push to that branch
    permission_settings='{"required_status_checks":null,"enforce_admins":null,"required_pull_request_reviews":null,"restrictions":{"users":[],"teams":[]}}'

    # Parse it into json
    permissions=$(jq <<< $permission_settings)

    ( curl --user $GITHUB_USER:$GITHUB_PASSWORD -X PUT --data "$permissions" https://api.github.com/repos/$COHORT/$repo/branches/master/protection > /dev/null ) && ( echo "\nSuccessfully updated master permissions on $repo" )
}

clone_repos
