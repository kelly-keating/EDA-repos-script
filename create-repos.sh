#!/bin/sh

# Enter current cohort
cohort="kotare-2019"

# Repos you want to clone (make sure you match the name listed on eda-challenges)
repos=("pupparazzi" "enspiraled")

# TODO: take repos from args rather than array


function clone_repos {

    echo "Starting script\n"
    read -p "Github username: " github_user
    read -sp "Github password: " github_password
    echo "Awesome sauce!\n\n"

    # TODO: Check credentials

    for repo in "${repos[@]}"; do
        clone_repo
        protect_master
    done

    echo "Done :)"
}


#### COPY EXISTING REPO

function clone_repo {

    eda_org="https://github.com/dev-academy-challenges"

    echo "Copying repo $repo - $eda_org/$repo.git\n"

    # if remote exists, otherwise
    ( 
        git ls-remote $eda_org/$repo.git -q 
    ) && ( 
        git clone $eda_org/$repo.git 
        make_new_repo 
        push_repo
    ) || (
        echo "No such repo $eda_org/$repo.git"
    )
}


#### MAKE NEW REPO ON STUDENT GITHUB

function make_new_repo {

    echo "\nCreating repo $repo on Github\n"

    # TODO: add "description": "This is your repository description that I got from git",
    new_repo_data='{"name":"'"$repo"'"}'

    # curl at github api
    # TODO: how try/catch?
    ( curl --user $github_user:$github_password -X POST --data "$new_repo_data" https://api.github.com/orgs/$cohort/repos > /dev/null ) && ( echo "\nCreated repo $repo" ) 
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
    git push https://github.com/$cohort/$repo.git $branch
}


#### PROTECT MASTER

function protect_master {

    echo "\nUpdating master permissions\n"

    # This adds the branch restrictions so that only admin can push to that branch
    permission_settings='{"required_status_checks":null,"enforce_admins":null,"required_pull_request_reviews":null,"restrictions":{"users":[],"teams":[]}}'

    # Parse it into json
    permissions=$(jq <<< $permission_settings)

    # TODO: how try/catch?
    ( curl --user $github_user:$github_password -X PUT --data "$permissions" https://api.github.com/repos/$cohort/$repo/branches/master/protection > /dev/null ) && ( echo "\nUpdated master permissions on $repo\n" )
}

clone_repos 
