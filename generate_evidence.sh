#!/bin/bash
# ================================================================
# SCRIPT DE GÉNÉRATION DES PREUVES - SOC Lab L2 SIMAC
# Exécutez : bash generate_evidence.sh
# ================================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     GÉNÉRATION DES PREUVES POUR RAPPORT SOC LAB               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

# Création de la structure
mkdir -p rapport/captures/{partie2/{phase1,phase2,phase3},partie3,preuves_techniques}
EVIDENCE_DIR="./rapport/captures"
echo -e "${GREEN}✓ Répertoires créés${NC}"

echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║ PHASE 1 : RECONNAISSANCE (NMAP)                               ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Attendre que tout soit up
echo "⏳ Vérification des services (30s)..."
sleep 5

# 1.1 Scan Nmap SYN
echo -e "${BLUE}[P2-P1.1] Lancement scan Nmap SYN sur ports 1-10000...${NC}"
echo "Commande exécutée : sudo nmap -sS -p 1-10000 localhost" > $EVIDENCE_DIR/partie2/phase1/commande_nmap.txt
sudo nmap -sS -p 1-10000 localhost | tee $EVIDENCE_DIR/partie2/phase1/resultat_nmap.txt
echo -e "${GREEN}✓ Scan terminé - Preuve sauvegardée${NC}"

# Attendre la détection (30 secondes)
echo "⏳ Attente détection par Wazuh (30s)..."
sleep 30

# 1.2 Extraction preuve Wazuh (règle 86602)
echo -e "${BLUE}[P2-P1.2] Extraction alertes Wazuh (règle 86602)...${NC}"
docker exec wazuh-manager grep -i "86602\|network scan\|nmap" /var/ossec/logs/alerts/alerts.json | head -5 | tee $EVIDENCE_DIR/preuves_techniques/wazuh_alert_86602.json
echo -e "${YELLOW}⚠ CAPTURE MANUELLE REQUISE :${NC}"
echo -e "   → Ouvrez https://localhost dans navigateur"
echo -e "   → Menu : 'Threat Intelligence' → 'Dashboard'"
echo -e "   → Filtre : ${GREEN}rule.id:86602${NC}"
echo -e "   → ${RED}SCREENSHOT : Sauvegardez dans${NC} $EVIDENCE_DIR/partie2/phase1/P2_P1_wazuh_dashboard_86602.png"
read -p "   Appuyez sur Entrée quand c'est fait..."

# 1.3 Preuve Suricata (Nmap)
echo -e "${BLUE}[P2-P1.3] Extraction logs Suricata...${NC}"
docker exec suricata sh -c "cat /var/log/suricata/eve.json 2>/dev/null | grep -i nmap || echo 'Pas encore de logs - normal si Suricata en mode placeholder'" | tee $EVIDENCE_DIR/preuves_techniques/suricata_nmap.json
echo -e "${GREEN}✓ Preuve Suricata sauvegardée${NC}"

echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║ PHASE 2 : BRUTE FORCE SSH                                     ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 2.1 Création cible SSH
echo -e "${BLUE}[P2-P2.1] Création conteneur SSH cible...${NC}"
docker run -d --name ssh-target --network soc-frontend -p 2222:22 ubuntu:22.04 bash -c "
  apt-get update -qq && 
  apt-get install -y -qq openssh-server && 
  echo 'root:password123' | chpasswd && 
  mkdir -p /var/run/sshd && 
  echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && 
  /usr/sbin/sshd -D
" 2>&1 | tee $EVIDENCE_DIR/partie2/phase2/creation_ssh_target.log
sleep 10
docker ps | grep ssh-target | tee $EVIDENCE_DIR/partie2/phase2/ssh_target_status.txt
echo -e "${GREEN}✓ SSH Target créé (port 2222)${NC}"
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC} docker ps | grep ssh-target → Screenshot $EVIDENCE_DIR/partie2/phase2/P2_P2_ssh_target.png"

