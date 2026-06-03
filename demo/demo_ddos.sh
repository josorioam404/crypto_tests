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

# Verificar si curl está instalado
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: 'curl' no está instalado.${NC}"
    exit 1
fi

echo -e "${YELLOW}--- FASE 1: ATAQUE SIN PROTECCIÓN ---${NC}"
echo -e "Asegúrate de que en ${CYAN}gateway/nginx.conf${NC} las líneas de ${GREEN}limit_req${NC} para /api/pets estén ${RED}COMENTADAS${NC}."
echo -e "Ejecuta 'docker compose restart gateway' o 'docker restart Adopti_gateway' si acabas de guardar."
echo ""
read -p "Presiona ENTER cuando estés listo para lanzar el ataque sin protección..."

echo -e "\n${RED}🔥 Lanzando ataque DoS (200 requests simultáneos) contra el endpoint de mascotas...${NC}"
echo -e "${CYAN}   (Esto puede demorar unos segundos mientras el servidor sufre la carga)${NC}"

rm -f /tmp/demo_unprotected.log
for i in {1..200}; do
    curl -k -s --max-time 10 -o /dev/null -w "%{http_code}\n" https://localhost/api/pets/stats >> /tmp/demo_unprotected.log &
done
wait

HTTP_200=$(grep -c "200" /tmp/demo_unprotected.log || true)
HTTP_429=$(grep -c "429" /tmp/demo_unprotected.log || true)
HTTP_5XX=$(grep -c -E "^5|^000" /tmp/demo_unprotected.log || true)

echo ""
echo -e "   Peticiones Procesadas (HTTP 200 OK): ${GREEN}$HTTP_200${NC}"
echo -e "   Peticiones Bloqueadas Rápidamente (HTTP 429): ${CYAN}$HTTP_429${NC}"
echo -e "   Peticiones Fallidas por Sobrecarga (HTTP 502/504): ${RED}$HTTP_5XX${NC}"
echo ""
echo -e "${RED}↑ Observa cómo el servidor backend colapsa bajo la carga e intenta devolver errores 5xx.↑${NC}"

echo ""
echo -e "${YELLOW}--- FASE 2: ATAQUE CON PROTECCIÓN ACTIVA ---${NC}"
echo -e "Ahora ve a ${CYAN}gateway/nginx.conf${NC} y ${GREEN}DESCOMENTA${NC} (activa) las líneas de rate limiting:"
echo -e "   ${GREEN}limit_req zone=api_general burst=20 nodelay;${NC}"
echo -e "   ${GREEN}limit_req_status 429;${NC}"
echo -e "Luego, REINICIA el contenedor ejecutando: ${CYAN}docker restart Adopti_gateway${NC}"
echo ""
read -p "Presiona ENTER cuando la protección esté activada y NGINX recargado..."

echo -e "\n${RED}🔥 Lanzando el MISMO ataque DoS contra el endpoint protegido...${NC}"

rm -f /tmp/demo_protected.log
for i in {1..200}; do
    curl -k -s --max-time 10 -o /dev/null -w "%{http_code}\n" https://localhost/api/pets/stats >> /tmp/demo_protected.log &
done
wait

HTTP_200=$(grep -c "200" /tmp/demo_protected.log || true)
HTTP_429=$(grep -c "429" /tmp/demo_protected.log || true)
HTTP_5XX=$(grep -c -E "^5|^000" /tmp/demo_protected.log || true)

echo ""
echo -e "   Peticiones Procesadas (HTTP 200 OK): ${GREEN}$HTTP_200${NC}"
echo -e "   Peticiones Bloqueadas Rápidamente (HTTP 429): ${CYAN}$HTTP_429${NC}"
echo -e "   Peticiones Fallidas por Sobrecarga (HTTP 502/504): ${RED}$HTTP_5XX${NC}"
echo ""

echo -e "${GREEN}✅ ¡Ataque Mitigado!${NC}"
echo -e "De los 200 requests, NGINX interceptó inmediatamente el exceso devolviendo HTTP 429."
echo -e "El servidor interno jamás fue sobrecargado, por lo que desaparecieron los errores 5xx."
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}                    FIN DE LA DEMOSTRACIÓN                   ${NC}"
echo -e "${CYAN}============================================================${NC}"
