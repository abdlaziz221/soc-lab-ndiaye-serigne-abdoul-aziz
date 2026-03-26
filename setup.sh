#!/bin/bash
# ================================================================
# setup.sh — Script de déploiement SOC Lab L2 SIMAC
# Usage : bash setup.sh
# ================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     DÉPLOIEMENT SOC LAB — L2 SIMAC                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"

# ---------------------------------------------------------------
# 1. Prérequis système : vm.max_map_count pour Wazuh Indexer
#    Wazuh Indexer (OpenSearch/Elasticsearch) requiert cette valeur
#    pour gérer les index de logs sans crash OOM.
# ---------------------------------------------------------------
echo -e "\n${YELLOW}[1/5] Configuration vm.max_map_count (requis par Wazuh Indexer)...${NC}"

CURRENT_MAP=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
if [ "$CURRENT_MAP" -lt "262144" ]; then
    echo "  Valeur actuelle : $CURRENT_MAP → application de 262144"
    sudo sysctl -w vm.max_map_count=262144
    # Rendre persistant après reboot
    if ! grep -q "vm.max_map_count" /etc/sysctl.conf 2>/dev/null; then
        echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf > /dev/null
        echo -e "  ${GREEN}✓ Rendu persistant dans /etc/sysctl.conf${NC}"
    fi
else
    echo -e "  ${GREEN}✓ vm.max_map_count = $CURRENT_MAP (OK)${NC}"
fi

# ---------------------------------------------------------------
# 2. Vérification du fichier .env
# ---------------------------------------------------------------
echo -e "\n${YELLOW}[2/5] Vérification du fichier .env...${NC}"
if [ ! -f ".env" ]; then
    echo -e "  ${RED}✗ Fichier .env manquant !${NC}"
    echo "  Copie de .env.example vers .env..."
    cp .env.example .env
    echo -e "  ${YELLOW}⚠ Éditez .env avec vos vrais mots de passe avant de continuer.${NC}"
    exit 1
else
    echo -e "  ${GREEN}✓ .env présent${NC}"
fi

# ---------------------------------------------------------------
# 3. Création des répertoires nécessaires
# ---------------------------------------------------------------
echo -e "\n${YELLOW}[3/5] Création des répertoires...${NC}"
mkdir -p suricata/logs
mkdir -p suricata/rules
mkdir -p grafana/dashboards
mkdir -p thehive/config
mkdir -p rapport/captures
touch suricata/logs/.gitkeep
echo -e "  ${GREEN}✓ Structure créée${NC}"

# ---------------------------------------------------------------
# 4. Arrêt et nettoyage de l'ancienne stack (si elle existe)
# ---------------------------------------------------------------
echo -e "\n${YELLOW}[4/5] Arrêt de l'ancienne stack...${NC}"
docker compose down --remove-orphans 2>/dev/null || true

# Supprimer les réseaux conflictuels s'ils existent
for net in soc-backend soc-frontend soc-monitoring; do
    if docker network ls --format '{{.Name}}' | grep -q "^${net}$"; then
        echo "  Suppression du réseau : $net"
        docker network rm "$net" 2>/dev/null || true
    fi
done

# ---------------------------------------------------------------
# 5. Démarrage de la stack
# ---------------------------------------------------------------
echo -e "\n${YELLOW}[5/5] Démarrage de la stack SOC Lab...${NC}"
docker compose up -d

echo -e "\n${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     STACK DÉMARRÉE — Attente de l'état healthy     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Suivi en temps réel : ${YELLOW}docker compose ps${NC}"
echo -e "Logs complets      : ${YELLOW}docker compose logs -f${NC}"
echo ""
echo -e "${GREEN}Services accessibles :${NC}"
echo "  • Wazuh Dashboard  : https://localhost (admin / mot de passe .env)"
echo "  • Grafana          : http://localhost:3000"
echo "  • TheHive          : http://localhost:9000"
echo "  • Wazuh Indexer    : https://localhost:9200"
echo ""
echo -e "${YELLOW}⏳ Patience — Wazuh Indexer peut prendre 2-3 min à démarrer.${NC}"
echo -e "${YELLOW}   Suivi : watch -n5 'docker compose ps'${NC}"