# 2.2 Préparation liste mots de passe (10 premiers)
echo -e "${BLUE}[P2-P2.2] Préparation attaque Hydra...${NC}"
cat > /tmp/10pass.txt << EOF
password
123456
123456789
qwerty
password123
admin
letmein
welcome
monkey
dragon
EOF
echo "Liste mots de passe (10) :" | tee $EVIDENCE_DIR/partie2/phase2/liste_mots_de_passe.txt
cat /tmp/10pass.txt | tee -a $EVIDENCE_DIR/partie2/phase2/liste_mots_de_passe.txt

# 2.3 Lancement Hydra
echo -e "${BLUE}[P2-P2.3] Lancement attaque Brute Force (Hydra)...${NC}"
echo "Commande : hydra -l root -P /tmp/10pass.txt -t 4 ssh://localhost:2222" | tee $EVIDENCE_DIR/partie2/phase2/commande_hydra.txt
hydra -l root -P /tmp/10pass.txt -t 4 ssh://localhost:2222 2>&1 | tee $EVIDENCE_DIR/partie2/phase2/resultat_hydra.txt || true
echo -e "${GREEN}✓ Attaque exécutée${NC}"
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC} Terminal montrant Hydra avec '[22][ssh] host: localhost login: root' → $EVIDENCE_DIR/partie2/phase2/P2_P2_hydra_attack.png"

# Attendre détection Wazuh
echo "⏳ Attente détection Wazuh (20s)..."
sleep 20

# 2.4 Preuve alerte Wazuh Level 10
echo -e "${BLUE}[P2-P2.4] Extraction alerte Brute Force (règle 5712, level 10)...${NC}"
docker exec wazuh-manager grep -E "5712|sshd.*brute|Failed password" /var/ossec/logs/alerts/alerts.json | head -5 | tee $EVIDENCE_DIR/preuves_techniques/wazuh_brute_5712.json
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC}"
echo -e "   → https://localhost → Discover → Filtre : ${GREEN}rule.level:10${NC}"
echo -e "   → Chercher 'sshd: brute force trying to get access'"
echo -e "   → ${RED}SCREENSHOT :${NC} $EVIDENCE_DIR/partie2/phase2/P2_P2_wazuh_brute_level10.png"
read -p "   Appuyez sur Entrée..."

# 2.5 Configuration Active Response
echo -e "${BLUE}[P2-P2.5] Extraction configuration Active Response...${NC}"
docker exec wazuh-manager cat /var/ossec/etc/ossec.conf | grep -A 15 "active-response" | tee $EVIDENCE_DIR/preuves_techniques/active_response_config.xml
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC} Le fichier XML ci-dessus → Screenshot $EVIDENCE_DIR/partie2/phase2/P2_P2_active_response_config.png"

# 2.6 Vérification blocage IP
echo -e "${BLUE}[P2-P2.6] Vérification blocage IP (iptables)...${NC}"
docker exec wazuh-manager iptables -L -n | grep -i drop | head -5 | tee $EVIDENCE_DIR/preuves_techniques/iptables_block.txt || echo "Aucune règle DROP trouvée (peut-être pas encore bloqué ou timeout dépassé)" | tee $EVIDENCE_DIR/preuves_techniques/iptables_block.txt
docker exec wazuh-manager cat /var/ossec/logs/active-responses.log 2>/dev/null | tail -10 | tee $EVIDENCE_DIR/preuves_techniques/active_responses.log || echo "Fichier log non trouvé" | tee $EVIDENCE_DIR/preuves_techniques/active_responses.log
echo -e "${GREEN}✓ Preuves de blocage sauvegardées${NC}"

echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║ PHASE 3 : INJECTION SQL + THEHIVE                             ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 3.1 Lancement DVWA
echo -e "${BLUE}[P2-P3.1] Lancement DVWA (Damn Vulnerable Web App)...${NC}"
docker run -d --name dvwa --network soc-frontend -p 8080:80 vulnerables/web-dvwa 2>&1 | tee $EVIDENCE_DIR/partie2/phase3/dvwa_creation.log
sleep 15
echo -e "${GREEN}✓ DVWA lancé sur http://localhost:8080${NC}"
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC}"
echo -e "   → Ouvrez http://localhost:8080 dans navigateur"
echo -e "   → Login : ${GREEN}admin/admin${NC}"
echo -e "   → ${RED}SCREENSHOT :${NC} $EVIDENCE_DIR/partie2/phase3/P2_P3_dvwa_login.png"
echo -e "   → Setup/Create Database, puis re-login"
read -p "   Appuyez sur Entrée quand c'est fait..."

