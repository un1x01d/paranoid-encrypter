#!/bin/bash

# Global variables
CENTRAL_LOGGING=false
SPLUNK_HEC_URL=""
SPLUNK_TOKEN=""

# Usage function
usage() {
    echo "Usage:"
    echo "  ./script.sh encrypt <source_file> <output_file_base> [options]"
    echo "  ./script.sh decrypt <encrypted_file> <hmac_file> <output_file> <symmetric_key> [options]"
    echo
    echo "Modes:"
    echo "  encrypt    Encrypt a file and generate an HMAC for integrity verification."
    echo "  decrypt    Decrypt a file and verify its integrity using the HMAC."
    echo
    echo "Arguments:"
    echo "  <source_file>         The plaintext file to be encrypted."
    echo "  <output_file_base>    Base name for output files (e.g., encrypted_data)."
    echo "  <encrypted_file>      The encrypted file to be decrypted."
    echo "  <hmac_file>           The HMAC file for integrity verification."
    echo "  <output_file>         The name of the decrypted output file."
    echo "  <symmetric_key>       The symmetric key used for decryption."
    echo
    echo "Options:"
    echo "  --central-logging     Enable centralized logging (rsyslog or Splunk)."
    echo "  --splunk-url <URL>    Splunk HEC endpoint (requires --splunk-token)."
    echo "  --splunk-token <TOKEN> Splunk HEC token for authentication."
    echo
    echo "Examples:"
    echo "  ./script.sh encrypt plaintext.txt encrypted_data"
    echo "  ./script.sh decrypt encrypted_data.data encrypted_data.hmac decrypted_file your-symmetric-key"
    echo "  ./script.sh encrypt plaintext.txt encrypted_data --central-logging --splunk-url \"https://splunk-hec-url:8088\" --splunk-token \"your-token\""
}

# Logging function
log_event() {
    local log_file="/var/log/encryption_script.log"
    local log_message="$1"
    local log_level="${2:-INFO}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Write the log message locally
    echo "[$timestamp] [$log_level] $log_message" >> "$log_file"

    # Display the log message on the console
    if [[ "$log_level" == "ERROR" ]]; then
        echo -e "\033[0;31m[ERROR] $log_message\033[0m"
    else
        echo -e "\033[0;32m[INFO] $log_message\033[0m"
    fi

    # Forward logs to centralized logging if enabled
    if [[ "$CENTRAL_LOGGING" == true ]]; then
        if [[ -n "$SPLUNK_HEC_URL" && -n "$SPLUNK_TOKEN" ]]; then
            send_log_to_splunk "$log_message" "$log_level"
        else
            send_log_to_rsyslog "$log_message" "$log_level"
        fi
    fi
}

# Function to send logs to rsyslog
send_log_to_rsyslog() {
    local message="$1"
    local level="$2"

    logger -p user.$level -t encryption_script "$message"
}

# Function to send logs to Splunk
send_log_to_splunk() {
    local message="$1"
    local level="$2"

    local payload=$(cat <<EOF
{
    "event": {
        "message": "$message",
        "severity": "$level",
        "timestamp": "$(date +%s)"
    },
    "sourcetype": "encryption_script_logs",
    "source": "encryption_script"
}
EOF
)

    curl -s -k "$SPLUNK_HEC_URL" \
        -H "Authorization: Splunk $SPLUNK_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1

    if [[ $? -ne 0 ]]; then
        echo -e "\033[0;31m[ERROR] Failed to send log to Splunk HEC.\033[0m"
    fi
}

# Encryption function
encrypt() {
    local source_file="$1"
    local output_file_base="$2"

    if [[ ! -f "$source_file" ]]; then
        log_event "Source file '$source_file' does not exist. Encryption aborted." "ERROR"
        exit 1
    fi

    log_event "Starting encryption for '$source_file'."
    SECONDS=0

    # Generate random symmetric key
    local symmetric_key=$(openssl rand -hex 32)
    local encrypted_data_file="${output_file_base}.data"
    local hmac_file="${output_file_base}.hmac"

    # Encrypt the file with AES-256
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$symmetric_key" -in "$source_file" -out "$encrypted_data_file"
    log_event "File encrypted with AES-256."

    # Generate HMAC for integrity
    echo -n "$symmetric_key" | openssl dgst -sha256 -hmac "$symmetric_key" -out "$hmac_file"
    log_event "HMAC generated for integrity verification."

    # Log elapsed time
    local duration=$SECONDS
    log_event "Encryption completed for '$source_file'. Time taken: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
}

# Decryption function
decrypt() {
    local encrypted_file="$1"
    local hmac_file="$2"
    local output_file="$3"
    local symmetric_key="$4"

    if [[ ! -f "$encrypted_file" || ! -f "$hmac_file" ]]; then
        log_event "Missing encrypted or HMAC file. Decryption aborted." "ERROR"
        exit 1
    fi

    log_event "Starting decryption for '$encrypted_file'."
    SECONDS=0

    # Verify HMAC
    echo -n "$symmetric_key" | openssl dgst -sha256 -hmac "$symmetric_key" -verify "$hmac_file"
    if [[ $? -ne 0 ]]; then
        log_event "HMAC verification failed. Data integrity compromised." "ERROR"
        exit 1
    fi
    log_event "HMAC verified successfully."

    # Decrypt the file
    openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass pass:"$symmetric_key" -in "$encrypted_file" -out "$output_file"
    log_event "Decryption completed for '$encrypted_file'."

    # Log elapsed time
    local duration=$SECONDS
    log_event "Decryption completed. Time taken: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --central-logging)
                CENTRAL_LOGGING=true
                shift
                ;;
            --splunk-url)
                SPLUNK_HEC_URL="$2"
                shift 2
                ;;
            --splunk-token)
                SPLUNK_TOKEN="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
}

# Main function
main() {
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    parse_args "$@"

    local mode="$1"
    shift

    case "$mode" in
        encrypt)
            encrypt "$@"
            ;;
        decrypt)
            decrypt "$@"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"

