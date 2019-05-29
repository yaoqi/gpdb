#! /bin/bash
set -eo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

function setup_gpadmin_user() {
    ./gpdb_src/concourse/scripts/setup_gpadmin_user.bash "$TEST_OS"
}

# Get ssh private key from REMOTE_KEY, which is assumed to
# be encode in base64. We can't pass the key content directly
# since newline doesn't work well for env variable.
function import_remote_key() {
    echo -n $REMOTE_KEY | base64 -d > ~/remote.key
    chmod 400 ~/remote.key

    eval `ssh-agent -s`
    ssh-add ~/remote.key

    # Scan for target server's public key, append port number
    mkdir -p ~/.ssh
    ssh-keyscan -p $REMOTE_PORT $REMOTE_HOST > ~/.ssh/known_hosts
}

# Simulate actual clients package installation, and try to
# connect with psql.
# SSH tunnel will forward the port of gpdemo cluster on concourse
# worker to remote machine.
function run_clients_test() {
    export PGPORT=15432
    scp ./gpdb_src/concourse/scripts/windows_remote_test.ps1 $REMOTE_USER@$REMOTE_HOST:
    ssh -T -R$PGPORT:127.0.0.1:$PGPORT -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST 'powershell < windows_remote_test.ps1'
}

function run_remote_test() {
    source ./gpdb_src/gpAux/gpdemo/gpdemo-env.sh

    # Create working directory on remote machine.
    run_clients_test
}

function _main() {

    if [ -z "$REMOTE_PORT" ]; then
        REMOTE_PORT=22
    fi

    time install_and_configure_gpdb
    time setup_gpadmin_user
    export WITH_MIRRORS=false
    time make_cluster
    time import_remote_key
    time run_remote_test
    exit 1
}

_main "$@"