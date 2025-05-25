# 🧬 Paranoia Encrypter v3.0 – Red Team Edition

> **“Memory is the only safe place.”**

Paranoia Encrypter is a memory-only, multi-layer encryption utility built for red team engagements, adversarial simulations, and offensive security labs. It performs all operations in RAM — leaving no trace on disk.

---

## 🔐 Key Features

- **Triple-layer encryption**: `AES-256-CBC` → `ChaCha20` → `Camellia-256-CBC`
- **RSA-4096 ephemeral key wrapping**
- **Zero file-based key persistence**
- **No intermediate temp files or artifacts**
- **Base64-encoded output**, ideal for clipboard or transmission
- Compatible with **Bash**, **Linux**, **macOS**, **WSL**

---

## ⚙️ Usage

### 🔒 Encrypt

```bash
./paranoia-encrypter encrypt secret.txt locked.enc
```

Terminal Output:
```text
Encrypting...
Encryption done in 0m 2s
Encrypted saved to: locked.enc
Store these passwords securely:
AES: 6UbwE9Yq6vKsFXgQ...
ChaCha: cT4yXDQ0xgjMZYDz...
Camellia: QljWivh0biwCDtEr...
Paste this private key when decrypting:
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhki...
-----END PRIVATE KEY-----
```

---

### 🔓 Decrypt

```bash
./paranoia-encrypter decrypt locked.enc restored.txt
```

Terminal Prompts:
```text
AES password: ********
ChaCha20 password: ********
Camellia password: ********
Paste the private key (end with Ctrl-D):
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhki...
-----END PRIVATE KEY-----

Decryption done in 0m 1s
Decrypted saved to: restored.txt
```

---

## 📌 Example Workflow

```bash
# Encrypt a file
./paranoia-encrypter encrypt report.pdf encrypted.b64

# Save the printed passwords + private key (manually)
# Restore the file later
./paranoia-encrypter decrypt encrypted.b64 decrypted.pdf
```

---

## 🧠 Simulation Notes

- Designed for **controlled lab use**, red/blue team scenarios, or ephemeral storage
- Encryption/decryption runs entirely in memory
- Nothing is saved except the input/output files you specify
- Perfect for scenarios requiring **zero residual evidence**

---

## ⚠️ Disclaimer

This tool is intended for **ethical and authorized use only**.  
Use it in:
- Security research  
- Red/blue team simulations  
- Lab training environments  

**Unauthorized use is strictly prohibited.**

---

## 🛠 Requirements

- `bash`
- `openssl`
- Standard UNIX tools: `tr`, `head`, `tail`, `base64`

