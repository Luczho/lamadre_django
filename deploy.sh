#!/bin/bash

# LaMadre Django - Deployment Script for Hetzner Server
# Server IP: 37.27.44.248
# Domain: shop.lamadre.pl
# Uruchom jako root lub z sudo

set -e  # Zatrzymaj na pierwszym błędzie

echo "🚀 Rozpoczynam deployment LaMadre Django na Hetzner (37.27.44.248)"
echo "🌐 Domena: shop.lamadre.pl"

# Kolory dla outputu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcja logowania
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Sprawdź czy jesteś root
if [[ $EUID -ne 0 ]]; then
   error "Ten skrypt musi być uruchomiony jako root (sudo)"
fi

# Informacje o serwerze
log "Serwer: 37.27.44.248"
log "Domena: shop.lamadre.pl"
log "Data: $(date)"
log "Użytkownik: $SUDO_USER"

# Aktualizacja systemu
log "Aktualizuję system..."
apt update && apt upgrade -y

# Instalacja podstawowych pakietów
log "Instaluję podstawowe pakiety..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release htop net-tools

# Instalacja Docker
log "Instaluję Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    systemctl enable docker
    systemctl start docker
    log "Docker zainstalowany i uruchomiony"
else
    log "Docker już zainstalowany"
fi

# Instalacja Docker Compose
log "Instaluję Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log "Docker Compose zainstalowany"
else
    log "Docker Compose już zainstalowany"
fi

# Instalacja Nginx (jeśli nie ma)
log "Sprawdzam Nginx..."
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    log "Nginx zainstalowany"
else
    log "Nginx już zainstalowany"
fi

# Instalacja Certbot dla SSL
log "Instaluję Certbot dla SSL..."
apt install -y certbot python3-certbot-nginx

# Sprawdzenie i konfiguracja SSH
log "Sprawdzam konfigurację SSH..."

# Sprawdź czy SSH key już istnieje (w root lub w katalogu użytkownika)
if [ -f "/root/.ssh/id_ed25519" ] || [ -f "/root/.ssh/id_rsa" ] || [ -f "/home/$SUDO_USER/.ssh/id_ed25519" ] || [ -f "/home/$SUDO_USER/.ssh/id_rsa" ]; then
    log "SSH key już istnieje - sprawdzam połączenie z GitHub..."
    
    # Test połączenia SSH z GitHub (jako root)
    if ssh -T git@github.com > /dev/null 2>&1; then
        log "✅ SSH połączenie z GitHub działa!"
        SSH_WORKING=true
    else
        warn "SSH key istnieje, ale połączenie z GitHub nie działa"
        warn "Sprawdź czy dodałeś klucz do GitHub lub czy jest poprawnie skonfigurowany"
        SSH_WORKING=false
    fi
else
    log "SSH key nie istnieje - generuję nowy..."
    
    # Przełącz na użytkownika i generuj SSH key
    su - $SUDO_USER << 'EOF'
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "lamadre-django@37.27.44.248" -f ~/.ssh/id_ed25519 -N ""
        chmod 600 ~/.ssh/id_ed25519
        chmod 644 ~/.ssh/id_ed25519.pub
        
        # Konfiguracja SSH dla GitHub
        cat > ~/.ssh/config << 'SSHCONFIG'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
SSHCONFIG
        
        chmod 600 ~/.ssh/config
        
        echo "SSH key wygenerowany!"
        echo "Public key:"
        cat ~/.ssh/id_ed25519.pub
        echo ""
        echo "⚠️  DODAJ TEN KLUCZ DO GITHUB:"
        echo "1. Idź na: https://github.com/settings/keys"
        echo "2. Kliknij 'New SSH key'"
        echo "3. Wklej powyższy klucz"
        echo "4. Tytuł: lamadre-django@37.27.44.248"
        echo "5. Kliknij 'Add SSH key'"
        echo ""
        echo "Po dodaniu klucza, wróć tutaj i naciśnij Enter..."
EOF
    
    read -p "Naciśnij Enter po dodaniu SSH key do GitHub..."
    
    # Test połączenia SSH z GitHub
    log "Testuję połączenie SSH z GitHub..."
    if su - $SUDO_USER -c "ssh -T git@github.com" > /dev/null 2>&1; then
        log "✅ SSH połączenie z GitHub działa!"
        SSH_WORKING=true
    else
        warn "Połączenie SSH z GitHub nie działa. Sprawdź czy dodałeś klucz."
        SSH_WORKING=false
    fi
fi

# Konfiguracja Git
log "Konfiguruję Git..."
su - $SUDO_USER << 'EOF'
    git config --global user.name "LaMadre Django"
    git config --global user.email "deploy@lamadre.pl"
    git config --global init.defaultBranch main
    echo "Git skonfigurowany!"
