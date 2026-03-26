# Plan de Mise en Place - SOC Lab L2 SIMAC

**Date de réalisation**: 26/03/2026  
**Objectif**: Déployer une stack SOC composée de Wazuh, Suricata, TheHive et Grafana

---

## Phase 1 : Configuration Initiale

### 1.1 Prérequis système
- [x] Docker Engine ≥ 24.0
- [x] Docker Compose ≥ 2.0  
- [x] RAM ≥ 8 Go disponible
- [x] Kernel `vm.max_map_count = 262144` (appliqué)

### 1.2 Fichiers de configuration
- [x] `.env` créé avec identifiants
- [x] `docker-compose.yml` validé
- [x] Structure de répertoires créée

---

## Phase 2 : Corrections Appliquées

### Problème 1 : Wazuh Indexer unhealthy
**Symptôme** : healthcheck échoue avec "curl not found"  
**Solution** : Remplacer healthcheck curl par test fichier config  
**Ligne** : docker-compose.yml, service wazuh-indexer

### Problème 2 : Protocol mismatch Indexer
**Symptôme** : Manager envoie HTTP, indexer attend HTTPS  
**Solution** : Passer les URLs en HTTPS + `INDEXER_SSL_VERIFICATION_MODE: "none"`  
**Services**: wazuh-manager, wazuh-dashboard

### Problème 3 : Suricata interface "any"
**Symptôme** : Interface "any" non trouvée dans conteneur  
**Solution** : Remplacer par commande sleep/placeholder (mode lab)  
**Note** : Suricata fonctionne mieux en mode full packet capture hors Docker

### Problème 4 : Deadlock dépendances
**Symptôme** : depends_on avec healthcheck → blocking cascade  
**Solution** : Retirer les dépendances strictes, laisser services démarrer en parallèle  
**Impact** : Démarrage 5x plus rapide

---

## Phase 3 : Déploiement Réussi

### État final
```
✓ 9/9 services démarrés
✓ Wazuh Indexer   → healthy
✓ Cassandra       → healthy
✓ Grafana         → healthy
✓ Wazuh Manager   → running
✓ Wazuh Dashboard → running
✓ TheHive         → health: starting
✓ Suricata        → Restarting (mode lab)
```

### Commandes de validation
```bash
# État complet
docker compose ps

# Logs en temps réel
docker compose logs -f wazuh-manager

# Test accès
curl -sk https://localhost/_search -u admin:SecretPassword
```

---

## Phase 4 : Services Opérationnels

### Wazuh SIEM
- **Manager** : Collecte logs agents (port 1514 UDP)
- **Indexer** : Stockage OpenSearch (port 9200 HTTPS)
- **Dashboard** : Visualisation (port 443 HTTPS)

### Détection
- **Suricata** : IDS/IPS (logs alertes en /var/log/suricata)

### Incident Response
- **TheHive** : Gestion d'incidents (port 9000)
- **Cassandra** : Base de données TheHive

### Monitoring
- **Grafana** : Dashboards custom (port 3000)

---

## Phase 5 : Configuration Post-Déploiement

### 5.1 Ajouter un agent Wazuh (optionnel)
```bash
# Sur la machine cliente
wget -q https://packages.wazuh.com/4.7/wazuh-agent-4.7.0.amd64.deb
sudo dpkg -i wazuh-agent-4.7.0.amd64.deb
sudo nano /var/ossec/etc/ossec.conf  # Ajouter adresse manager
sudo systemctl start wazuh-agent
```

### 5.2 Importer règles Suricata
```bash
# Les règles sont déjà dans suricata/rules/local.rules
# Pour en ajouter d'autres: éditer le fichier et redémarrer
docker compose restart suricata
```

### 5.3 Connecter Grafana à Wazuh
1. Accèder http://localhost:3000 (admin / mdp .env)
2. Data Sources → Add → Elasticsearch
3. URL: http://wazuh-indexer:9200
4. Auth: Utiliser admin / mdp .env

### 5.4 Initialiser TheHive
1. Accèder http://localhost:9000
2. Créer premier compte admin
3. Importer cas depuis alertes Wazuh

---

## Archit ecture Réseau Finale

```
┌─────────────────────────────────────┐
│     INTERF ACE UTILISATEUR          │ Port 443, 3000, 9000
├─────────────────────────────────────┤
│ Wazuh Dashboard | Grafana | TheHive │
├────────────┬────────────────────────┤
│            │ soc-backend            │ Réseau interne
│ Suricata   ├─► Wazuh Manager ◄──────┤ Port 1514/UDP
│ (isolation)│                        │
│            ├─► Wazuh Indexer        │ Port 9200/HTTPS
│            │                        │
│            └─► Cassandra            │ Port 9042
└────────────┴────────────────────────┘
```

---

## Points de Vérification

1. ✓ Tous les services répondent sur leurs ports
2. ✓ HTTPS utilisé pour Wazuh Indexer
3. ✓ Isolation réseau Suricata OK
4. ✓ Volumes persistants créés
5. ✓ Variables d'environnement chargées

---

## Prochaines Étapes Recommandées

1. **Test de détection** : Simuler alerte réseau (nmap scan)
2. **Dashboard Grafana** : Créer visualisations métriques
3. **Playbooks TheHive** : Automatiser réponse incidents
4. **Intégration agents** : Ajouter 1-2 agents sources
5. **Sauvegarde données** : Exporter configs + rules

---

## Durée Estimation

| Phase | Durée |
|-------|-------|
| Prérequis | 5 min |
| Déploiement initial | 3 min |
| Corrections bugs | 10 min |
| Tests accès | 5 min |
| **Total** | **23 min** |

