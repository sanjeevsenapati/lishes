#!/bin/bash

# Usage:
# ./extract_pfx.sh <certificate.pfx> <password>

PFX_FILE="$1"
PFX_PASSWORD="$2"

if [ -z "$PFX_FILE" ] || [ -z "$PFX_PASSWORD" ]; then
    echo "Usage: $0 <certificate.pfx> <password>"
    exit 1
fi

if [ ! -f "$PFX_FILE" ]; then
    echo "ERROR: PFX file not found: $PFX_FILE"
    exit 1
fi

BASE_NAME="${PFX_FILE%.*}"

PRIVATE_KEY="${BASE_NAME}.key"
CERTIFICATE="${BASE_NAME}.crt"
CA_CERT="${BASE_NAME}.ca.crt"

echo "=========================================="
echo " PFX Certificate Extraction"
echo "=========================================="
echo "Input: $PFX_FILE"
echo

# 1. Extract PRIVATE KEY
echo "[1/3] Extracting private key..."

openssl pkcs12 \
    -in "$PFX_FILE" \
    -passin "pass:$PFX_PASSWORD" \
    -nocerts \
    -nodes \
    -out "$PRIVATE_KEY"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract private key."
    exit 1
fi

chmod 600 "$PRIVATE_KEY"


# 2. Extract SERVER CERTIFICATE
echo "[2/3] Extracting server certificate..."

openssl pkcs12 \
    -in "$PFX_FILE" \
    -passin "pass:$PFX_PASSWORD" \
    -clcerts \
    -nokeys \
    -out "$CERTIFICATE"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract certificate."
    exit 1
fi


# 3. Extract CA / INTERMEDIATE CERTIFICATES
echo "[3/3] Extracting CA certificates..."

openssl pkcs12 \
    -in "$PFX_FILE" \
    -passin "pass:$PFX_PASSWORD" \
    -cacerts \
    -nokeys \
    -out "$CA_CERT"

if [ $? -ne 0 ]; then
    echo "WARNING: No CA certificates found in PFX."
fi


echo
echo "=========================================="
echo " Extraction Completed"
echo "=========================================="
echo
echo "Private Key : $PRIVATE_KEY"
echo "Certificate : $CERTIFICATE"
echo "CA Chain    : $CA_CERT"
echo

ls -lh "$PRIVATE_KEY" "$CERTIFICATE" "$CA_CERT" 2>/dev/null

echo
echo "Certificate Details:"
openssl x509 \
    -in "$CERTIFICATE" \
    -subject \
    -issuer \
    -dates \
    -noout