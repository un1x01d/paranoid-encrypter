# Paranoia Encrypter

## Description
Paranoia Encrypter is a highly secure bash-based encryption tool designed with a **Zero Trust security model** in mind. It supports encryption of both **text files** and **binary files**, with the file size limit depending on available system memory. The script leverages multiple layers of encryption using **AES-256-CBC**, **ChaCha20**, and **Camellia-256-CBC** algorithms and uses **RSA keys** for secure key management. Temporary files are securely handled in shared memory (`/dev/shm`) and shredded upon script termination to ensure no sensitive data is left behind.

---

## Features
- **Multi-layered encryption**: Combines AES, ChaCha20, and Camellia encryption algorithms for robust data protection.
- **RSA key pair management**: Automatically generates RSA keys for secure asymmetric encryption of symmetric keys.
- **Binary file support**: Encrypts both text and binary files, with file size limited by system memory.
- **Secure temporary file handling**: Uses shared memory (`/dev/shm`) for temporary files and securely deletes them with `shred`.
- **Time tracking**: Displays encryption/decryption start and end times along with the elapsed time.
- **Failsafe cleanup**: Implements a trap to clean up temporary files upon script interruption or termination.

---

## Usage
Run the script with the following commands:

### Encryption
```bash
./paranoia_encrypter.sh encrypt <source_file> <output_file>
```
- **`<source_file>`**: Path to the text or binary file you want to encrypt.
- **`<output_file>`**: Path to save the encrypted output file.

### Decryption
```bash
./paranoia_encrypter.sh decrypt <source_file> <output_file>
```
- **`<source_file>`**: Path to the encrypted file.
- **`<output_file>`**: Path to save the decrypted output file.

---

## Example
### Encrypting a text file
```bash
./paranoia_encrypter.sh encrypt secret.txt encrypted_secret.bin
```

### Encrypting a binary file
```bash
./paranoia_encrypter.sh encrypt image.png encrypted_image.bin
```

### Decrypting a file
```bash
./paranoia_encrypter.sh decrypt encrypted_secret.bin decrypted_secret.txt
```

**Output:**
```
Encryption started at Mon Jan 1 12:00:00 UTC 2025
Generating RSA keys...
Encryption completed at Mon Jan 1 12:02:00 UTC 2025
Elapsed time: 2 minutes
Output file: encrypted_secret.bin
AES Password: <random_generated_password>
ChaCha20 Password: <random_generated_password>
Camellia Password: <random_generated_password>
Private Key Path: /path/to/private_key.pem
Public Key Path: /path/to/public_key.pem
```

---

## Why Paranoia Encrypter Aligns with Zero Trust Security

### 1. **Assume Breach Mentality**
The Zero Trust model operates under the assumption that breaches can and will happen. Paranoia Encrypter addresses this by:
- Encrypting all sensitive data using robust encryption algorithms.
- Ensuring that even if temporary files are accessed, they are securely shredded after use.

### 2. **Least Privilege Principle**
Temporary files and encryption keys are stored in shared memory (`/dev/shm`), reducing the potential attack surface. Only the necessary files are created during runtime and securely destroyed upon script termination.

### 3. **Multi-Layered Security**
The script uses multiple encryption algorithms sequentially (AES, ChaCha20, and Camellia), making it significantly harder for attackers to decrypt data even if one layer is compromised.

### 4. **Secure Key Management**
By using RSA for encrypting symmetric keys, Paranoia Encrypter ensures that the encryption keys themselves are protected. Even if an attacker gains access to encrypted data, they would still need the private RSA key to decrypt the symmetric keys.

### 5. **Secure Temporary File Handling**
Temporary files containing sensitive information are stored in volatile memory (`/dev/shm`) and shredded upon script termination, minimizing the risk of sensitive data being left on disk.

---

## Benefits Summary
| Feature                | Zero Trust Principle     | Benefit                                  |
|------------------------|--------------------------|------------------------------------------|
| Multi-layered encryption | Assume Breach            | Enhances security against data leaks     |
| Secure key management    | Least Privilege          | Protects encryption keys                |
| Temporary file handling  | Secure All Access        | Minimizes risk of data exposure         |
| Failsafe cleanup         | Continuous Verification  | Ensures no leftover sensitive data      |

---

## System Requirements
- Bash 4.0 or higher
- OpenSSL
- Sufficient system memory to handle large files in shared memory (`/dev/shm`)

---

## License
MIT License

```
MIT License

Copyright (c) 2025 Paranoia Encrypter Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Contributions
Contributions are welcome! Please submit a pull request with your proposed changes, and ensure your code is well-documented and follows best practices.

---

## Disclaimer
Paranoia Encrypter is provided as-is with no warranties. Users are responsible for ensuring the security of their own systems and data. Always test the script in a safe environment before using it in production.

