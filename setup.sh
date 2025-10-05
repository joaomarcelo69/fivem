#!/usr/bin/env bash
set -euo pipefail

# Script de setup para baixar e extrair o FXServer (Linux) no diretório fxserver/
# Pode passar a variável FX_URL para usar um URL direto para fx.tar.xz

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FX_DIR="$WORKDIR/fxserver"
TMP_ARCHIVE="$WORKDIR/fx.tar.xz"

echo "Iniciando setup do FXServer..."

if [ -n "${FX_URL-}" ]; then
  URL="$FX_URL"
else
  echo "Procurando o build mais recente no runtime.fivem.net..."
  LISTING=$(curl -fsSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ || true)
  BUILD=$(echo "$LISTING" | grep -oP 'href="\K[0-9]+-[a-f0-9]+(?=/")' | sort -V | tail -n1 || true)
  if [ -z "$BUILD" ]; then
    echo "Não foi possível detectar automaticamente o build. Exportar FX_URL com o link direto para fx.tar.xz e reexecutar." >&2
    exit 1
  fi
  URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$BUILD/fx.tar.xz"
fi

echo "URL escolhida: $URL"

mkdir -p "$FX_DIR"
echo "Baixando..."
curl -L --fail -o "$TMP_ARCHIVE" "$URL"
echo "Extraindo para $FX_DIR..."
tar -xJf "$TMP_ARCHIVE" -C "$FX_DIR"
rm -f "$TMP_ARCHIVE"

if [ -f "$FX_DIR/run.sh" ]; then
  chmod +x "$FX_DIR/run.sh"
fi

echo "FXServer instalado em: $FX_DIR"
echo "Para iniciar o servidor: cd $FX_DIR && ./run.sh +exec $WORKDIR/server-data/server.cfg"
