#!/bin/bash

# LaMadre Django + WordPress - Deployment Script for Hetzner
# Uruchom jako root lub z sudo
# Ten skrypt zakłada, że WordPress już działa na porcie 80

set -e

echo "🚀 Rozpoczynam deployment LaMadre Django obok WordPress na Hetzner..."

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Sprawdź czy jesteś root
if [[ $EUID -ne 0 ]]; then
   error "Ten skrypt musi być uruchomiony jako root (sudo)"
fi

# Sprawdź czy Nginx działa
if ! systemctl is-active --quiet nginx; then
    error "Nginx nie jest uruchomiony. Uruchom WordPress najpierw!"
fi

# Sprawdź port 80
if netstat -tlnp | grep :80 | grep -q nginx; then
    log "Nginx działa na porcie 80 (WordPress)"
else
    warn "Port 80 nie jest zajęty przez Nginx. Sprawdź konfigurację WordPress!"
fi

# Instalacja Docker (jeśli nie ma)
if ! command -v docker &> /dev/null; then
    log "Instaluję Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    systemctl enable docker
    systemctl start docker
else
    log "Docker już zainstalowany"
fi

# Instalacja Docker Compose (jeśli nie ma)
if ! command -v docker-compose &> /dev/null; then
    log "Instaluję Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    log "Docker Compose już zainstalowany"
fi

# Tworzenie katalogu aplikacji
APP_DIR="/opt/lamadre-django"
log "Tworzę katalog aplikacji: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# Klonowanie repozytorium
if [ ! -d ".git" ]; then
    log "Klonuję repozytorium..."
    git clone https://github.com/Luczho/lamadre_django.git .
else
    log "Aktualizuję repozytorium..."
    git pull origin main
fi

# Konfiguracja środowiska
if [ ! -f ".env" ]; then
    log "Tworzę plik .env..."
    cp env.example .env
    
    # Generowanie SECRET_KEY
    SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    sed -i "s/your-secret-key-here/$SECRET_KEY/" .env
    
    # Konfiguracja produkcji
    sed -i 's/DEBUG=True/DEBUG=False/' .env
    sed -i 's/DB_HOST=localhost/DB_HOST=db/' .env
    sed -i 's/REDIS_URL=redis:\/\/localhost:6379\/0/REDIS_URL=redis:\/\/redis:6379\/0/' .env
    
    warn "Edytuj plik .env i ustaw prawdziwe dane przed uruchomieniem!"
    warn "Szczególnie: DB_PASSWORD, EMAIL_*"
else
    log "Plik .env już istnieje"
fi

# Tworzenie katalogów
log "Tworzę katalogi..."
mkdir -p logs media staticfiles

# Ustawienie uprawnień
log "Ustawiam uprawnienia..."
chown -R $SUDO_USER:$SUDO_USER $APP_DIR
chmod -R 755 $APP_DIR

# Modyfikacja docker-compose.yml dla portu 8000
log "Modyfikuję docker-compose.yml dla portu 8000..."
sed -i 's/- "8000:8000"/- "127.0.0.1:8000:8000"/' docker-compose.yml

# Budowanie i uruchomienie Docker
log "Buduję i uruchamiam kontenery..."
docker-compose build --no-cache
docker-compose up -d

# Czekam na uruchomienie bazy danych
log "Czekam na uruchomienie bazy danych..."
sleep 30

# Migracje i setup
log "Wykonuję migracje..."
docker-compose exec -T web python manage.py migrate

log "Kolekcjonuję pliki statyczne..."
docker-compose exec -T web python manage.py collectstatic --noinput

log "Tworzę superużytkownika..."
echo "Tworzenie superużytkownika Django..."
echo "Uruchom: docker-compose exec web python manage.py createsuperuser"

# Konfiguracja Nginx dla Django na porcie 8000
log "Dodaję konfigurację Django do Nginx..."
cat > /etc/nginx/sites-available/lamadre-django << 'EOF'
# LaMadre Django - Konfiguracja dla portu 8000
# Dodaj to do istniejącej konfiguracji WordPress

# Dodaj na końcu istniejącego server block w WordPress:
# location /django/ {
#     proxy_pass http://127.0.0.1:8000/;
#     proxy_set_header Host $host;
#     proxy_set_header X-Real-IP $remote_addr;
#     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#     proxy_set_header X-Forwarded-Proto $scheme;
#     proxy_redirect off;
#     
#     # Rate limiting
#     limit_req zone=api burst=20 nodelay;
#     
#     # Timeouts
#     proxy_connect_timeout 60s;
#     proxy_send_timeout 60s;
#     proxy_read_timeout 60s;
# }

# Lub stwórz nowy server block dla subdomeny:
server {
    listen 80;
    server_name django.twoja-domena.pl;  # Zastąp swoją domeną
    
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

# Tworzenie skryptu restart
cat > /usr/local/bin/lamadre-restart << 'EOF'
#!/bin/bash
cd /opt/lamadre-django
docker-compose restart
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
echo "LaMadre Django zaktualizowany!"
EOF

chmod +x /usr/local/bin/lamadre-update

# Status
log "Sprawdzam status serwisów..."
docker-compose ps

echo ""
echo "🎉 DEPLOYMENT DJANGO ZAKOŃCZONY POMYŚLNIE!"
echo ""
echo "📋 Następne kroki:"
echo "1. Edytuj plik .env w $APP_DIR"
echo "2. Uruchom: docker-compose exec web python manage.py createsuperuser"
echo "3. Wybierz opcję konfiguracji Nginx:"
echo "   a) Dodaj /django/ do istniejącej strony WordPress"
echo "   b) Stwórz subdomenę django.twoja-domena.pl"
echo "4. Skonfiguruj domenę w Nginx"
echo "5. Uruchom: certbot --nginx -d twoja-domena.pl"
echo ""
echo "🔧 Przydatne komendy:"
echo "  lamadre-restart  - Restart aplikacji Django"
echo "  lamadre-update   - Aktualizacja Django z Git"
echo "  docker-compose logs -f web  - Logi Django"
echo ""
echo "🌐 Django dostępne na: http://127.0.0.1:8000 (lokalnie)"
echo "📊 Status: docker-compose ps"
echo ""
echo "⚠️  UWAGA: WordPress nadal działa na porcie 80!"
echo "   Django działa na porcie 8000 (tylko lokalnie)"
echo "   Skonfiguruj Nginx aby udostępnić Django publicznie"
echo "" 