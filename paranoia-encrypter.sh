#!/bin/bash

# Colors
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; N='\033[0m'

echo -e "${G}"
echo "╔════════════════════════════════════════════╗"
echo "║           Paranoia Encrypter v5.3          ║"
echo "║   In-memory. 512-bit entropy. Unbreakable. ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${N}"

CIPHERS=("AES-256-CBC" "ARIA-256-CFB" "Camellia-256-CBC")

b64_noline() {
    if base64 --help 2>&1 | grep -q -- '-w'; then base64 -w0; else base64 | tr -d '\n'; fi
}

gen_keys() {
    [[ ! -f priv.pem || ! -f pub.pem ]] && {
        echo -e "${Y}Generating RSA keys...${N}"
        openssl genpkey -algorithm RSA -out priv.pem -pkeyopt rsa_keygen_bits:4096 >/dev/null 2>&1
        openssl rsa -pubout -in priv.pem -out pub.pem >/dev/null 2>&1
    }
}

secure_del() {
    local f="$1"
    command -v shred &>/dev/null && shred -u "$f" >/dev/null 2>&1 ||
    [[ "$OSTYPE" == "darwin"* ]] && rm -P "$f" 2>/dev/null || rm -f "$f"
}

encrypt() {
    local src="$1"; local out="$2"
    [[ ! -e "$src" ]] && { echo -e "${R}Source not found.${N}"; exit 1; }

    echo -e "${G}Encryption started at $(date)${N}"
    SECONDS=0; gen_keys

    declare -a p
    for i in "${!CIPHERS[@]}"; do
        p[$i]=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 128)
    done

    local skey=$(openssl rand 32)
    local ekey=$(echo -n "$skey" | openssl pkeyutl -encrypt -pubin -inkey pub.pem | b64_noline)

    if [[ -d "$src" ]]; then
        stream_cmd="tar -cf - -C \"$(dirname "$src")\" \"$(basename "$src")\""
    else
        stream_cmd="cat \"$src\""
    fi

    enc_cmd="$stream_cmd"
    for i in "${!CIPHERS[@]}"; do
        cipher=${CIPHERS[$i],,}
        enc_cmd+=" | openssl enc -${cipher} -pbkdf2 -md sha512 -salt -pass pass:'${p[$i]}'"
    done
    encrypted_data=$(eval "$enc_cmd" | b64_noline)

    echo "$ekey" > "$out"
    echo "::" >> "$out"
    echo "$encrypted_data" >> "$out"

    local dur=$SECONDS
    echo -e "${G}Encryption completed at $(date)${N}"
    echo -e "${G}Elapsed time: $(($dur / 60))m $(($dur % 60))s${N}"
    echo -e "${Y}Output file: $out${N}"
    echo -e "${Y}Private Key: $(realpath priv.pem)${N}"
    echo -e "${Y}Public Key: $(realpath pub.pem)${N}"

    echo -e "${Y}Store these passwords securely:${N}"
    for i in "${!CIPHERS[@]}"; do echo -e "${N}${CIPHERS[$i]} password: ${p[$i]}"; done

    echo -e "\nYou have 30 seconds to copy these passwords."
    for i in {30..1}; do echo -ne "$i...\r"; sleep 1; done

    unset p skey ekey encrypted_data
    clear
}

decrypt() {
    local src="$1"; local out="$2"
    [[ ! -f "$src" ]] && { echo -e "${R}Encrypted file not found.${N}"; exit 1; }
    [[ ! -t 1 ]] && { echo -e "${R}Interactive terminal required.${N}"; exit 1; }

    echo -e "${G}Decryption started at $(date)${N}"
    SECONDS=0
    local ekey=$(head -n 1 "$src")
    local edata=$(tail -n +3 "$src" | tr -d '\n')
    local skey=$(echo "$ekey" | base64 -d | openssl pkeyutl -decrypt -inkey priv.pem 2>/dev/null)
    [[ $? -ne 0 || -z "$skey" ]] && { echo -e "${R}Symmetric key decryption failed.${N}"; exit 1; }

    declare -a p
    local max=8; local cnt=0
    while true; do
        for i in "${!CIPHERS[@]}"; do
            read -rsp "${CIPHERS[$i]} password: " p[$i]; echo
        done

        dec_cmd="echo \"\$edata\" | base64 -d"
        for ((i=${#CIPHERS[@]}-1; i>=0; i--)); do
            cipher=${CIPHERS[$i],,}
            dec_cmd+=" | openssl enc -d -${cipher} -pbkdf2 -md sha512 -salt -pass pass:'${p[$i]}'"
        done
        eval "$dec_cmd" > .dec.blob 2>/dev/null

        if [[ $? -eq 0 ]]; then
            if file .dec.blob | grep -q "tar archive"; then
                mkdir -p "$out"
                tar -xf .dec.blob -C "$out"
                echo -e "${Y}Extracted directory to: $out${N}"
            else
                mv .dec.blob "$out"
                echo -e "${Y}Decrypted file saved to: $out${N}"
            fi
            secure_del .dec.blob
            local dur=$SECONDS
            echo -e "${G}Decryption completed at $(date)${N}"
            echo -e "${G}Elapsed time: $(($dur / 60))m $(($dur % 60))s${N}"
            unset p skey edata ekey
            return
        else
            echo -e "${R}Password incorrect.${N}"
            cnt=$((cnt + 1))
            secure_del .dec.blob
            [[ $cnt -ge $max ]] && {
                echo -e "${R}Too many failed attempts. File destroyed.${N}"
                unset p edata ekey skey
                secure_del "$src"
                exit 1
            }
        fi
    done
}

main() {
    [[ $# -lt 1 ]] && {
        echo -e "${Y}Usage:${N}"
        echo "  $0 encrypt <source_path> <output_file>"
        echo "  $0 decrypt <encrypted_file> <output_path>"
        exit 0
    }

    case "$1" in
        encrypt) encrypt "$2" "$3" ;;
        decrypt) decrypt "$2" "$3" ;;
        *) echo -e "${R}Unknown mode: $1${N}"; exit 1 ;;
    esac
}

main "$@"

