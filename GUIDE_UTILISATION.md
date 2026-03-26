# Guide d'Utilisation - SOC Lab L2 SIMAC

**Public cible**: Étudiants L2 Cybersecurité  
**Niveau requis**: Notions Docker, Linux, Cybersecurité de base  
**Durée d'apprentissage**: 2-3 heures

---

## 1. Démarrage Rapide

### 1.1 Lancer la stack
```bash
cd soc-lab-aziz-ndiaye
bash setup.sh
```

**Durée d'attente** : ~3 minutes (les services se stabilisent)

### 1.2 Vérifier l'état
```bash
docker compose ps
watch -n5 'docker compose ps'  # Suivi en temps réel
```

### 1.3 Accéder aux interfaces
- **Wazuh Dashboard** : https://localhost → admin / [mdp dans .env]
- **Grafana** : http://localhost:3000 → admin / [mdp dans .env]
- **TheHive** : http://localhost:9000 → admin@thehive.local / secret

---

## 2. Comprendre l'Architecture

### 2.1 Composant Principal : Wazuh

**Wazuh** = Plateforme SIEM + XDR open-source

Trois composants :
1. **Manager** (1514/UDP) → Reçoit logs d'agents
2. **Indexer** (9200/HTTPS) → Stocke les données (OpenSearch)
3. **Dashboard** (443/HTTPS) → Interface web

```
Agent Wazuh    →  Manager  →  Indexer  →  Dashboard
(client)        (traitement) (storage)    (visualisation)
```

### 2.2 Flux d'Alertes

```
Évènement système (login, fichier modifié, etc.)
    ↓
Agent Wazuh → Manager (port 1514)
    ↓
Analyse + Enrichissement  
    ↓
Indexeur OpenSearch (9200)
    ↓
Dashboard + TheHive
```

### 2.3 Suricata : IDS/IPS  

**Suricata** = Son rôle dans le lab :
- Détecte anomalies réseau
- Sort alertes en format EVE-JSON
- Peut envoyer logs vers Manager

---

## 3. Tâches Pratiques

### Tâche 1 : Visualiser les logs Wazuh

**Objectif** : Voir les alertes système en temps réel

**Étapes** :
```
1. Accéder https://localhost/app/wazuh
2. Menu → Threat Intelligence → Dashboard
3. Observer les logs entrantes
4. Cliquer sur une alerte → voir détails
```

**Qu'observer** :
- Événements système (fichiers, réseau)
- Niveau de sévérité (Critical, High, Medium)
- Recherche par host, type d'alerte

---

### Tâche 2 : Créer un Dashboard Grafana

**Objectif** : Visualiser les métriques Wazuh dans Grafana

**Étapes** :
```
1. Accéder http://localhost:3000 (Grafana)
2. Configuration → Data Sources → Add Elasticsearch
3. URL: http://wazuh-indexer:9200
4. Auth: admin / [mdp .env]
5. Save & Test
6. Créer Dashboard → New Panel
7. Requête : index="wazuh-*" | stats count() by alert.level
```

**Panel utiles** :
- Nombre d'alertes par jour
- Top 10 hôtes bruyants
- Distribution des sévérités

---

### Tâche 3 : Gérer un Incident dans TheHive

**Objectif** : Créer et closer un incident

**Étapes** :
```
1. Accéder http://localhost:9000
2. Cases → New Case
3. Remplir formulaire (titre, description, severity)
4. Tasks → Créer sous-tâche (Investigate, Respond)
5. Ajouter observables (IP, domaine, hash)
6. Marquer tâches comme complétées
7. Status → Resolved
```

**Usecases courants** :
- Alerte compromission compte
- Détection malware fichier
- Tentative brute-force SSH

---

## 4. Gestion de la Stack

### 4.1 Voir les logs

```bash
# Logs spécifique service  
docker compose logs wazuh-manager -f

# Logs tous services
docker compose logs -f

# Logs X dernières minutes
docker compose logs --since 10m
```

### 4.2 Arrêter / Redémarrer

```bash
# Arrêter complètement
docker compose down

# Redémarrer tout
docker compose restart

# Redémarrer un service
docker compose restart wazuh-manager

# Supprimer volumes (perte données)
docker compose down -v
```

### 4.3 Accès direct conteneur

