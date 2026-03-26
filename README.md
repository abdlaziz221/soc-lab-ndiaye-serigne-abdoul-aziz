# SOC Lab Conteneurisé — L2 SIMAC

Stack complète : **Wazuh · Suricata · Grafana · TheHive · Cassandra**

## Déploiement rapide

```bash
# 1. Cloner le dépôt
git clone <url-repo> soc-lab-[NOM_ETUDIANT]
cd soc-lab-[NOM_ETUDIANT]

# 2. Configurer les variables
cp .env.example .env
nano .env   # Remplir les mots de passe

# 3. Déployer
bash setup.sh

# 4. Vérifier
watch -n5 'docker compose ps'
```

## Prérequis

- Docker Engine ≥ 24.0
- Docker Compose ≥ 2.0
- RAM : 8 Go minimum
- `vm.max_map_count=262144` (géré par setup.sh)

## Accès aux interfaces

| Service | URL | Identifiants |
|---------|-----|-------------|
| Wazuh Dashboard | https://localhost | admin / voir .env |
| Grafana | http://localhost:3000 | admin / voir .env |
| TheHive | http://localhost:9000 | admin@thehive.local / secret |
| Wazuh Indexer | https://localhost:9200 | admin / voir .env |

## Architecture réseau

```
                    ┌──────────────────────────────┐
  EXTERNE           │  soc-frontend (172.20.x.x)   │
  :443, :3000, :9000│  wazuh-dashboard              │
                    │  grafana                      │
                    │  thehive                      │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────┴───────────────┐
                    │  soc-backend (172.21.x.x)    │
                    │  wazuh-indexer               │
                    │  wazuh-manager               │
                    │  cassandra                   │
                    └──────────────────────────────┘
                    
                    ┌──────────────────────────────┐
                    │  soc-monitoring (172.22.x.x) │
                    │  suricata (IDS — isolé)      │
                    └──────────────────────────────┘
```

## Diagnostic

```bash
bash diagnostic_soc.sh
```

## Structure du dépôt

```
soc-lab-[NOM]/
├── README.md
├── docker-compose.yml
├── setup.sh
├── diagnostic_soc.sh
├── .env.example
├── .gitignore
├── suricata/
│   ├── suricata.yaml
│   ├── rules/local.rules
│   └── logs/.gitkeep
├── grafana/dashboards/
├── thehive/config/application.conf
└── rapport/
    ├── rapport-final.pdf
    └── captures/
```
