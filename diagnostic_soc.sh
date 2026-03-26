#!/bin/bash
# ================================================================
# diagnostic_soc.sh — Diagnostic complet du SOC Lab
# ================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     DIAGNOSTIC COMPLET LAB SOC - L2 SIMAC                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"

echo -e "\n📦 1. ÉTAT DES CONTENEURS DOCKER"
echo "----------------------------------------"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}\t{{.Ports}}"

echo -e "\n💻 2. RESSOURCES SYSTÈME"
echo "----------------------------------------"
echo "Mémoire :"
free -h
echo -e "\nCPU : $(nproc) cœurs disponibles"
echo -e "\nvm.max_map_count : $(sysctl -n vm.max_map_count)"

echo -e "\n🌐 3. RÉSEAUX DOCKER"
echo "----------------------------------------"
docker network ls | grep -E "soc|NAME"

echo -e "\n🔌 4. MATRICE DE CONNECTIVITÉ"
echo "----------------------------------------"

# Test 1 : grafana → wazuh-manager:55000
echo -n "Test 1 — grafana → wazuh-manager:55000 : "
if docker exec grafana wget -qO- --timeout=5 http://wazuh-manager:55000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ JOIGNABLE${NC} (attendu: Joignable)"
else
    echo -e "${RED}✗ INJOIGNABLE${NC} (attendu: Joignable ← vérifier si wazuh-manager est healthy)"
fi

# Test 2 : thehive → wazuh-manager (DNS)
echo -n "Test 2 — thehive → wazuh-manager (DNS) : "
if docker exec thehive nslookup wazuh-manager > /dev/null 2>&1; then
    echo -e "${GREEN}✓ DNS OK${NC} (attendu: Joignable)"
elif docker exec thehive getent hosts wazuh-manager > /dev/null 2>&1; then
    echo -e "${GREEN}✓ DNS OK (getent)${NC} (attendu: Joignable)"
else
    echo -e "${RED}✗ DNS FAIL${NC} (attendu: Joignable)"
fi

# Test 3 : suricata → grafana (doit échouer)
echo -n "Test 3 — suricata → grafana (isolation) : "
if docker exec suricata wget -qO- --timeout=3 http://grafana:3000 > /dev/null 2>&1; then
    echo -e "${RED}✗ JOIGNABLE${NC} (attendu: Injoignable ← PROBLÈME D'ISOLATION)"
else
    echo -e "${GREEN}✓ INJOIGNABLE${NC} (attendu: Injoignable — isolation OK)"
fi

# Test 4 : wazuh-dashboard → suricata (doit échouer)
echo -n "Test 4 — wazuh-dashboard → suricata : "
if docker exec wazuh-dashboard nslookup suricata > /dev/null 2>&1; then
    echo -e "${RED}✗ JOIGNABLE${NC} (attendu: Injoignable ← PROBLÈME D'ISOLATION)"
else
    echo -e "${GREEN}✓ INJOIGNABLE${NC} (attendu: Injoignable — isolation OK)"
fi

echo -e "\n🌐 5. TESTS DES SERVICES WEB"
echo "----------------------------------------"
for service in "Wazuh Indexer|https://localhost:9200|9200" \
               "Grafana|http://localhost:3000/api/health|3000" \
               "TheHive|http://localhost:9000/api/v1/status|9000"; do
    name=$(echo $service | cut -d'|' -f1)
    url=$(echo $service | cut -d'|' -f2)
    result=$(curl -sk --max-time 5 "$url" 2>/dev/null | head -c 100)
    if [ -n "$result" ]; then
        echo -e "$name : ${GREEN}✓ Accessible${NC}"
    else
        echo -e "$name : ${RED}✗ Non accessible${NC}"
    fi
done

echo -e "\n🏥 6. HEALTHCHECKS"
echo "----------------------------------------"
for svc in wazuh-indexer wazuh-manager wazuh-dashboard cassandra thehive grafana suricata; do
    status=$(docker inspect --format='{{.State.Health.Status}}' $svc 2>/dev/null || echo "NON DÉMARRÉ")
    case $status in
        healthy)   echo -e "$svc : ${GREEN}✓ healthy${NC}" ;;
        unhealthy) echo -e "$svc : ${RED}✗ unhealthy${NC}" ;;
        starting)  echo -e "$svc : ${YELLOW}⏳ starting${NC}" ;;
        *)         echo -e "$svc : ${RED}✗ $status${NC}" ;;
    esac
done

echo -e "\n⚡ 7. CONSOMMATION RESSOURCES"
echo "----------------------------------------"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    FIN DU DIAGNOSTIC                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
