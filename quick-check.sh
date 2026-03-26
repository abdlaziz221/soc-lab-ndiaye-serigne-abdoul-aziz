#!/bin/bash
# quick-check.sh — Vérification rapide SOC Lab
# Usage: bash quick-check.sh

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         SOC LAB — VÉRIFICATION RAPIDE                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Compteurs
green_count=0
red_count=0

check() {
    local name=$1
    local cmd=$2
    echo -n "✓ $name ... "
    
    if eval "$cmd" &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        ((green_count++))
    else
        echo -e "${RED}FAIL${NC}"
        ((red_count++))
    fi
}

echo "1️⃣  INFRASTRUCTURE DOCKER"
echo "─────────────────────────────────────"
check "Docker CLI" "docker --version"
check "Docker Compose" "docker compose --version"
check "Docker daemon" "docker ps"
echo ""

echo "2️⃣  SERVICES ACTIFS"
echo "─────────────────────────────────────"
check "wazuh-indexer" "docker ps | grep -q wazuh-indexer"
check "wazuh-manager" "docker ps | grep -q wazuh-manager"
check "wazuh-dashboard" "docker ps | grep -q wazuh-dashboard"
check "grafana" "docker ps | grep -q grafana"
check "thehive" "docker ps | grep -q thehive"
check "cassandra" "docker ps | grep -q cassandra"
echo ""

echo "3️⃣  ACCESSIBILITÉ RÉSEAU"
echo "─────────────────────────────────────"
sleep 2  # Laisser le temps aux services

# Indexer HTTPS
echo -n "✓ Wazuh Indexer (9200/HTTPS) ... "
if curl -sk https://localhost:9200 2>/dev/null | grep -q "OpenSearch"; then
    echo -e "${GREEN}OK${NC}"
    ((green_count++))
else
    echo -e "${YELLOW}STARTING${NC}"
fi

# Grafana HTTP
echo -n "✓ Grafana (3000/HTTP) ... "
if curl -s http://localhost:3000/api/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}OK${NC}"
    ((green_count++))
else
    echo -e "${YELLOW}STARTING${NC}"
fi

# TheHive HTTP
echo -n "✓ TheHive (9000/HTTP) ... "
if curl -s http://localhost:9000/ 2>/dev/null | grep -q -i "thehive"; then
    echo -e "${GREEN}OK${NC}"
    ((green_count++))
else
    echo -e "${YELLOW}STARTING${NC}"
fi

echo ""
echo "4️⃣  STOCKAGE PERSISTANT"
echo "─────────────────────────────────────"
check "Volumes créés" "docker volume ls | grep -q wazuh"
check "Logs Suricata" "[ -d suricata/logs ]"
echo ""

echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 RÉSULTAT"
echo "─────────"
echo -e "   ${GREEN}✓ Réussis${NC} : $green_count"
echo -e "   ${RED}✗ Échoués${NC}  : $red_count"
echo ""

if [ $red_count -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les services sont prêts !${NC}"
    echo ""
    echo "Accès rapides :"
    echo "  • Wazuh Dashboard  → https://localhost"
    echo "  • Grafana          → http://localhost:3000"
    echo "  • TheHive          → http://localhost:9000"
    echo "  • Indexer API      → https://localhost:9200"
else
    echo -e "${YELLOW}⚠️  Certains services ne sont pas encore prêts.${NC}"
    echo ""
    echo "Options :"
    echo "  • Attendre 30 sec et relancer ce script"
    echo "  • docker compose logs -f    (voir logs en temps réel)"
    echo "  • bash diagnostic_soc.sh    (diagnostic complet)"
fi
echo ""
