#!bin/bash

# deploy_agent.sh - deploy, run and archive the Attendance Tracker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

cd "$SCRIPT_DIR" || exit 1

die() {
    echo "EROR: $*" >&2
    exit 1
}

# Pre-flight checks


check_requirements() {
	echo
	echo "Checking required programs..."

	 if ! command -v python3 >/dev/null 2>&1
    then
        echo "ERROR: python3 is not installed."
        return 1
    fi

    if ! command -v zip >/dev/null 2>&1
    then
        echo "ERROR: zip is not installed."
        return 1
    fi

    echo "python3: OK"
    echo "zip: OK"

    return 0

}


