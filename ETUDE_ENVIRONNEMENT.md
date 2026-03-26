# Étude de l'Environnement SOC Lab L2 SIMAC

**Date**: 26/03/2026  
**Projet**: SOC Lab Conteneurisé - L2 Cybersecurité  
**Étudiant**: Aziz NDIAYE

---

## 1. État Initial du Projet

### État détecté
Le projet était partiellement fonctionnel mais rencontrait des problèmes de déploiement :

**Problèmes identifiés :**
- ✗ Wazuh Indexer : healthcheck non compatible avec image (curl absent du container)
- ✗ Wazuh Manager : connexion HTTP au lieu de HTTPS vers l'indexer
- ✗ Suricata : interface "any" non disponible en conteneur Docker
- ✗ Dépendances strictes causant deadlock au démarrage

### Architecture prévue
```
Frontend (Wazuh Dashboard, Grafana, TheHive)
    ↓
Backend (Wazuh Indexer, Wazuh Manager, Cassandra)
    ↓
Monitoring (Suricata - IDS isolé)
```

---

## 2. Composants SOC Identifiés

| Service | Image | Port | Rôle |
|---------|-------|------|------|
| **Wazuh Manager** | wazuh/wazuh-manager:4.7.0 | 1514, 1515, 55000 | Collecte & traitement logs |
| **Wazuh Indexer** | wazuh/wazuh-indexer:4.7.0 | 9200 | Stockage SIEM (OpenSearch) |
| **Wazuh Dashboard** | wazuh/wazuh-dashboard:4.7.0 | 443 | Interface de visualisation |
| **Suricata** | jasonish/suricata:latest | aucun | IDS/IPS (mode conteneur) |
| **Grafana** | grafana/grafana:10.2.0 | 3000 | Dashboards métriques |
| **TheHive** | strangebee/thehive:5.1.2 | 9000 | Gestion des incidents |
| **Cassandra** | cassandra:4.1 | 9042 | Base données TheHive |

---

## 3. Configuration

### Fichiers clés
- **docker-compose.yml** : Orchestration 9 services
- **.env** : Variables sensibles (mots de passe)
- **wazuh/config/opensearch.yml** : Configuration indexer
- **suricata/rules/local.rules** : Règles de détection
- **thehive/config/application.conf** : Configuration TheHive

### Réseaux Docker
- **soc-frontend** : Wazuh Dashboard, Grafana, TheHive (accès public)
- **soc-backend** : Indexer, Manager, Cassandra (réseau interne)

---

## 4. Exigences Système

- **RAM** : 8 Go minimum (4 Go utilisé en production)
- **CPU** : 2+ cœurs
- **Prérequis** : Docker Engine ≥ 24.0, Docker Compose ≥ 2.0
- **Kernel** : `vm.max_map_count = 262144` (géré par setup.sh)

---

## 5. Flux de Données Attendus

```
Agents Wazuh (externes)
    → Wazuh Manager (port 1514 UDP)
    → Traitement + Enrichissement
    → Wazuh Indexer (HTTPS port 9200)
    → Stockage & Indexation
    → Wazuh Dashboard (port 443)
    → Visualisation
    
Trafic réseau
    → Suricata (IDS, interface docker)
    → Logs d'alertes
```

---

## 6. Accès Services

| Service | URL | Identifiant | Note |
|---------|-----|-------------|------|
| Wazuh Dashboard | https://localhost | admin / voir .env | HTTPS auto-signé |
| Grafana | http://localhost:3000 | admin / voir .env | HTTP public |
| TheHive | http://localhost:9000 | admin@thehive.local / secret | Base attendue en Cassandra |
| Wazuh Indexer | https://localhost:9200 | admin / voir .env | OpenSearch 2.0 (compatible) |

---

## 7. Points Critiques à Retenir

1. **OpenSearch Security** : Configuration minimale (sécurité system disabled sur indexer)
2. **HTTPS obligatoire** : Tous les accès inter-services vers l'indexer
3. **Isolation Suricata** : Container isolé, pas de capture d'interfaces réelles possible
4. **Cassandra obligatoire** : Pour le démarrage de TheHive
5. **Timeouts de démarrage** : Wazuh Manager peut prendre 2-3 min à venir healthy

---

## 8. Exigences du Projet

✓ Stack SIEM complète (Wazuh)  
✓ IDS/IPS (Suricata)  
✓ Gestion d'incidents (TheHive)  
✓ Visualisation de métriques (Grafana)  
✓ Déploiement conteneurisé  
✓ Documentation en français  