```bash
# Shell interactif
docker exec -it wazuh-manager bash

# Exécuter commande
docker exec wazuh-manager ls -la /var/ossec/logs/

# Vérifier PID Wazuh Manager
docker exec wazuh-manager ps aux | grep wazuh
```

---

## 5. Troubleshooting

### Problème : Dashboard lent à démarrer

**Cause** : Initialisation OpenSearch normal  
**Solution** :
```bash
# Attendre 2-3 min
watch -n5 'curl -sk https://localhost:9200/_cluster/health'
# Patienter jusqu'à {"status":"green"}
```

---

### Problème : TheHive ne démarre pas

**Cause** : Cassandra pas encore prêt  
**Solution** :
```bash
# Vérifier Cassandra
docker compose logs cassandra | tail -20

# Redémarrer ensemble
docker compose restart cassandra
docker compose restart thehive
```

---

### Problème : Pas d'alertes dans Dashboard

**Cause** : Pas d'agents connectés  
**Solution** :
```bash
# Vérifier logs Manager
docker compose logs wazuh-manager | grep "agent"

# Attendre démarrage complet (5 min)
# Vois section "Ajouter Agent" para fournir données
```

---

## 6. Ajouter un Agent Wazuh (Optionnel)

### Sur Linux client (Ubuntu)
```bash
# 1. Télécharger agent
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | \
  tee /etc/apt/sources.list.d/wazuh.list
apt update && apt install -y wazuh-agent

# 2. Configurer
MANAGER_IP="192.168.1.X"  # IP machine Docker
nano /var/ossec/etc/ossec.conf
# Modifier <address>localhost</address> → <address>$MANAGER_IP</address>

# 3. Démarrer
systemctl enable wazuh-agent
systemctl start wazuh-agent

# 4. Vérifier  
grep "Agent started" /var/ossec/logs/ossec.log
```

### Dans Wazuh Dashboard
```
1. Infrastructure → Agents
2. Observer nouvel agent avec statut "Active"
3. Cliquer pour voir ses alertes
```

---

## 7. Règles Suricata (IDS)

### 7.1 Où les modifier
```
suricata/rules/local.rules
```

### 7.2 Exemple règle

```
# Déjà présente : alerte sur scan nmap
alert tcp any any -> $HOME_NET any (msg:"Nmap SYN scan"; \
  flow:stateless; flags:S; threshold: type both, track by_src, \
  count 10, seconds 2; sid:1000001; rev:1;)
```

### 7.3 Ajouter règle perso

```
alert http $HOME_NET any -> $EXTERNAL_NET any \
  (msg:"SQL Injection attempt"; \
  content:"union|20|select"; \
  http_uri; nocase; sid:1000100; rev:1;)
```

**Appliquer** :
```bash
docker compose restart suricata
docker compose logs suricata  # Vérifier pas d'erreur
```

---

## 8. Questions Fréquentes

**Q: Combien de RAM consomme la stack?**  
A: ~2-4 Go selon la charge. Indexer ~800 MB, TheHive ~600 MB.

**Q: Puis-je ajouter mes propres agents?**  
A: Oui, voir section 6. Installer l'agent Wazuh sur Linux/Windows.

**Q: Comment sauvegarder mes données?**  
A: Volumes Docker persistants. Pour export : 
```bash
docker exec wazuh-indexer curl -u admin:pwd \
  http://localhost:9200/wazuh-2024* -o backup.json
```

**Q: Comment intégrer Slack/Email?**  
A: Dans Wazuh Dashboard → Tools → Integrations. Configurer webhook.

**Q: Suricata peut-il vraiment capturer du trafic?**  
A: En conteneur, seulement le trafic Docker interne. Pour capture réelle, déployer Suricata hors conteneur.

---

## 9. Ressources & Documentation

- **Wazuh Docs** : https://documentation.wazuh.com
- **Suricata Rules** : https://rules.suricata.io
- **TheHive Project** : https://github.com/TheHive-Project
- **Grafana Query Language** : https://www.elastic.co/guide/en/kibana/current/dsl-query-language.html

---

## 10. Évaluation de Compréhension

Après utilisation, valider :

- [ ] Accès Wazuh Dashboard et observation d'alertes
- [ ] Création dashboard Grafana custom
- [ ] Gestion incident dans TheHive
- [ ] Modification et déploiement règle Suricata
- [ ] Docker logs troubleshooting
- [ ] Configuration agent externe (optionnel)

