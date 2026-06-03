#!/bin/bash

# demo_ddos.sh
# Script interactivo para la exposición del RNF 2: Defensa contra DoS
# Requiere tener instalado 'ab' (apache2-utils)

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}   🚀 DEMOSTRACIÓN RNF 2: DEFENSA CONTRA DoS (Rate Limiting)   ${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# Verificar si 'ab' está instalado
if ! command -v ab &> /dev/null; then
    echo -e "${RED}Error: 'ab' (Apache Benchmark) no está instalado.${NC}"
    echo "Instálalo usando: sudo apt-get install apache2-utils (Linux) o brew install httpd (Mac)"
    exit 1
fi

echo -e "${YELLOW}--- FASE 1: ATAQUE SIN PROTECCIÓN ---${NC}"
echo -e "Asegúrate de que en ${CYAN}gateway/nginx.conf${NC} las líneas de ${GREEN}limit_req${NC} para /api/pets estén ${RED}COMENTADAS${NC}."
echo -e "Ejecuta 'docker exec Adopti_gateway nginx -s reload' si acabas de guardar."
echo ""
read -p "Presiona ENTER cuando estés listo para lanzar el ataque sin protección..."

echo -e "\n${RED}🔥 Lanzando ataque DoS (500 requests, 100 concurrentes) contra el endpoint de mascotas...${NC}"
# Usamos -k (KeepAlive) para mayor impacto, y redirigimos la salida temporalmente para mostrar solo el final
ab -n 500 -c 100 -k https://localhost/api/pets/stats 2>&1 | tee /tmp/ab_unprotected.log | grep -E "Time taken for tests|Failed requests|Non-2xx responses|Requests per second"

echo ""
echo -e "${RED}↑ Observa cómo el servidor intenta procesar todo, elevando el uso de CPU/RAM o demorando mucho.↑${NC}"
echo ""
echo -e "${YELLOW}--- FASE 2: ATAQUE CON PROTECCIÓN ACTIVA ---${NC}"
echo -e "Ahora ve a ${CYAN}gateway/nginx.conf${NC} y ${GREEN}DESCOMENTA${NC} (activa) las líneas de rate limiting:"
echo -e "   ${GREEN}limit_req zone=api_general burst=20 nodelay;${NC}"
echo -e "   ${GREEN}limit_req_status 429;${NC}"
echo -e "Luego, recarga el NGINX ejecutando: ${CYAN}docker exec Adopti_gateway nginx -s reload${NC}"
echo ""
read -p "Presiona ENTER cuando la protección esté activada y NGINX recargado..."

echo -e "\n${RED}🔥 Lanzando el MISMO ataque DoS contra el endpoint protegido...${NC}"
ab -n 500 -c 100 -k https://localhost/api/pets/stats 2>&1 | tee /tmp/ab_protected.log | grep -E "Time taken for tests|Failed requests|Non-2xx responses|Requests per second"

echo ""
echo -e "${GREEN}✅ ¡Ataque Mitigado!${NC}"
echo -e "De los 500 requests, la inmensa mayoría fueron rechazados inmediatamente por NGINX."
echo -e "Fíjate en el valor ${CYAN}'Non-2xx responses'${NC} de arriba. Esos son los bloqueos rápidos con código HTTP 429 (Too Many Requests)."
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}                    FIN DE LA DEMOSTRACIÓN                   ${NC}"
echo -e "${CYAN}============================================================${NC}"
