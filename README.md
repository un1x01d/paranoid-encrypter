# 🧩 Micro DNS – Minimal UDP DNS Resolver

A lightweight, user-level DNS resolver in a single Go binary. It resolves `A`, `CNAME`, `TXT`, and `MX` records from a local zone file, supports hot reloading, and optionally falls back to external DNS servers (UDP-only). Logs all queries and responses to stdout.

---

## ✨ Features

- ✅ Prebuilt binary included (`dnsresolver`)
- ✅ Fully user-space (no root required)
- ✅ DNS zone file syntax (like BIND)
- ✅ Supports `A`, `CNAME`, `TXT`, `MX` records
- ✅ Logs all queries and responses
- ✅ Hot reloads zone file on change
- ✅ Optional UDP fallback (e.g. `8.8.8.8`)
- ✅ CLI flags override `config.yaml`
- ✅ Docker-ready, supports `PORT` env var

---

## 📁 Key Files

| File           | Purpose                                       |
|----------------|-----------------------------------------------|
| `dnsresolver`  | Prebuilt binary resolver                      |
| `Dockerfile`   | Builds minimal Alpine container               |
| `config.yaml`  | Resolver configuration (port, zone file, etc) |
| `zones.txt`    | DNS records in BIND-style format              |
| `src/main.go`  | Go source code for the resolver               |
| `README.md`    | Project overview and instructions             |

---

## ⚙️ Configuration

### `config.yaml`
```yaml
listen_port: "1053"
hosts_file: "zones.txt"
log_level: "info"
poll_freq: 5
fallback_dns: "8.8.8.8:53"
```

### `zones.txt`
```text
example.local.    300 IN A     127.0.0.1
router.home.      300 IN A     192.168.1.1
alias.local.      300 IN CNAME example.local.
text.example.     300 IN TXT   "This is a test TXT record"
mail.example.     300 IN MX    10 mailserver.local.
```

---

## 🚀 Usage

### Run Prebuilt Binary
```bash
./dnsresolver
```

### Run with CLI Overrides
```bash
./dnsresolver --port 1053 --zones zones.txt --fallback 1.1.1.1:53 --poll 10
```

---

## 🐳 Docker Support

### Build Docker Image
```bash
docker build -t micro-dns .
```

### Run with Default Port (1053)
```bash
docker run -p 1053:1053/udp --rm micro-dns
```

### Run with Custom Port via `PORT` Environment Variable
```bash
docker run -e PORT=5300 -p 5300:5300/udp --rm micro-dns
```

---

## 🧪 Testing

### With `dig` (recommended)
```bash
dig @127.0.0.1 -p 1053 example.local A
dig @127.0.0.1 -p 1053 alias.local CNAME
dig @127.0.0.1 -p 1053 text.example TXT
dig @127.0.0.1 -p 1053 mail.example MX
```

### With `nslookup` (only works on port 53)
```bash
sudo ./dnsresolver --port 53
nslookup example.local 127.0.0.1
```

---

## ⚙️ Optional: Build From Source

```bash
cd src
go mod tidy
go build -o ../dnsresolver main.go
```

---

## 📜 License

MIT — do whatever you want.

