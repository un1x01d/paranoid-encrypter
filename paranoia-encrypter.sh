#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

# Function to generate RSA keys if they do not exist
generate_rsa_keys() {
    if [[ ! -f private_key.pem || ! -f public_key.pem ]]; then
        echo -e "${YELLOW}Generating RSA keys...${NC}"
        openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096 >/dev/null 2>&1
        openssl rsa -pubout -in private_key.pem -out public_key.pem >/dev/null 2>&1
    else
        echo -e "${YELLOW}RSA keys already exist.${NC}"
    fi
}

# Main encryption function
encrypt() {
    local source_file="$1"
    local output_file="$2"

    if [[ ! -f "$source_file" ]]; then
        echo -e "${RED}Error: Source file '$source_file' does not exist.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Encryption started at $(date)${NC}"
    SECONDS=0

    generate_rsa_keys

    # Generate random passwords
    local aes_password=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
    local chacha_password=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
    local camellia_password=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)

    # Use shared memory for temporary files
    local symmetric_key_file="/dev/shm/symmetric_key"
    local encrypted_key_file="/dev/shm/encrypted_key"
    local encrypted_data_file="/dev/shm/encrypted_data"

    # Generate and encrypt symmetric key
    openssl rand 32 >"$symmetric_key_file"
    openssl pkeyutl -encrypt -inkey public_key.pem -pubin -in "$symmetric_key_file" -out "$encrypted_key_file"

    # Encrypt the file sequentially using shared memory
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$aes_password" -in "$source_file" 2>/dev/null | \
        openssl enc -chacha20 -pbkdf2 -salt -pass pass:"$chacha_password" 2>/dev/null | \
        openssl enc -camellia-256-cbc -pbkdf2 -salt -pass pass:"$camellia_password" 2>/dev/null >"$encrypted_data_file"

    # Combine encrypted key and data into the output file
    cat "$encrypted_key_file" "$encrypted_data_file" >"$output_file"

    # Clean up shared memory files
    rm -f "$symmetric_key_file" "$encrypted_key_file" "$encrypted_data_file"

    local duration=$SECONDS
    echo -e "${GREEN}Encryption completed at $(date)${NC}"
    echo -e "${GREEN}Elapsed time: $(($duration / 60)) minutes and $(($duration % 60)) seconds${NC}"
    echo -e "${YELLOW}Output file: $output_file${NC}"
    echo -e "${YELLOW}AES Password: $aes_password${NC}"
    echo -e "${YELLOW}ChaCha20 Password: $chacha_password${NC}"
    echo -e "${YELLOW}Camellia Password: $camellia_password${NC}"
    echo -e "${YELLOW}Private Key Path: $(realpath private_key.pem)${NC}"
    echo -e "${YELLOW}Public Key Path: $(realpath public_key.pem)${NC}"
}

# Main decryption function
decrypt() {
    local source_file="$1"
    local output_file="$2"

    if [[ ! -f "$source_file" ]]; then
        echo -e "${RED}Error: Encrypted file '$source_file' does not exist.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Decryption started at $(date)${NC}"
    SECONDS=0

    read -sp "Enter AES password: " aes_password
    echo
    read -sp "Enter ChaCha20 password: " chacha_password
    echo
    read -sp "Enter Camellia password: " camellia_password
    echo

    # Use shared memory for temporary files
    local encrypted_key_file="/dev/shm/encrypted_key"
    local encrypted_data_file="/dev/shm/encrypted_data"
    local symmetric_key_file="/dev/shm/symmetric_key"

    # Extract encrypted key and data
    head -c 512 "$source_file" >"$encrypted_key_file"  # Assuming RSA 4096-bit key (512 bytes)
    tail -c +513 "$source_file" >"$encrypted_data_file"

    # Decrypt the symmetric key
    openssl pkeyutl -decrypt -inkey private_key.pem -in "$encrypted_key_file" -out "$symmetric_key_file"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to decrypt the symmetric key.${NC}"
        rm -f "$encrypted_key_file" "$encrypted_data_file" "$symmetric_key_file"
        exit 1
    fi

    # Decrypt the file data sequentially using shared memory
    cat "$encrypted_data_file" | \
        openssl enc -d -camellia-256-cbc -pbkdf2 -salt -pass pass:"$camellia_password" 2>/dev/null | \
        openssl enc -d -chacha20 -pbkdf2 -salt -pass pass:"$chacha_password" 2>/dev/null | \
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass pass:"$aes_password" -out "$output_file" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to decrypt the data. Please check passwords.${NC}"
        rm -f "$encrypted_key_file" "$encrypted_data_file" "$symmetric_key_file"
        exit 1
    fi

    # Clean up shared memory files
    rm -f "$encrypted_key_file" "$encrypted_data_file" "$symmetric_key_file"

    local duration=$SECONDS
    echo -e "${GREEN}Decryption completed at $(date)${NC}"
    echo -e "${GREEN}Elapsed time: $(($duration / 60)) minutes and $(($duration % 60)) seconds${NC}"
    echo -e "${YELLOW}Output file: $output_file${NC}"
}

# Script entry point
main() {
    if [[ $# -lt 3 ]]; then
        echo -e "${RED}Usage:${NC}"
        echo "  $0 encrypt <source_file> <output_file>"
        echo "  $0 decrypt <source_file> <output_file>"
        exit 1
    fi

    local mode="$1"
    local source_file="$2"
    local output_file="$3"

    case "$mode" in
        encrypt)
            encrypt "$source_file" "$output_file"
            ;;
        decrypt)
            decrypt "$source_file" "$output_file"
            ;;
        *)
            echo -e "${RED}Unknown mode: $mode${NC}"
            exit 1
            ;;
    esac
}

main "$@"

