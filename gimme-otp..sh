#!/bin/zsh

# Function to load credentials from a JSON file
load_credentials() {
    local env=$1
    jq -r ".${env}" credentials.json
}

# Function to perform port forwarding
port_forward() {
    kubectl port-forward postgres-0 5432:5432 > /dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    sleep 5  # Wait for port-forwarding to be established
}

# Function to decrypt a value
decrypt_value() {
    local encrypted_value=$1
    local decrypt_url=$2
    curl -s -X POST -H "accept: */*" -H "content-type: application/json" -d "{\"encryptedValue\":\"${encrypted_value}\"}" "${decrypt_url}" | jq -r '.plainTextValue'
}

# Function to connect and query the database
connect_and_query() {
    local env=$1
    local strategy=$2
    local login_id=$3

    # Load credentials from file
    local creds=$(load_credentials "${env}")
    local dbname=$(echo "${creds}" | jq -r '.dbname')
    local user=$(echo "${creds}" | jq -r '.user')
    local password=$(echo "${creds}" | jq -r '.password')
    local host=$(echo "${creds}" | jq -r '.host')
    local port=$(echo "${creds}" | jq -r '.port')
    local decrypt_url=$(echo "${creds}" | jq -r '.decrypt_url')

    # If environment is 'ondemand', set up port-forwarding
    if [[ "${env}" == "ondemand" ]]; then
        port_forward
    fi

    # Construct the query based on the strategy
    local query=""
    if [[ "${strategy}" == "by-login" ]]; then
        if [[ -z "${login_id}" ]]; then
            echo "Error: login_id must be provided for by-login strategy" > /dev/stderr
            exit 1
        fi
        query="SELECT value FROM verificationtoken.verification_token WHERE source='LOGIN' AND source_id='${login_id}' ORDER BY create_date DESC LIMIT 1;"
    elif [[ "${strategy}" == "recent" ]]; then
        query="SELECT value FROM verificationtoken.verification_token ORDER BY create_date DESC LIMIT 1;"
    else
        echo "Unknown strategy: ${strategy}" > /dev/stderr
        exit 1
    fi

    # Execute the query and decrypt the results
    PGPASSWORD="${password}" psql -h "${host}" -U "${user}" -d "${dbname}" -c "${query}" -t -A 2>/dev/null | while read -r encrypted_value; do
        decrypted_value=$(decrypt_value "${encrypted_value}" "${decrypt_url}")
        echo "${decrypted_value}"
    done

    # Clean up port-forwarding if it was set up
    if [[ "${env}" == "ondemand" ]]; then
        kill "${PORT_FORWARD_PID}" > /dev/null 2>&1
    fi
}

# Main script execution
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <env> <strategy> [--login-id <login_id>]" > /dev/stderr
    exit 1
fi

env=$1
strategy=$2
login_id=""

# Parse optional arguments
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --login-id)
            login_id=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1" > /dev/stderr
            exit 1
            ;;
    esac
done

echo "Fetching OTP..."
connect_and_query "${env}" "${strategy}" "${login_id}"