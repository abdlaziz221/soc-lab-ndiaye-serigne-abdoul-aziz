# 🚀 SOC LAB — DÉMARRAGE EN 3 ÉTAPES

## Étape 1 : Lancer la stack (3 minutes)

```bash
cd soc-lab-aziz-ndiaye
bash setup.sh
```

**Vous verrez** :
```
✓ Configuration vm.max_map_count
✓ Structure répertoires créée
✓ Stack démarrée (9 services)
⏳ Wazuh Indexer peut prendre 2-3 min
```

---

## Étape 2 : Vérifier que tout fonctionne

```bash
bash quick-check.sh
```

**Résultat attendu** :
```
✅ Tous les services sont prêts !
```

---

## Étape 3 : Accéder aux interfaces

| Service | URL | Login | Mot de passe |
|---------|-----|-------|-------------|
| **Wazuh Dashboard** | https://localhost | admin | Voir `.env` |
| **Grafana** | http://localhost:3000 | admin | Voir `.env` |
| **TheHive** | http://localhost:9000 | admin@thehive.local | secret |
| **Wazuh Indexer** (API) | https://localhost:9200 | admin | Voir `.env` |

---

## 📚 Documentation Disponible

### Pour Comprendre le Projet
- **ETUDE_ENVIRONNEMENT.md** — Architecture et composants
- **RAPPORT_TECHNIQUE.md** — Bilan complet et tests

### Pour Utiliser
- **GUIDE_UTILISATION.md** — Tâches pratiques, troubleshooting, API

### Pour Déployer
- **PLAN_MISE_EN_PLACE.md** — Phases, bugs résolus, corrections

---

## 🛠️ Commandes Utiles

```bash
# Voir état des services
docker compose ps

# Logs en temps réel
docker compose logs -f

# Logs d'un service spécifique
docker compose logs wazuh-manager -f

# Accès shell dans un conteneur
docker exec -it wazuh-manager bash

# Accès shell de diagnostic
docker exec -it cassandra nodetool status

# Arrêter tout
docker compose down

# Redémarrer un service
docker compose restart wazuh-manager
```

---

## ✅ Checklist Première Utilisation

- [ ] setup.sh exécuté
- [ ] quick-check.sh 13/13 OK
- [ ] Accès https://localhost possible
- [ ] J'ai noté mes identifiants (.env)
- [ ] Lu GUIDE_UTILISATION.md (10 min)
- [ ] Créé mon premier dashboard Grafana
- [ ] Créé mon premier incident TheHive

---

## ⚠️ Si ça ne marche pas

### "Connection refused" sur https://localhost
→ Attendre 2-3 min, Wazuh Dashboard prend du temps  
→ Relancer : `bash quick-check.sh`

### "curl: (52) Empty reply"
→ OpenSearch démarre, relancer dans 30 sec

### Un service reste "Restarting"
→ Normal au démarrage, attendre 1 min  
→ Si persiste : `docker compose logs [service]`

### Autre problème
→ Lire section 5 de **GUIDE_UTILISATION.md** (Troubleshooting)  
→ Ou lancer : `bash diagnostic_soc.sh`

---

## 📞 Support Rapide

Fichier | Question |
|--------|----------|
| **GUIDE_UTILISATION.md** | "Comment faire ...?" |
| **diagnostic_soc.sh** | "Pourquoi ça ne marche pas?" |
| **quick-check.sh** | "Est-ce que c'est OK?" |
| **docker compose logs** | "Qu'est-ce que le service dit?" |
| **RAPPORT_TECHNIQUE.md** | "C'est quoi qui a été corrigé?" |

---

## 🎓 Prochain Pas

Voir section "Tâches Pratiques" dans **GUIDE_UTILISATION.md** :

1. **Tâche 1** : Visualiser logs Wazuh (15 min)
2. **Tâche 2** : Créer dashboard Grafana (20 min)
3. **Tâche 3** : Incident dans TheHive (15 min)

---

**Bon lab! 🚀**

