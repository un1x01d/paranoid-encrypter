#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════╗"
echo "║           Paranoia Encrypter v2.6          ║"
echo "║    Your security ends where your trust     ║"
echo "║             in others begins.              ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Cross-platform base64 (no newlines)
b64_noline() {
    if base64 --help 2>&1 | grep -q -- '-w'; then
        base64 -w0
    else
        base64 | tr -d '\n'
    fi
}

# Triple base64 encode using compatible base64
triple_base64_encode() {
    echo -n "$1" | b64_noline | b64_noline | b64_noline
}

generate_rsa_keys() {
    if [[ ! -f private_key.pem || ! -f public_key.pem ]]; then
        echo -e "${YELLOW}Generating RSA keys...${NC}"
        openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096 >/dev/null 2>&1
        openssl rsa -pubout -in private_key.pem -out public_key.pem >/dev/null 2>&1
    else
        echo -e "${YELLOW}RSA keys already exist.${NC}"
    fi
}

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

    local aes_plain=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c 32)
    local chacha_plain=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c 32)
    local camellia_plain=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c 32)

    local symmetric_key=$(openssl rand 32)
    local encrypted_key=$(echo -n "$symmetric_key" | openssl pkeyutl -encrypt -pubin -inkey public_key.pem | b64_noline)

    encrypted_data=$(openssl enc -aes-256-cbc -pbkdf2 -md sha512 -salt -pass pass:"$aes_plain" -in "$source_file" 2>/dev/null | \
        openssl enc -chacha20 -pbkdf2 -md sha512 -salt -pass pass:"$chacha_plain" 2>/dev/null | \
        openssl enc -camellia-256-cbc -pbkdf2 -md sha512 -salt -pass pass:"$camellia_plain" 2>/dev/null | b64_noline)

    echo "$encrypted_key" > "$output_file"
    echo "::" >> "$output_file"
    echo "$encrypted_data" >> "$output_file"

    local duration=$SECONDS
    echo -e "${GREEN}Encryption completed at $(date)${NC}"
    echo -e "${GREEN}Elapsed time: $(($duration / 60)) minutes and $(($duration % 60)) seconds${NC}"
    echo -e "${YELLOW}Output file: $output_file${NC}"
    echo -e "${YELLOW}Private Key Path: $(realpath private_key.pem)${NC}"
    echo -e "${YELLOW}Public Key Path: $(realpath public_key.pem)${NC}"

    echo -e "${YELLOW}Store these RAW passwords securely for decryption:${NC}"
    echo -e "${NC}AES password: $aes_plain"
    echo -e "ChaCha20 password: $chacha_plain"
    echo -e "Camellia password: $camellia_plain${NC}"

    aes_plain=""; chacha_plain=""; camellia_plain=""
    unset aes_plain chacha_plain camellia_plain
}

decrypt() {
    local source_file="$1"
    local output_file="$2"

    if [[ ! -f "$source_file" ]]; then
        echo -e "${RED}Error: Encrypted file '$source_file' does not exist.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Decryption started at $(date)${NC}"
    SECONDS=0

    local encrypted_key=$(head -n 1 "$source_file")
    local encrypted_data=$(tail -n +3 "$source_file" | tr -d '\n')

    echo -e "${YELLOW}Enter RAW passwords for decryption:${NC}"
    read -rsp "AES password: " AES; echo
    read -rsp "ChaCha20 password: " CHACHA; echo
    read -rsp "Camellia password: " CAMELLIA; echo

    if [[ -z "$AES" || -z "$CHACHA" || -z "$CAMELLIA" ]]; then
        echo -e "${RED}Invalid input: one or more passwords are empty.${NC}"
        exit 1
    fi

    local symmetric_key=$(echo "$encrypted_key" | base64 -d | openssl pkeyutl -decrypt -inkey private_key.pem 2>/dev/null)
    if [[ $? -ne 0 || -z "$symmetric_key" ]]; then
        echo -e "${RED}Error: Failed to decrypt the symmetric key with RSA.${NC}"
        exit 1
    fi

    echo "$encrypted_data" | base64 -d | \
        openssl enc -d -camellia-256-cbc -pbkdf2 -md sha512 -salt -pass pass:"$CAMELLIA" 2>/dev/null | \
        openssl enc -d -chacha20 -pbkdf2 -md sha512 -salt -pass pass:"$CHACHA" 2>/dev/null | \
        openssl enc -d -aes-256-cbc -pbkdf2 -md sha512 -salt -pass pass:"$AES" -out "$output_file" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Decryption failed. Check passwords or file integrity.${NC}"
        exit 1
    fi

    local duration=$SECONDS
    echo -e "${GREEN}Decryption completed at $(date)${NC}"
    echo -e "${GREEN}Elapsed time: $(($duration / 60)) minutes and $(($duration % 60)) seconds${NC}"
    echo -e "${YELLOW}Output file: $output_file${NC}"

    AES=""; CHACHA=""; CAMELLIA=""
    unset AES CHACHA CAMELLIA
}

main() {
    if [[ $# -lt 1 ]]; then
        echo -e "${YELLOW}Usage:${NC}"
        echo "  $0 encrypt <source_file> <output_file>"
        echo "  $0 decrypt <source_file> <output_file>"
        exit 0
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
            echo "Usage:"
            echo "  $0 encrypt <source_file> <output_file>"
            echo "  $0 decrypt <source_file> <output_file>"
            exit 1
            ;;
    esac
}

main "$@"

