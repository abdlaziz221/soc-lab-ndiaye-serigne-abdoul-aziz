# SOC Lab Conteneurisé - L2 SIMAC - SERIGNE ABDOUL AZIZ NDIAYE

Déploiement complet d'un Security Operations Center (SOC) avec Docker Compose.

## Services déployés

| Service | Image | Port(s) | Réseau | Rôle |
|---------|-------|---------|--------|------|
| **Wazuh Manager** | wazuh/wazuh-manager:4.7.0 | 1514/UDP, 1515/TCP, 55000/TCP | soc-backend | SIEM & Agent Management |
| **Wazuh Dashboard** | wazuh/wazuh-dashboard:4.7.0 | 443/TCP | soc-frontend | Interface Web Wazuh |
| **Suricata** | jasonish/suricata:latest | - | host | IDS/IPS |
| **Cassandra** | cassandra:4.1 | 9042/TCP | soc-backend | BD TheHive |
| **TheHive** | strangebee/thehive:5.1.2 | 9000/TCP | soc-frontend + soc-backend | Réponse à incident |
| **Grafana** | grafana/grafana:latest | 3000/TCP | soc-frontend | Dashboards |


## Prérequis

- Docker et Docker Compose installés
- **vm.max_map_count = 262144**
- 8 GB RAM minimum
- 2 CPUs minimum

## Installation

### 1. Configurer vm.max_map_count

```bash
# Vérifier la valeur actuelle
sysctl vm.max_map_count

# Corriger temporairement
sudo sysctl -w vm.max_map_count=262144

# Rendre persistant
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Vérifier
sysctl vm.max_map_count
