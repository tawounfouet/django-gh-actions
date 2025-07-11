# Guide de Mise en Route Rapide - DigitalOcean

Ce guide vous aide à déployer rapidement votre application Django sur le serveur DigitalOcean.

## 📋 Informations du Serveur

- **Nom** : dos-ubuntu-devops
- **IP** : 157.245.79.172
- **Utilisateur initial** : root
- **Mot de passe** : z@zEuuE5fk

## 🚀 Étapes de Configuration Rapide

### 1. Connexion au serveur et configuration automatique

```bash
# Connexion SSH au serveur
ssh root@157.245.79.172

# Téléchargement et exécution du script de configuration
curl -fsSL https://raw.githubusercontent.com/tawounfouet/django-gh-actions/main/scripts/setup-digitalocean.sh | bash

# OU si vous avez le script localement :
# Copier le script sur le serveur et l'exécuter
chmod +x setup-digitalocean.sh
./setup-digitalocean.sh
```

### 2. Configuration des secrets GitHub

Dans votre repository GitHub, allez dans Settings > Secrets and variables > Actions et ajoutez :

| Secret | Valeur |
|--------|--------|
| `SSH_PRIVATE_KEY` | Contenu de votre clé privée SSH (ex: `~/.ssh/id_rsa`) |
| `SSH_HOST` | `157.245.79.172` |
| `SSH_USER` | `django` |

### 3. Vérification de la configuration

```bash
# Test de connexion SSH avec le nouvel utilisateur
ssh django@157.245.79.172

# Vérification des services
sudo supervisorctl status
sudo systemctl status nginx

# Test de l'application
curl http://157.245.79.172
```

## 🔧 Commandes Utiles

### Gestion des services

```bash
# Redémarrer l'application Django
sudo supervisorctl restart django-app

# Recharger la configuration Nginx
sudo systemctl reload nginx

# Vérifier les logs
tail -f /var/www/django-app/logs/gunicorn.log
tail -f /var/log/nginx/django-app.access.log
```

### Déploiement manuel

```bash
# Se connecter au serveur
ssh django@157.245.79.172

# Naviguer vers l'application
cd /var/www/django-app/app

# Pull des dernières modifications
git pull origin main

# Activation de l'environnement virtuel
source /var/www/django-app/venv/bin/activate

# Installation des dépendances
pip install -r requirements.txt

# Migrations
python manage.py migrate

# Collecte des fichiers statiques
python manage.py collectstatic --noinput

# Redémarrage
sudo supervisorctl restart django-app
```

## 🔄 Test du Pipeline CI/CD

1. **Modifier du code** dans votre repository local
2. **Commit et push** vers la branche `main`
3. **Observer** l'exécution dans l'onglet "Actions" de GitHub
4. **Vérifier** le déploiement sur http://157.245.79.172

## 🏥 Diagnostic en cas de problème

### Vérifications basiques

```bash
# Statut des services
sudo supervisorctl status
sudo systemctl status nginx

# Test de connectivité locale
curl -I http://localhost:8000
curl -I http://127.0.0.1

# Test depuis l'extérieur
curl -I http://157.245.79.172
```

### Consultation des logs

```bash
# Logs de l'application Django
tail -f /var/www/django-app/logs/gunicorn.log

# Logs Nginx
tail -f /var/log/nginx/django-app.access.log
tail -f /var/log/nginx/django-app.error.log

# Logs système
tail -f /var/log/syslog
journalctl -u nginx -f
```

### Redémarrage complet

```bash
# Redémarrage de tous les services
sudo supervisorctl restart django-app
sudo systemctl restart nginx

# Vérification
sleep 5
curl -I http://157.245.79.172
```

## 🔐 Sécurité

Le script de configuration automatique configure :
- ✅ Pare-feu UFW avec règles restrictives
- ✅ Fail2Ban pour protéger SSH
- ✅ Utilisateur non-root pour l'application
- ✅ Permissions sudo limitées

## 📞 Support

En cas de problème :

1. **Vérifiez les logs** avec les commandes ci-dessus
2. **Consultez le plan d'action détaillé** dans `plan-action-devops_v2.md`
3. **Testez la connectivité SSH** depuis GitHub Actions
4. **Vérifiez les secrets GitHub** (SSH_PRIVATE_KEY, SSH_HOST, SSH_USER)

## 🌐 Accès à l'Application

Une fois configuré, votre application Django sera accessible à :
**http://157.245.79.172**

---

*Guide créé le 11 juillet 2025*
