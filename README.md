# 🛡️ Paranoia Encrypter v5.3

> **In-memory. 512-bit entropy. Unbreakable.**

Paranoia Encrypter is a multi-layered encryption tool built with native Linux/macOS utilities. It encrypts files or directories using three modern ciphers in sequence, and stores only base64-encoded ciphertext and an RSA-encrypted symmetric key. All secrets are kept in memory and discarded securely after use.

---

## ⚙️ Features

- 🔐 3-layer encryption using:
  - AES-256-CBC  
  - ARIA-256-CFB  
  - Camellia-256-CBC  
- 🔑 4096-bit RSA keypair for securing symmetric keys  
- 🧠 All data handled in-memory; no temp files except `.dec.blob`  
- 🗃 Supports encrypting both files and directories  
- 🗝 Passwords shown **once only**, self-clearing after 30 seconds  
- 💥 8 failed decryption attempts = auto file deletion  

---

## 📦 Requirements

- `openssl`  
- `base64`  
- `tar`  
- macOS or Linux  

---

## 🚀 Usage

### Encrypt

```
./paranoia.sh encrypt <source_path> <output_file>
```

### Decrypt

```
./paranoia.sh decrypt <encrypted_file> <output_path>
```

---

## 🧪 Example Encryption Report

```
./paranoia.sh encrypt ./classified_docs/ safe_output.penc
```

**Terminal Output:**
```
╔════════════════════════════════════════════╗
║           Paranoia Encrypter v5.3          ║
║   In-memory. 512-bit entropy. Unbreakable. ║
╚════════════════════════════════════════════╝

Generating RSA keys...

Encryption started at Mon Jun  9 12:03:48 EDT 2025
Encryption completed at Mon Jun  9 12:03:49 EDT 2025
Elapsed time: 0m 1s
Output file: safe_output.penc
Private Key: /home/user/priv.pem
Public Key:  /home/user/pub.pem

Store these passwords securely:
AES-256-CBC password:      zApH2wVNMEjxlBSGBdrtQo73W8qMYyzEk9eqRQwqI6ONIf5RhU3YzPHCgZom7K0RZsSJMgz6zH8ZbGhCcjWmPtRx7W6Ow4zoR9AWX7RIdMgRU1xN1YMpK4H5H6fnG4wX
ARIA-256-CFB password:     xbBDqLvpFLntBaAvMk0S0H9MpKZOTX3LUXKkXPIPOR3E2bG4GEQ1AKgRtXBzuYr7gczVEbZLYOuzpqTcXmhZGr2uBkwpI4U3AC9kwj5vazCLmI7OW5DzrRSpY0Gdc8iW
Camellia-256-CBC password: 3P8h8rFQszkCu57WuyzDjPKGvhsYltBA1YksZPYmO4nR8YAkYQ2DbHkVY7m7ak0NvXiz8fTqTzLRAEMLzPtvvZns0e3w5d8Am6O7ex9lDoUIghgSnB2YF1zgxEYZ6KkQ

You have 30 seconds to copy these passwords.
30...
```

> ⚠️ **Passwords are not recoverable.** They are shown once and erased from memory. Copy them securely.

---

## 📁 Output Structure

Encrypted file format:
```
<base64-encrypted symmetric key>
::
<base64-encrypted data blob>
```

---

## 🧹 Cleanup

To remove files securely using native tools:

```
# macOS
rm -P <file>

# Linux fallback
rm -f <file>
```

To regenerate RSA keys:

```
rm priv.pem pub.pem
```

---

## 📜 License

MIT — Use at your own paranoia level.