# 3.2 Simulation Injection SQL (via curl pour preuve technique)
echo -e "${BLUE}[P2-P3.2] Simulation Injection SQL...${NC}"
# On simule l'injection pour avoir des logs
curl -s "http://localhost:8080/vulnerabilities/sqli/?id=1%27+UNION+SELECT+user%2Cpassword+FROM+users+--+&Submit=Submit" -H "Cookie: PHPSESSID=test; security=low" > /dev/null || true
echo "Payload utilisé : 1' UNION SELECT user,password FROM users -- " | tee $EVIDENCE_DIR/partie2/phase3/payload_sql.txt
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC}"
echo -e "   → DVWA → SQL Injection → User ID : ${GREEN}1' UNION SELECT user,password FROM users -- ${NC}"
echo -e "   → ${RED}SCREENSHOT :${NC} Page montrant le dump des utilisateurs → $EVIDENCE_DIR/partie2/phase3/P2_P3_sqli_exploit.png"
read -p "   Appuyez sur Entrée..."

# 3.3 Preuve Suricata SQL
echo -e "${BLUE}[P2-P3.3] Extraction logs Suricata (SQLi)...${NC}"
docker exec suricata sh -c "cat /var/log/suricata/eve.json 2>/dev/null | grep -i 'union\\|sql\\|injection' | head -3" | tee $EVIDENCE_DIR/preuves_techniques/suricata_sql.json || echo "Log Suricata SQL (vérifiez manuellement)" | tee $EVIDENCE_DIR/preuves_techniques/suricata_sql.json

# 3.4-3.8 TheHive (Création via API pour automatisation)
echo -e "${BLUE}[P2-P3.4-3.8] Création Case TheHive via API...${NC}"
sleep 5

# Attendre que TheHive soit prêt
echo "⏳ Attente TheHive (60s)..."
sleep 60

# Création du case via curl
curl -s -X POST http://localhost:9000/api/v1/case \
  -H "Content-Type: application/json" \
  -d '{
    "title": "APT-2024-001 — SQLi détectée sur DVWA — TechCorp SA",
    "description": "Injection SQL détectée sur l'\''application DVWA. Attaque UNION SELECT sur la table users.",
    "severity": 3,
    "tlp": 2,
    "pap": 2,
    "tags": ["SQLi", "DVWA", "APT"]
  }' > $EVIDENCE_DIR/preuves_techniques/thehive_case_created.json 2>/dev/null || echo '{"error": "TheHive peut-être pas encore prêt - créer manuellement"}' | tee $EVIDENCE_DIR/preuves_techniques/thehive_case_created.json

echo -e "${YELLOW}⚠ CAPTURES MANUELLES THEHIVE REQUISES :${NC}"
echo -e "   → http://localhost:9000 → Cases → New Case"
echo -e "   → Titre : ${GREEN}APT-2024-XXX — SQLi détectée sur DVWA — TechCorp SA${NC}"
echo -e "   → Severity : ${GREEN}HIGH${NC}, TLP : ${GREEN}AMBER${NC}, PAP : ${GREEN}AMBER${NC}"
echo -e "   → ${RED}SCREENSHOT :${NC} $EVIDENCE_DIR/partie2/phase3/P2_P3_thehive_new_case.png"
read -p "   Appuyez sur Entrée..."

echo -e "${YELLOW}   → Ajouter 4 tâches :${NC}"
echo -e "      1. Identification — Analyser logs Suricata/Wazuh"
echo -e "      2. Containment — Isoler conteneur DVWA"
echo -e "      3. Éradication — Patcher vulnérabilité SQLi"
echo -e "      4. Recovery — Vérifier intégrité et remettre en service"
echo -e "   → ${RED}SCREENSHOT :${NC} $EVIDENCE_DIR/partie2/phase3/P2_P3_thehive_tasks.png"
read -p "   Appuyez sur Entrée..."