EOF

# Tworzenie katalogu aplikacji
APP_DIR="/opt/lamadre-django"
log "Tworzę katalog aplikacji: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# Klonowanie repozytorium
if [ ! -d ".git" ]; then
    if [ "$SSH_WORKING" = true ]; then
        log "Klonuję repozytorium przez SSH..."
        git clone git@github.com:Luczho/lamadre_django.git . || {
            warn "Klonowanie przez SSH nie działa, próbuję przez HTTPS..."
            git clone https://github.com/Luczho/lamadre_django.git .
        }
    else
        log "Klonuję repozytorium przez HTTPS..."
        git clone https://github.com/Luczho/lamadre_django.git .
    fi
else
    log "Aktualizuję repozytorium..."
    if [ "$SSH_WORKING" = true ]; then
        git pull origin main || {
            warn "Pull przez SSH nie działa, próbuję przez HTTPS..."
            git pull origin main
        }
    else
        git pull origin main
    fi
fi

# Konfiguracja środowiska
if [ ! -f ".env" ]; then
    log "Tworzę plik .env..."
    cp env.example .env
    
    # Generowanie SECRET_KEY (używam openssl zamiast Python)
    SECRET_KEY=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-50)
    sed -i "s/your-secret-key-here/$SECRET_KEY/" .env
    
    # Konfiguracja produkcji
    sed -i 's/DEBUG=True/DEBUG=False/' .env
    sed -i 's/DB_HOST=localhost/DB_HOST=db/' .env
    sed -i 's/REDIS_URL=redis:\/\/localhost:6379\/0/REDIS_URL=redis:\/\/redis:6379\/0/' .env
    
    # Ustawienie domeny i IP serwera
    sed -i 's/ALLOWED_HOSTS=localhost,127.0.0.1/ALLOWED_HOSTS=shop.lamadre.pl,37.27.44.248,localhost,127.0.0.1/' .env
    
    warn "Edytuj plik .env i ustaw prawdziwe dane przed uruchomieniem!"
    warn "Szczególnie: DB_PASSWORD, EMAIL_*"
    warn "ALLOWED_HOSTS ustawione na: shop.lamadre.pl, 37.27.44.248"
else
    log "Plik .env już istnieje"
    # Sprawdź czy domena jest w ALLOWED_HOSTS
    if ! grep -q "shop.lamadre.pl" .env; then
        warn "Dodaję domenę do ALLOWED_HOSTS..."
        sed -i 's/ALLOWED_HOSTS=/ALLOWED_HOSTS=shop.lamadre.pl,37.27.44.248,/' .env
    fi
fi

# Tworzenie katalogów
log "Tworzę katalogi..."
mkdir -p logs media staticfiles

# Ustawienie uprawnień
log "Ustawiam uprawnienia..."
chown -R $SUDO_USER:$SUDO_USER $APP_DIR
chmod -R 755 $APP_DIR

# Budowanie i uruchomienie Docker
log "Buduję i uruchamiam kontenery..."
docker-compose build --no-cache
docker-compose up -d

# Czekam na uruchomienie bazy danych
log "Czekam na uruchomienie bazy danych..."
sleep 30

# Sprawdź status kontenerów
log "Sprawdzam status kontenerów..."
docker-compose ps

# Migracje i setup
log "Wykonuję migracje..."
docker-compose exec -T web python manage.py migrate

log "Kolekcjonuję pliki statyczne..."
docker-compose exec -T web python manage.py collectstatic --noinput

log "Tworzę superużytkownika..."
echo "Tworzenie superużytkownika Django..."
echo "Uruchom: docker-compose exec web python manage.py createsuperuser"

