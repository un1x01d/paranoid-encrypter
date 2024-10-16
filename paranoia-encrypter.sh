#!/bin/bash

generate_rsa_keys() {
    if [[ ! -f private_key.pem || ! -f public_key.pem ]]; then
        echo "Generating RSA keys..."
        openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
        openssl rsa -pubout -in private_key.pem -out public_key.pem
    else
        echo "RSA keys already exist."
    fi
}

encrypt_symmetric_key() {
    # Encrypt the symmetric key using the RSA public key with pkeyutl
    openssl pkeyutl -encrypt -inkey public_key.pem -pubin -in "$1" -out "$2"
}

decrypt_symmetric_key() {
    # Decrypt the symmetric key using the RSA private key with pkeyutl
    openssl pkeyutl -decrypt -inkey private_key.pem -in "$1" -out "$2"
}

aes_encrypt() {
    # AES encrypt the file using a password-protected symmetric key
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$1" -in "$2" -out "$3"
}

aes_decrypt() {
    # AES decrypt the file using a password-protected symmetric key
    openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass pass:"$1" -in "$2" -out "$3"
}

chacha_encrypt() {
    # ChaCha20 encrypt the file using a password-protected symmetric key
    openssl enc -chacha20 -pbkdf2 -salt -pass pass:"$1" -in "$2" -out "$3"
}

chacha_decrypt() {
    # ChaCha20 decrypt the file using a password-protected symmetric key
    openssl enc -d -chacha20 -pbkdf2 -salt -pass pass:"$1" -in "$2" -out "$3"
}

encrypt() {
    local source_file="$1"
    local output_file="$2"

    # Check if the source file exists
    if [[ ! -f "$source_file" ]]; then
        echo "Error: Source file '$source_file' does not exist."
        exit 1
    fi

    generate_rsa_keys

    # Generate random passwords for AES and ChaCha20 encryption
    local aes_password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' </dev/urandom | head -c 16)
    local chacha_password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' </dev/urandom | head -c 16)

    # Temporary file paths
    local symmetric_key="/dev/shm/symmetric_key.$$"
    local encrypted_key="/dev/shm/encrypted_key.$$"
    local encrypted_data="/dev/shm/encrypted_data.$$"
    local chacha_encrypted_data="/dev/shm/chacha_encrypted_data.$$"

    # Step 1: Generate a symmetric key
    head -c 32 </dev/urandom >"$symmetric_key"

    # Step 2: Encrypt the symmetric key with RSA
    encrypt_symmetric_key "$symmetric_key" "$encrypted_key"

    # Step 3: Encrypt the data with AES using the password
    aes_encrypt "$aes_password" "$source_file" "$encrypted_data"

    # Step 4: Encrypt the AES-encrypted data with ChaCha20 using the password
    chacha_encrypt "$chacha_password" "$encrypted_data" "$chacha_encrypted_data"
    rm -f "$encrypted_data"  # Remove the temporary AES-encrypted file

    # Step 5: Combine the encrypted key and ChaCha20-encrypted data into a single output file
    cat "$encrypted_key" "$chacha_encrypted_data" > " $output_file"
    rm -f "$encrypted_key" "$chacha_encrypted_data"  # Remove temporary files

    echo "Encryption completed: $output_file"
    echo "AES Password: $aes_password"
    echo "ChaCha20 Password: $chacha_password"
    echo "Private Key Path: $(realpath private_key.pem)"
    echo "Public Key Path: $(realpath public_key.pem)"
}

decrypt() {
    local source_file="$1"
    local output_file="$2"

    # Check if the encrypted file exists
    if [[ ! -f "$source_file" ]]; then
        echo "Error: Encrypted file '$source_file' does not exist."
        exit 1
    fi

    # Prompt for the AES and ChaCha20 passwords
    read -sp "Enter AES password: " aes_password
    echo
    read -sp "Enter ChaCha20 password: " chacha_password
    echo

    # Temporary file paths
    local encrypted_key="/dev/shm/encrypted_key.$$"
    local chacha_encrypted_data="/dev/shm/chacha_encrypted_data.$$"
    local symmetric_key="/dev/shm/symmetric_key.$$"
    local decrypted_data="/dev/shm/decrypted_data.$$"

    # Step 1: Split the input file into the encrypted key and ChaCha20-encrypted data
    head -c 256 "$source_file" >"$encrypted_key"  # Assuming a 2048-bit RSA key (256 bytes)
    tail -c +257 "$source_file" >"$chacha_encrypted_data"

    # Step 2: Decrypt the symmetric key using the RSA private key
    decrypt_symmetric_key "$encrypted_key" "$symmetric_key"

    # Step 3: Decrypt the ChaCha20-encrypted data using the password
    chacha_decrypt "$chacha_password" "$chacha_encrypted_data" "$decrypted_data"

    # Step 4: Decrypt the data using the AES password
    aes_decrypt "$aes_password" "$decrypted_data" "$output_file"

    # Clean up temporary files
    rm -f "$encrypted_key" "$chacha_encrypted_data" "$symmetric_key" "$decrypted_data"

    echo "Decryption completed: $output_file"
}

main() {
    if [[ $# -lt 3 ]]; then
        echo "Usage:"
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
            echo "Unknown mode: $mode"
            echo "Usage:"
            echo "  $0 encrypt <source_file> <output_file>"
            echo "  $0 decrypt <source_file> <output_file>"
            exit 1
            ;;
    esac
}

main "$@"

