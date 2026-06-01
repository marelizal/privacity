#!/bin/bash

# Configuración de rutas de trabajo
DIR_TRABAJO="$HOME/mis-vpns"
CSV_FILE="$DIR_TRABAJO/lista_vpngate.csv"
OVPN_FILE="$DIR_TRABAJO/vpngate_activo.ovpn"

mkdir -p "$DIR_TRABAJO"
cd "$DIR_TRABAJO" || exit 1

# 1. Descargar la lista de servidores activos actual
echo "[-] Descargando lista actualizada de servidores VPN Gate..."
if ! wget -q -O "$CSV_FILE" http://www.vpngate.net/api/iphone/; then
    whiptail --title "Error" --msgbox "No se pudo descargar la lista de servidores. Revisa tu conexión a internet." 8 45
    exit 1
fi

# 2. Parsear el CSV para armar el menú de selección
# Filtramos las líneas útiles, removemos retornos de carro y tomamos IP (col 2), País (col 7) y Base64 (col 15)
echo "[-] Procesando servidores disponibles..."
mapfile -t LINEAS < <(tail -n +3 "$CSV_FILE" | head -n 40 | tr -d '\r' | awk -F, '$2!="" && $7!="" && $15!="" {print $2"|"$7"|"$15}')

if [ ${#LINEAS[@]} -eq 0 ]; then
    whiptail --title "Error" --msgbox "No se encontraron servidores válidos en la lista." 8 45
    exit 1
fi

# 3. Construir los argumentos para el menú de whiptail
OPCIONES=()
INDEX=0
for LINEA in "${LINEAS[@]}"; do
    IP=$(echo "$LINEA" | cut -d'|' -f1)
    PAIS=$(echo "$LINEA" | cut -d'|' -f2)
    OPCIONES+=("$INDEX" "[$PAIS] - IP: $IP")
    INDEX=$((INDEX + 1))
done

# 4. Mostrar la TUI al usuario
ELEGIDO=$(whiptail --title " Selector de VPN Gratuita (VPN Gate) " \
    --menu "Selecciona un servidor de la lista para conectarte:" 20 65 12 \
    "${OPCIONES[@]}" 3>&1 1>&2 2>&3)

# Si el usuario cancela o presiona ESC
if [ -z "$ELEGIDO" ]; then
    echo "[!] Operación cancelada por el usuario."
    exit 0
fi

# 5. Extraer la configuración Base64 elegida y decodificarla
LINEA_ELEGIDA="${LINEAS[$ELEGIDO]}"
DATA_BASE64=$(echo "$LINEA_ELEGIDA" | cut -d'|' -f3)

echo "[-] Generando archivo de configuración local..."
echo "$DATA_BASE64" | base64 -d > "$OVPN_FILE"

# 6. Inyectar el cifrado compatible para mitigar el error de negociación en OpenVPN 2.7+
if ! grep -q "data-ciphers" "$OVPN_FILE"; then
    echo "" >> "$OVPN_FILE"
    echo "data-ciphers DEFAULT:AES-128-CBC" >> "$OVPN_FILE"
fi

# 7. Lanzar OpenVPN de forma limpia en la terminal
clear
echo "=========================================================================="
echo " Conectando al servidor VPN seleccionado..."
echo " Presiona Ctrl + C para desconectarte y cerrar el túnel."
echo "=========================================================================="
echo ""

sudo openvpn --config "$OVPN_FILE"
