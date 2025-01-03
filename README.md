# Paranoia Encrypter

Paranoia Encrypter is a collection of Bash scripts designed to provide robust encryption and decryption of files using multiple layers of security.  
The project includes two main scripts:

1. **paranoia-encrypter.sh**: Utilizes a combination of RSA, AES, and ChaCha20 algorithms for encryption.
2. **paranoia-encrypter-gov.sh**: Employs AES-256 encryption and HMAC-SHA256 for integrity verification, aligning with government encryption standards.

---

## Features

- **Multi-Layered Encryption**: Combines asymmetric (RSA) and symmetric (AES, ChaCha20) encryption for enhanced security.
- **Government-Standard Compliance**: Implements encryption methods that adhere to government standards.
- **Automatic Key Generation**: Generates necessary encryption keys if they do not exist.
- **Integrity Verification**: Ensures data integrity using HMAC-SHA256.
- **Centralized Logging Support**: Optional logging to centralized systems like rsyslog or Splunk HEC.

---

## Prerequisites

Ensure that `OpenSSL` is installed on your system.

---

## Usage

### General Syntax

```bash
./script.sh <mode> [arguments] [options]
```

### Modes

| **Mode**    | **Description**                                                |
|-------------|----------------------------------------------------------------|
| `encrypt`   | Encrypt a file and generate an HMAC for integrity verification. |
| `decrypt`   | Decrypt a file and verify its integrity using the HMAC.         |

---

## Options

| **Option**             | **Description**                                                      |
|------------------------|----------------------------------------------------------------------|
| `--central-logging`     | Enable centralized logging (rsyslog or Splunk).                     |
| `--splunk-url <URL>`    | Splunk HEC endpoint for centralized logging (requires `--splunk-token`). |
| `--splunk-token <TOKEN>`| Splunk HEC token for authentication.                                |

---

## 1. paranoia-encrypter.sh

### Encryption

```bash
./paranoia-encrypter.sh encrypt <source_file> <output_file> [options]
```

- `<source_file>`: Path to the plaintext file to be encrypted.
- `<output_file>`: Path where the encrypted output will be stored.

**Example:**

```bash
./paranoia-encrypter.sh encrypt plaintext.txt encrypted_output
```

### Decryption

```bash
./paranoia-encrypter.sh decrypt <encrypted_file> <output_file> [options]
```

- `<encrypted_file>`: Path to the encrypted file.
- `<output_file>`: Path where the decrypted output will be stored.

**Example:**

```bash
./paranoia-encrypter.sh decrypt encrypted_output decrypted.txt
```

---

## 2. paranoia-encrypter-gov.sh

### Encryption

```bash
./paranoia-encrypter-gov.sh encrypt <source_file> <output_file_base> [options]
```

- `<source_file>`: Path to the plaintext file to be encrypted.
- `<output_file_base>`: Base name for output files (e.g., `encrypted_data`).

**Example:**

```bash
./paranoia-encrypter-gov.sh encrypt plaintext.txt encrypted_data
```

This will produce `encrypted_data.data` and `encrypted_data.hmac`.

### Decryption

```bash
./paranoia-encrypter-gov.sh decrypt <encrypted_file> <hmac_file> <output_file> <symmetric_key> [options]
```

- `<encrypted_file>`: Path to the encrypted `.data` file.
- `<hmac_file>`: Path to the `.hmac` file for integrity verification.
- `<output_file>`: Path where the decrypted output will be stored.
- `<symmetric_key>`: The symmetric key used for decryption.

**Example:**

```bash
./paranoia-encrypter-gov.sh decrypt encrypted_data.data encrypted_data.hmac decrypted.txt your-symmetric-key
```

---

## Logging

To enable centralized logging, use the `--central-logging` option.  
For Splunk integration, provide the `--splunk-url` and `--splunk-token`.

**Example:**

```bash
./paranoia-encrypter-gov.sh encrypt plaintext.txt encrypted_data --central-logging --splunk-url "https://splunk-hec-url:8088" --splunk-token "your-token"
```

---

## Security Considerations

- **Key Management**: Ensure that private keys and symmetric keys are stored securely.
- **Data Integrity**: Always verify HMACs during decryption to confirm data integrity.
- **Access Control**: Restrict access to the scripts and keys to authorized personnel only.

---

## License

This project is licensed under the MIT License.

---

## Acknowledgments

Special thanks to the contributors of the Paranoia Encrypter project.

---

For more details, visit the [Paranoia Encrypter GitHub repository](https://github.com/un1x01d/paranoid-encrypter).

