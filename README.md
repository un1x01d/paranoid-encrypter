# Paranoia Encrypter

This script, `paranoia-encrypter.sh`, provides a way to encrypt and decrypt files using a combination of RSA, AES, and ChaCha20 algorithms. It automatically generates RSA keys if they don't already exist and allows for secure encryption of data with a multi-step process.

## Features
- RSA key generation (4096-bit) if not present
- Symmetric key encryption using RSA
- File encryption using AES-256-CBC and ChaCha20 algorithms
- Secure random password generation for encryption
- Combination of asymmetric and symmetric encryption for enhanced security

## Prerequisites
- OpenSSL must be installed on your system.

## Usage
The script accepts two modes: `encrypt` and `decrypt`.

### Encryption
```
./paranoia-encrypter.sh encrypt <source_file> <output_file>
```
- `<source_file>`: Path to the file to be encrypted.
- `<output_file>`: Path where the encrypted output will be stored.

### Decryption
```
./paranoia-encrypter.sh decrypt <source_file> <output_file>
```
- `<source_file>`: Path to the encrypted file.
- `<output_file>`: Path where the decrypted output will be stored.

## How It Works
### Encryption Steps
1. **Generate RSA Keys**: Creates `private_key.pem` and `public_key.pem` if they don't already exist.
2. **Generate Symmetric Key**: Creates a random 32-byte symmetric key.
3. **Encrypt Symmetric Key**: Encrypts the symmetric key using the RSA public key.
4. **Encrypt Data (AES)**: Uses AES-256-CBC to encrypt the original file.
5. **Encrypt AES Output (ChaCha20)**: Encrypts the AES output using ChaCha20.
6. **Combine Outputs**: Merges the encrypted symmetric key and the ChaCha20-encrypted data into the final output file.

### Decryption Steps
1. **Extract Encrypted Key and Data**: Splits the input file into the encrypted symmetric key and the encrypted data.
2. **Decrypt Symmetric Key**: Uses the RSA private key to decrypt the symmetric key.
3. **Decrypt Data (ChaCha20)**: Uses the provided ChaCha20 password to decrypt the encrypted data.
4. **Decrypt Data (AES)**: Uses the provided AES password to decrypt the final output.

## Notes
- The script temporarily stores data in `/dev/shm` for added security.
- Make sure to store your RSA keys (`private_key.pem` and `public_key.pem`) securely.
- The script will prompt for the AES and ChaCha20 passwords during decryption.

## Example
```
./paranoia-encrypter.sh encrypt myfile.txt myfile.enc
./paranoia-encrypter.sh decrypt myfile.enc myfile_decrypted.txt
```

## Security Considerations
- Generated passwords for AES and ChaCha20 are printed during encryption; ensure they are stored securely.
- RSA key files must be protected to prevent unauthorized access.

## Troubleshooting
- If you see an "Error: Source file does not exist" message, verify the input file path.
- Ensure OpenSSL is installed and accessible from the command line.

## License
This script is open-source and available for modification or distribution.