# Konfiguracja Nginx jako reverse proxy
log "Konfiguruję Nginx dla domeny shop.lamadre.pl..."
cat > /etc/nginx/sites-available/lamadre-django << 'EOF'
server {
    listen 80;
    server_name shop.lamadre.pl www.shop.lamadre.pl 37.27.44.248;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Static files
    location /static/ {
        alias /opt/lamadre-django/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Media files
    location /media/ {
        alias /opt/lamadre-django/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Django application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_req zone=login burst=5 nodelay;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check
    location /health/ {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Aktywacja strony
log "Aktywuję stronę Nginx..."
ln -sf /etc/nginx/sites-available/lamadre-django /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default  # Usuń domyślną stronę

# Test konfiguracji Nginx
log "Testuję konfigurację Nginx..."
nginx -t

# Restart Nginx
log "Restartuję Nginx..."
systemctl restart nginx

# Firewall (UFW)
log "Konfiguruję firewall..."
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# Tworzenie skryptu restart
cat > /usr/local/bin/lamadre-restart << 'EOF'
#!/bin/bash
cd /opt/lamadre-django
docker-compose restart
systemctl restart nginx
echo "LaMadre Django zrestartowany!"
EOF

chmod +x /usr/local/bin/lamadre-restart

# Tworzenie skryptu update
cat > /usr/local/bin/lamadre-update << 'EOF'
#!/bin/bash
cd /opt/lamadre-django
git pull origin main
docker-compose build --no-cache
docker-compose up -d
docker-compose exec -T web python manage.py migrate
docker-compose exec -T web python manage.py collectstatic --noinput
systemctl restart nginx
echo "LaMadre Django zaktualizowany!"
EOF

chmod +x /usr/local/bin/lamadre-update

# Tworzenie skryptu status
cat > /usr/local/bin/lamadre-status << 'EOF'
#!/bin/bash
echo "=== LaMadre Django Status ==="
cd /opt/lamadre-django
echo "Kontenery:"
docker-compose ps
echo ""
echo "Nginx:"
systemctl status nginx --no-pager -l
echo ""
echo "Docker:"
systemctl status docker --no-pager -l
EOF

chmod +x /usr/local/bin/lamadre-status

# Tworzenie skryptu SSL
cat > /usr/local/bin/lamadre-ssl << 'EOF'
#!/bin/bash
echo "🔒 Konfiguruję SSL dla shop.lamadre.pl..."
certbot --nginx -d shop.lamadre.pl -d www.shop.lamadre.pl
echo "✅ SSL skonfigurowane!"
echo "🔄 Restartuję Nginx..."
systemctl restart nginx
EOF

chmod +x /usr/local/bin/lamadre-ssl

# Tworzenie skryptu SSH test
cat > /usr/local/bin/lamadre-ssh-test << 'EOF'
#!/bin/bash
echo "🔑 Testuję połączenie SSH z GitHub..."
ssh -T git@github.com
echo ""
echo "📋 Jeśli widzisz błąd, sprawdź:"
echo "1. Czy SSH key jest dodany do GitHub"
echo "2. Czy uprawnienia są poprawne (600 dla private, 644 dla public)"
echo "3. Czy SSH config jest skonfigurowany"
EOF

chmod +x /usr/local/bin/lamadre-ssh-test

# Status
log "Sprawdzam status serwisów..."
docker-compose ps
systemctl status nginx --no-pager -l

# Informacje o dostępie
echo ""
echo "🎉 DEPLOYMENT ZAKOŃCZONY POMYŚLNIE!"
echo ""
echo "📋 Informacje o serwerze:"
echo "   IP: 37.27.44.248"
echo "   Domena: shop.lamadre.pl"
echo "   Katalog: $APP_DIR"
echo "   Użytkownik: $SUDO_USER"
echo ""
echo "📋 Następne kroki:"
echo "1. Edytuj plik .env w $APP_DIR"
echo "2. Uruchom: docker-compose exec web python manage.py createsuperuser"
echo "3. Skonfiguruj DNS w CloudFlare:"
echo "   - A record: shop.lamadre.pl → 37.27.44.248"
echo "   - A record: www.shop.lamadre.pl → 37.27.44.248"
echo "4. Uruchom: lamadre-ssl (automatyczna konfiguracja SSL)"
echo ""
echo "🔧 Przydatne komendy:"
echo "  lamadre-restart  - Restart aplikacji"
echo "  lamadre-update   - Aktualizacja z Git"
echo "  lamadre-status   - Status wszystkich serwisów"
echo "  lamadre-ssl      - Konfiguracja SSL"
echo "  lamadre-ssh-test - Test połączenia SSH z GitHub"
echo "  docker-compose logs -f web  - Logi aplikacji"
echo ""
echo "🌐 Aplikacja dostępna na:"
echo "   http://shop.lamadre.pl (po skonfigurowaniu DNS)"
echo "   http://37.27.44.248 (bezpośrednio przez IP)"
echo "   http://37.27.44.248:8000 (bezpośrednio Django)"
echo ""
echo "📊 Status: docker-compose ps"
echo "📊 Logi: docker-compose logs -f web"
echo ""
echo "🔒 Firewall: ufw status"
echo "🌐 Nginx: systemctl status nginx"
echo ""
echo "⚠️  WAŻNE: Skonfiguruj DNS w CloudFlare przed uruchomieniem SSL!"
echo ""
if [ "$SSH_WORKING" = true ]; then
    echo "✅ SSH: Połączenie z GitHub działa poprawnie!"
else
    echo "⚠️  SSH: Połączenie z GitHub nie działa. Uruchom: lamadre-ssh-test"
fi
echo "" 