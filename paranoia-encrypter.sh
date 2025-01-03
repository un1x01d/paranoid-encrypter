#!/bin/bash


# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

echo -e "${GREEN}"
echo "╔══════════════════════════════════╗"
echo "║         Paranoia Encrypter       ║"
echo "║     Trust no one. Encrypt all.   ║"
echo "╚══════════════════════════════════╝"
echo -e "${NC}"

# Temporary file paths in shared memory
TEMP_FILES=("/dev/shm/symmetric_key" "/dev/shm/encrypted_key" "/dev/shm/encrypted_data")

# Function to securely clean up temporary files
secure_cleanup() {
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            shred -u "$file" >/dev/null 2>&1
        fi
    done
}

# Trap to handle script interruption or termination
trap secure_cleanup EXIT SIGINT SIGTERM

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
    local aes_password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c 32)
    local chacha_password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c 32)
    local camellia_password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c 32)

    # Use shared memory for temporary files
    openssl rand 32 >"${TEMP_FILES[0]}"
    openssl pkeyutl -encrypt -inkey public_key.pem -pubin -in "${TEMP_FILES[0]}" -out "${TEMP_FILES[1]}"

    # Encrypt the file sequentially
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$aes_password" -in "$source_file" 2>/dev/null | \
        openssl enc -chacha20 -pbkdf2 -salt -pass pass:"$chacha_password" 2>/dev/null | \
        openssl enc -camellia-256-cbc -pbkdf2 -salt -pass pass:"$camellia_password" 2>/dev/null >"${TEMP_FILES[2]}"

    # Combine encrypted key and data into the output file
    cat "${TEMP_FILES[1]}" "${TEMP_FILES[2]}" >"$output_file"

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
    head -c 512 "$source_file" >"${TEMP_FILES[1]}"
    tail -c +513 "$source_file" >"${TEMP_FILES[2]}"

    openssl pkeyutl -decrypt -inkey private_key.pem -in "${TEMP_FILES[1]}" -out "${TEMP_FILES[0]}"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to decrypt the symmetric key.${NC}"
        secure_cleanup
        exit 1
    fi

    cat "${TEMP_FILES[2]}" | \
        openssl enc -d -camellia-256-cbc -pbkdf2 -salt -pass pass:"$camellia_password" 2>/dev/null | \
        openssl enc -d -chacha20 -pbkdf2 -salt -pass pass:"$chacha_password" 2>/dev/null | \
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass pass:"$aes_password" -out "$output_file" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to decrypt the data. Please check passwords.${NC}"
        secure_cleanup
        exit 1
    fi

    secure_cleanup
    local duration=$SECONDS
    echo -e "${GREEN}Decryption completed at $(date)${NC}"
    echo -e "${GREEN}Elapsed time: $(($duration / 60)) minutes and $(($duration % 60)) seconds${NC}"
    echo -e "${YELLOW}Output file: $output_file${NC}"
}

# Main function
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

# Invoke the main function
main "$@"

