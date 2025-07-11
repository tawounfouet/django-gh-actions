#!/bin/bash

# Script de configuration automatisée pour le serveur DigitalOcean
# À exécuter sur le serveur : dos-ubuntu-devops (157.245.79.172)

set -e

echo "🚀 Configuration automatisée du serveur DigitalOcean pour Django CI/CD"
echo "========================================================================="
echo ""
echo "Server Info:"
echo "- Name: dos-ubuntu-devops"
echo "- IP: 157.245.79.172"
echo "- User: root"
echo ""

# Mise à jour du système
echo "📦 Mise à jour du système..."
apt update && apt upgrade -y

# Installation des paquets essentiels
echo "📦 Installation des paquets essentiels..."
apt install -y python3 python3-pip python3-venv git nginx supervisor ufw fail2ban curl

# Création d'un utilisateur non-root pour la sécurité
echo "👤 Création de l'utilisateur django..."
if ! id "django" &>/dev/null; then
    adduser django --disabled-password --gecos ""
    usermod -aG sudo django
    echo "✅ Utilisateur django créé"
else
    echo "ℹ️ Utilisateur django existe déjà"
fi

# Configuration SSH pour l'utilisateur django
echo "🔑 Configuration de l'accès SSH..."
mkdir -p /home/django/.ssh
if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys /home/django/.ssh/
    chown -R django:django /home/django/.ssh
    chmod 700 /home/django/.ssh
    chmod 600 /home/django/.ssh/authorized_keys
    echo "✅ Clés SSH copiées pour l'utilisateur django"
else
    echo "⚠️ Aucune clé SSH trouvée pour root. Veuillez configurer manuellement."
fi

# Configuration du pare-feu
echo "🔥 Configuration du pare-feu UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable
echo "✅ Pare-feu configuré"

# Préparation de l'environnement Django
echo "🐍 Préparation de l'environnement Django..."
mkdir -p /var/www/django-devops-app
chown -R django:django /var/www/django-devops-app

# Basculer vers l'utilisateur django pour les opérations suivantes
echo "🔄 Configuration de l'application Django (en tant qu'utilisateur django)..."

sudo -u django bash << 'EOF'
cd /var/www/django-app

# Cloner le repository si pas déjà fait
if [ ! -d "app" ]; then
    echo "📥 Clonage du repository..."
    git clone https://github.com/tawounfouet/django-gh-actions.git app
else
    echo "ℹ️ Repository déjà cloné"
fi

cd app

# Création de l'environnement virtuel
if [ ! -d "/var/www/django-app/venv" ]; then
    echo "🐍 Création de l'environnement virtuel..."
    python3 -m venv /var/www/django-app/venv
else
    echo "ℹ️ Environnement virtuel existe déjà"
fi

# Activation et installation des dépendances
echo "📦 Installation des dépendances Python..."
source /var/www/django-app/venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

# Configuration Django pour la production
echo "⚙️ Configuration Django pour la production..."
if ! grep -q "ALLOWED_HOSTS.*157.245.79.172" /var/www/django-app/app/core/settings.py; then
    echo "ALLOWED_HOSTS = ['157.245.79.172', 'localhost', '127.0.0.1']" >> /var/www/django-app/app/core/settings.py
fi

# Migrations et collecte des fichiers statiques
echo "🔄 Exécution des migrations..."
python manage.py migrate

echo "📁 Collecte des fichiers statiques..."
python manage.py collectstatic --noinput

# Création du dossier de logs
mkdir -p /var/www/django-app/logs
EOF

# Configuration de Supervisor pour Gunicorn
echo "⚙️ Configuration de Supervisor..."
cat > /etc/supervisor/conf.d/django-app.conf << 'EOF'
[program:django-app]
command=/var/www/django-app/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application
directory=/var/www/django-app/app
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/www/django-app/logs/gunicorn.log
environment=PATH="/var/www/django-app/venv/bin"
EOF

supervisorctl reread
supervisorctl update
supervisorctl start django-app

# Configuration de Nginx
echo "🌐 Configuration de Nginx..."
cat > /etc/nginx/sites-available/django-app << 'EOF'
server {
    listen 80;
    server_name 157.245.79.172;

    client_max_body_size 20M;

    location /static/ {
        alias /var/www/django-app/app/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /var/www/django-app/app/media/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    access_log /var/log/nginx/django-app.access.log;
    error_log /var/log/nginx/django-app.error.log;
}
EOF

# Activation du site
ln -sf /etc/nginx/sites-available/django-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test et redémarrage de Nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

# Permissions pour le déploiement automatisé
echo "🔐 Configuration des permissions sudo..."
echo 'django ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl restart django-app' > /etc/sudoers.d/django-supervisor
echo 'django ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx' > /etc/sudoers.d/django-nginx

# Configuration de Fail2Ban
echo "🛡️ Configuration de Fail2Ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl restart fail2ban
systemctl enable fail2ban

# Vérification finale
echo ""
echo "🏥 Vérification de l'installation..."
sleep 5

if curl -f http://localhost:8000 > /dev/null 2>&1; then
    echo "✅ Application Django fonctionne correctement!"
    echo "🌐 Votre application est accessible à : http://157.245.79.172"
else
    echo "⚠️ L'application ne répond pas. Vérifiez les logs :"
    echo "   - sudo supervisorctl status"
    echo "   - tail -f /var/www/django-app/logs/gunicorn.log"
fi

echo ""
echo "🎉 Configuration terminée avec succès!"
echo ""
echo "📋 Résumé de la configuration :"
echo "   - Utilisateur django créé avec accès sudo"
echo "   - Application Django installée dans /var/www/django-app/"
echo "   - Gunicorn configuré avec Supervisor"
echo "   - Nginx configuré comme reverse proxy"
echo "   - Pare-feu UFW activé"
echo "   - Fail2Ban configuré pour SSH"
echo ""
echo "🔧 Prochaines étapes :"
echo "   1. Configurez vos secrets GitHub :"
echo "      - SSH_PRIVATE_KEY: Votre clé privée SSH"
echo "      - SSH_HOST: 157.245.79.172"
echo "      - SSH_USER: django"
echo "   2. Utilisez le workflow deploy-cloud.yml pour le déploiement automatique"
echo "   3. Testez votre application à http://157.245.79.172"
echo ""

# Affichage des statuts des services
echo "📊 Statut des services :"
echo "========================"
echo "Supervisor :"
supervisorctl status
echo ""
echo "Nginx :"
systemctl status nginx --no-pager -l
echo ""
echo "UFW :"
ufw status
echo ""
echo "✨ Installation terminée ! ✨"