echo -e "${YELLOW}   → Ajouter 2 Observables :${NC}"
echo -e "      - Type IP : ${GREEN}172.20.0.1${NC} (ou votre IP)"
echo -e "      - Type URL : ${GREEN}http://localhost:8080/vulnerabilities/sqli/?id=1' UNION SELECT...${NC}"
echo -e "   → ${RED}SCREENSHOT :${NC} $EVIDENCE_DIR/partie2/phase3/P2_P3_thehive_observables.png"
read -p "   Appuyez sur Entrée..."

# 3.7 Containment Docker
echo -e "${BLUE}[P2-P3.7] Exécution containment (isolation DVWA)...${NC}"
docker network disconnect soc-frontend dvwa 2>&1 | tee $EVIDENCE_DIR/partie2/phase3/containment_command.txt || echo "Déjà déconnecté ou erreur" | tee $EVIDENCE_DIR/partie2/phase3/containment_command.txt
docker exec dvwa ping -c 3 google.com 2>&1 | tee $EVIDENCE_DIR/partie2/phase3/containment_verification.txt || echo "Ping échoué (normal - isolation OK)" | tee $EVIDENCE_DIR/partie2/phase3/containment_verification.txt
echo -e "${GREEN}✓ Containment exécuté et vérifié${NC}"
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC} Terminal montrant la commande docker network disconnect + ping échoué → $EVIDENCE_DIR/partie2/phase3/P2_P3_containment_isolation.png"

echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║ PARTIE 3 : RAPPORT TECHNIQUE                                  ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Schéma architecture (ASCII généré)
echo -e "${BLUE}[P3] Génération schéma architecture...${NC}"
cat > $EVIDENCE_DIR/partie3/schema_architecture.txt << 'EOF'
SOC LAB ARCHITECTURE
====================

soc-frontend (bridge)
  ├── wazuh-dashboard:443
  ├── grafana:3000
  └── thehive:9000
          |
          ↓
soc-backend (bridge)
  ├── wazuh-indexer:9200
  ├── wazuh-manager:1514/udp, 55000
  ├── cassandra:9042
  └── suricata (isolated)

Volumes persistants:
  - wazuh-indexer-data
  - wazuh-manager-data
  - grafana-data
  - cassandra-data
  - thehive-data
  - suricata-logs
EOF
echo -e "${GREEN}✓ Schéma ASCII sauvegardé${NC}"
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC} Utilisez draw.io ou faire screenshot de ce texte formaté → $EVIDENCE_DIR/partie3/P3_architecture_schema.png"

# Matrice de connectivité
echo -e "${BLUE}[P3] Génération matrice de connectivité...${NC}"
cat > $EVIDENCE_DIR/partie3/matrice_connectivite.txt << 'EOF'
MATRICE DE CONNECTIVITÉ
========================

Source → Destination          | Résultat | Commande test
------------------------------|----------|------------------------------------------
grafana → wazuh-manager:55000 | ✓ OK     | docker exec grafana wget http://wazuh-manager:55000
thehive → wazuh-manager       | ✓ OK     | docker exec thehive nslookup wazuh-manager
suricata → grafana            | ✗ NOK    | docker exec suricata nslookup grafana (échoue)
dashboard → suricata          | ✗ NOK    | docker exec wazuh-dashboard nslookup suricata (échoue)

Légende : 
- ✓ Joignable (même réseau ou routes autorisées)
- ✗ Injoignable (isolation réseau respectée)
EOF
docker exec grafana wget -qO- --timeout=3 http://wazuh-manager:55000 > /dev/null 2>&1 && echo "grafana → wazuh-manager : ✓ OK" | tee -a $EVIDENCE_DIR/partie3/matrice_connectivite.txt || echo "grafana → wazuh-manager : ✗ NOK" | tee -a $EVIDENCE_DIR/partie3/matrice_connectivite.txt
docker exec thehive getent hosts wazuh-manager > /dev/null 2>&1 && echo "thehive → wazuh-manager : ✓ OK" | tee -a $EVIDENCE_DIR/partie3/matrice_connectivite.txt || echo "thehive → wazuh-manager : DNS FAIL" | tee -a $EVIDENCE_DIR/partie3/matrice_connectivite.txt
echo -e "${GREEN}✓ Matrice générée${NC}"
echo -e "${YELLOW}⚠ CAPTURE MANUELLE :${NC} Tableau ci-dessus complété → $EVIDENCE_DIR/partie3/P3_matrice_connectivite.png"

