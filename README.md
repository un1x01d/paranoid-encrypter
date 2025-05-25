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
./paranoia-encrypter encrypt source_file.txt encrypted_output.enc
```

- Generates fresh RSA keys in memory
- Encrypts the input in 3 layers
- Outputs:
  - Encrypted symmetric key (base64)
  - Encrypted payload (base64)
  - AES / ChaCha / Camellia passwords
  - RSA private key (pasted manually for recovery)

---

### 🔓 Decrypt

```bash
./paranoia-encrypter decrypt encrypted_output.enc restored_file.txt
```

- Requires:
  - The original AES / ChaCha / Camellia passwords
  - The corresponding RSA private key
- Outputs decrypted content to the destination file

---

## 🧠 Simulation Notes

- Built for **controlled lab use**, CTFs, red team drops, or secure transport
- Operates entirely in RAM
- Leaves **no residual trace** of encryption keys or decrypted data
- Safe to embed in ephemeral containers, RAM disks, or live shells

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

