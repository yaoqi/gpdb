#!/bin/bash -l

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

    ssh-keyscan -p $REMOTE_PORT $REMOTE_HOST > pubkey
    awk '{printf "[%s]:", $1 }' pubkey > tmp
    echo -n $REMOTE_PORT >> tmp
    awk '{$1 = ""; print $0; }' pubkey >> tmp

    cat tmp >> ~/.ssh/known_hosts
}

function run_remote_test() {
    source ./gpdb_src/gpAux/gpdemo/gpdemo-env.sh

    MSI=`ls ./bin_gpdb_clients_windows_rc/*.msi`
    if [[ $MSI =~ greenplum-clients-(.*)-x86_64.msi ]];
    then
      VERSION=${BASH_REMATCH[1]}
    else
      echo "invalid package name"
    fi
    scp ./bin_gpdb_clients_windows_rc/*.msi $REMOTE_USER@$REMOTE_HOST:
    scp -P $REMOTE_PORT -r ./gpdb_src/gpMgmt/bin/gpload_test/gpload2 $REMOTE_USER@$REMOTE_HOST:.
    scp -P $REMOTE_PORT ./gpdb_src/src/test/regress/*.pl $REMOTE_USER@$REMOTE_HOST:./gpload2
    scp -P $REMOTE_PORT ./gpdb_src/src/test/regress/*.pm $REMOTE_USER@$REMOTE_HOST:./gpload2

    ssh -T -R$PGPORT:127.0.0.1:$PGPORT -L8081:127.0.0.1:8081 -L8082:127.0.0.1:8082 -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST <<- EOF
    set PGPORT=$PGPORT
    set PGUSER=gpadmin
    set PGHOST=127.0.0.1
    call "C:\Program Files\Greenplum\greenplum-clients-$VERSION\greenplum_clients_path.bat"
    cd gpload2
    python TEST_REMOTE.py
EOF
}

function _main() {

    if [ -z "$REMOTE_PORT" ]; then
        REMOTE_PORT=22
    fi

    time configure
    time install_gpdb
    time setup_gpadmin_user
    time make_cluster
    time import_remote_key
    time run_remote_test
}

_main "$@"
