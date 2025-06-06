#!/bin/bash

declare PACKAGE="$1"
declare PROJECT="${PACKAGE//-/_}"

set -e

function check_pytest () {
    sudo -u pulp -E type pytest || {
        cat << EOF

ERROR: pytest is not installed

This usually means the functional test requirements failed to install. Check that
functest_requirements.txt exists for the plugin and that "oci-env test -p PLUGIN
functional" completed the install step successfully.
EOF
        exit 1
    }
}

function check_client () {
    sudo -u pulp -E python3 -c "import pulpcore.client.${PROJECT}" || {
        cat << EOF

ERROR: pulpcore.client.${PROJECT} is missing.

This usually means you did not run "oci-env generate-client ${PROJECT}" before
running the functional test command.
EOF
        exit 1
    }
}

check_pytest
check_client

API_URL="${API_PROTOCOL:-http}://${API_HOST:-localhost}:${API_PORT:-5001}"
echo "Running functional tests for ${PROJECT} against live API ${API_URL}"
echo "Auth: ${DJANGO_SUPERUSER_USERNAME:-admin} (password from DJANGO_SUPERUSER_PASSWORD)"

sudo -u pulp -E \
    API_PROTOCOL="${API_PROTOCOL:-http}" \
    API_HOST="${API_HOST:-localhost}" \
    API_PORT="${API_PORT:-5001}" \
    DJANGO_SUPERUSER_USERNAME="${DJANGO_SUPERUSER_USERNAME:-admin}" \
    DJANGO_SUPERUSER_PASSWORD="${DJANGO_SUPERUSER_PASSWORD:-password}" \
    pytest -r sx --rootdir=/var/lib/pulp --color=yes --pyargs "${PROJECT}.tests.functional" "${@:2}"
