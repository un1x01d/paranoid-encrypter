# RSA Hybrid Encryption Script

This Bash script provides a secure method for encrypting and decrypting files using RSA for key encryption and a combination of AES, ChaCha20, and Camellia symmetric encryption algorithms. It ensures strong security by employing a hybrid encryption mechanism.

---

## Features

- **RSA Key Management**:
  - Automatically generates RSA private and public keys if they do not exist.
  - Supports 4096-bit RSA keys for secure encryption of symmetric keys.

- **Multi-Layer Symmetric Encryption**:
  - Encrypts files sequentially using AES-256-CBC, ChaCha20, and Camellia-256-CBC algorithms.

- **Secure Temporary Storage**:
  - Uses shared memory (`/dev/shm`) for storing sensitive temporary files to enhance security.

- **Performance Feedback**:
  - Displays the start and end times of encryption/decryption along with elapsed time.

---

## Requirements

- **OpenSSL**: Ensure that OpenSSL is installed and accessible via the terminal.
- **Bash**: The script requires a Unix-like environment with Bash.

---

## Usage

### Script Syntax

\`\`\`bash
./script_name.sh <mode> <source_file> <output_file>
\`\`\`

### Modes

1. **Encryption**:
   - Encrypt a file with the following command:
     \`\`\`bash
     ./script_name.sh encrypt <source_file> <output_file>
     \`\`\`
   - Example:
     \`\`\`bash
     ./script_name.sh encrypt secret.txt secret.enc
     \`\`\`

2. **Decryption**:
   - Decrypt a file with the following command:
     \`\`\`bash
     ./script_name.sh decrypt <source_file> <output_file>
     \`\`\`
   - Example:
     \`\`\`bash
     ./script_name.sh decrypt secret.enc secret_decrypted.txt
     \`\`\`

---

## Workflow

### Encryption Process
1. Generates RSA keys if not present.
2. Creates a symmetric key and encrypts it with the RSA public key.
3. Sequentially encrypts the input file using:
   - AES-256-CBC
   - ChaCha20
   - Camellia-256-CBC
4. Combines the encrypted symmetric key and the encrypted file data into a single output file.

### Decryption Process
1. Splits the encrypted file into:
   - Encrypted symmetric key.
   - Encrypted file data.
2. Decrypts the symmetric key with the RSA private key.
3. Sequentially decrypts the file using:
   - Camellia-256-CBC
   - ChaCha20
   - AES-256-CBC
4. Outputs the decrypted file.

---

## Notes

- **RSA Key Files**:
  - Private Key: `private_key.pem`
  - Public Key: `public_key.pem`
- The script stores these files in the current working directory.
- If the RSA keys are misplaced, the encrypted files cannot be decrypted.

- **Passwords**:
  - The script generates random passwords for symmetric encryption during encryption.
  - Users must input these passwords during decryption. Keep them secure.

---

## Example

### Encrypting a File
\`\`\`bash
./encrypt_decrypt.sh encrypt myfile.txt myfile.enc
\`\`\`

### Decrypting a File
\`\`\`bash
./encrypt_decrypt.sh decrypt myfile.enc myfile_dec.txt
\`\`\`

---

## Security Considerations

- **Shared Memory Usage**: Temporary files are stored in `/dev/shm` for enhanced security. However, ensure system memory is sufficiently available.
- **Password Management**: Securely save the generated passwords as they are essential for decryption.

---

## License

This script is open source. Use it responsibly to ensure data security.

---

Feel free to modify the script to suit your specific use cases.