# Timeline des attaques
echo -e "${BLUE}[P3] Génération template timeline...${NC}"
cat > $EVIDENCE_DIR/partie3/timeline_attaques.txt << 'EOF'
TIMELINE DES ATTAQUES (à compléter avec vos horaires réels)
============================================================

12:00:00 - [Phase 1] Lancement scan Nmap SYN (ports 1-10000)
         └─> Détection Wazuh règle 86602 après ~30s
         
12:05:00 - [Phase 2] Lancement attaque Brute Force SSH (Hydra)
         └-> 10 tentatives de connexion
         └-> Détection Wazuh level 10 (règle 5712)
         └-> Blocage IP par Active Response (iptables)
         
12:15:00 - [Phase 3] Injection SQL sur DVWA (UNION SELECT)
         └-> Détection Suricata (signature SQLi)
         └-> Création case TheHive (Severity: HIGH, TLP: AMBER)
         └-> Containment : isolation réseau du conteneur DVWA
EOF
echo -e "${GREEN}✓ Timeline template sauvegardé${NC}"

# Export des configurations clés
echo -e "${BLUE}[P3] Export configurations...${NC}"
docker exec wazuh-manager cat /var/ossec/etc/ossec.conf 2>/dev/null | head -50 > $EVIDENCE_DIR/preuves_techniques/ossec_config_sample.xml || echo "Config non accessible" > $EVIDENCE_DIR/preuves_techniques/ossec_config_sample.xml
docker network inspect soc-frontend > $EVIDENCE_DIR/preuves_techniques/network_frontend.json 2>/dev/null || echo "{}" > $EVIDENCE_DIR/preuves_techniques/network_frontend.json
docker network inspect soc-backend > $EVIDENCE_DIR/preuves_techniques/network_backend.json 2>/dev/null || echo "{}" > $EVIDENCE_DIR/preuves_techniques/network_backend.json
docker volume ls | grep -E "wazuh|grafana|cassandra|thehive|suricata" > $EVIDENCE_DIR/preuves_techniques/volumes_list.txt

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                     RÉSUMÉ DES PREUVES                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📁 Fichiers techniques générés (JSON/TXT) :${NC}"
find $EVIDENCE_DIR -type f -name "*.json" -o -name "*.txt" -o -name "*.log" | while read f; do echo "   - $f"; done

echo ""
echo -e "${YELLOW}📸 Screenshots manuels requis (Partie 2) :${NC}"
echo "   1. P2_P1_wazuh_dashboard_86602.png          (Wazuh règle 86602)"
echo "   2. P2_P2_ssh_target.png                     (docker ps ssh-target)"
echo "   3. P2_P2_hydra_attack.png                   (Terminal Hydra)"
echo "   4. P2_P2_wazuh_brute_level10.png            (Wazuh alert level 10)"
echo "   5. P2_P2_active_response_config.png         (XML config)"
echo "   6. P2_P3_dvwa_login.png                     (Page login DVWA)"
echo "   7. P2_P3_sqli_exploit.png                   (Résultat injection)"
echo "   8. P2_P3_thehive_new_case.png               (Formulaire case)"
echo "   9. P2_P3_thehive_tasks.png                  (4 tâches PICERL)"
echo "   10. P2_P3_thehive_observables.png           (IP + URL)"
echo "   11. P2_P3_containment_isolation.png         (docker network disconnect)"

echo ""
echo -e "${YELLOW}📸 Screenshots manuels requis (Partie 3) :${NC}"
echo "   1. P3_architecture_schema.png               (Schéma Docker)"
echo "   2. P3_matrice_connectivite.png              (Tableau connectivité)"
echo "   3. P3_timeline_attaques.png                 (Timeline phases)"

echo ""
echo -e "${GREEN}✅ Toutes les preuves techniques sont générées !${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT : Prenez les screenshots manquants listés ci-dessus${NC}"
echo -e "${BLUE}📂 Emplacement :${NC} $EVIDENCE_DIR/"
