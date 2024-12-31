import psycopg2
import argparse
import subprocess
import requests
import time
import json

def load_credentials(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def port_forward():
    # Run kubectl port-forward command
    process = subprocess.Popen(["kubectl", "port-forward", "postgres-0", "5432:5432"])
    time.sleep(5)  # Wait for port-forwarding to be established
    return process

def decrypt_value(encrypted_value, decrypt_url):
    headers = {
        'accept': '*/*',
        'accept-language': 'en-US,en;q=0.9',
        'content-type': 'application/json'
    }
    data = {
        "encryptedValue": encrypted_value
    }
    response = requests.post(decrypt_url, headers=headers, data=json.dumps(data))
    if response.status_code == 200:
        return response.json().get('plainTextValue')
    else:
        response.raise_for_status()

def connect_and_query(env, strategy, login_id=None):
    port_forward_process = None
    connection = None
    try:
        # Load credentials from file
        creds = load_credentials('credentials.json')

        # If environment is 'ondemand', set up port-forwarding
        if env == "ondemand":
            port_forward_process = port_forward()

        # Get credentials for the specified environment
        env_creds = creds[env]

        # Connect to your postgres DB
        connection = psycopg2.connect(
            dbname=env_creds["dbname"],
            user=env_creds["user"],
            password=env_creds["password"],
            host=env_creds["host"],
            port=env_creds["port"]
        )

        # Open a cursor to perform database operations
        cursor = connection.cursor()

        # Execute a query based on the strategy
        if strategy == "by-login":
            if login_id is None:
                raise ValueError("login_id must be provided for by-login strategy")
            cursor.execute("SELECT value FROM verificationtoken.verification_token WHERE source='LOGIN' AND source_id=%s ORDER BY create_date DESC LIMIT 1;", (login_id,))
        elif strategy == "recent":
            cursor.execute("SELECT value FROM verificationtoken.verification_token ORDER BY create_date DESC LIMIT 1;")
        else:
            print(f"Unknown strategy: {strategy}")
            return

        # Retrieve query results
        records = cursor.fetchall()
        for record in records:
            encrypted_value = record[0]
            decrypted_value = decrypt_value(encrypted_value, env_creds["decrypt_url"])
            print(decrypted_value)

    except Exception as error:
        print(f"Error: {error}")
    finally:
        if connection:
            cursor.close()
            connection.close()
        if port_forward_process:
            port_forward_process.terminate()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Connect to PostgreSQL database and perform a query.")
    parser.add_argument("env", choices=["ondemand", "main", "stage", "preprod"], help="The environment to connect to.")
    parser.add_argument("strategy", choices=["by-login", "recent"], help="The strategy to use for querying.")
    parser.add_argument("--login-id", help="The login ID to use for the by-login strategy.")
    args = parser.parse_args()

    connect_and_query(args.env, args.strategy, args.login_id)