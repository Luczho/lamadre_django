# 🚀 Deployment LaMadre Django na Hetzner

## 📋 Wymagania

- Serwer Hetzner z Ubuntu 20.04+ lub Debian 11+
- Minimum 2GB RAM, 2 vCPU, 20GB dysku
- Dostęp SSH jako root lub sudo
- Domena (opcjonalnie, ale zalecane)

## 🎯 Opcje deploymentu

### **Opcja 1: Tylko Django (zastępuje WordPress)**
```bash
# Sklonuj repozytorium na serwerze
git clone https://github.com/Luczho/lamadre_django.git
cd lamadre_django

# Uruchom skrypt deploymentowy
chmod +x deploy.sh
sudo ./deploy.sh
```

### **Opcja 2: Django + WordPress (obok siebie)**
```bash
# Sklonuj repozytorium na serwerze
git clone https://github.com/Luczho/lamadre_django.git
cd lamadre_django

# Uruchom skrypt dla WordPress + Django
chmod +x deploy-wordpress-django.sh
sudo ./deploy-wordpress-django.sh
```

## 🔧 Konfiguracja po deploymentzie

### **1. Edycja pliku .env**
```bash
cd /opt/lamadre-django
nano .env
```

**Ważne zmienne do ustawienia:**
```bash
# Django
SECRET_KEY=wygenerowany-automatycznie
DEBUG=False
ALLOWED_HOSTS=twoja-domena.pl,www.twoja-domena.pl

# Baza danych
DB_NAME=lamadre_db
DB_USER=lamadre_user
DB_PASSWORD=twoje-silne-haslo

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=twoj-email@gmail.com
EMAIL_HOST_PASSWORD=twoje-haslo-aplikacji
```

### **2. Tworzenie superużytkownika**
```bash
docker-compose exec web python manage.py createsuperuser
```

### **3. Konfiguracja Nginx**

#### **A) Jeśli chcesz Django na subdomenie:**
```bash
# Edytuj konfigurację Nginx
sudo nano /etc/nginx/sites-available/lamadre-django

# Zmień server_name na swoją domenę
server_name django.twoja-domena.pl;

# Aktywuj stronę
sudo ln -sf /etc/nginx/sites-available/lamadre-django /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### **B) Jeśli chcesz Django na ścieżce /django/:**
```bash
# Edytuj konfigurację WordPress
sudo nano /etc/nginx/sites-available/twoja-strona-wordpress

# Dodaj na końcu server block:
location /django/ {
    proxy_pass http://127.0.0.1:8000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;
}

# Restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

### **4. SSL/HTTPS z Let's Encrypt**
```bash
# Dla subdomeny
sudo certbot --nginx -d django.twoja-domena.pl

# Dla głównej domeny (jeśli zastępujesz WordPress)
sudo certbot --nginx -d twoja-domena.pl
```

## 🔍 Monitoring i logi

### **Status aplikacji**
```bash
# Status kontenerów
docker-compose ps

# Logi aplikacji
docker-compose logs -f web

# Logi bazy danych
docker-compose logs -f db

# Logi Redis
docker-compose logs -f redis
```

### **Status systemu**
```bash
# Status Nginx
sudo systemctl status nginx

# Status Docker
sudo systemctl status docker

# Użycie zasobów
htop
df -h
free -h
```

## 🛠️ Przydatne komendy

### **Restart aplikacji**
```bash
lamadre-restart
```

### **Aktualizacja z Git**
```bash
lamadre-update
```

### **Backup bazy danych**
```bash
# Backup
docker-compose exec db pg_dump -U lamadre_user lamadre_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore
docker-compose exec -T db psql -U lamadre_user -d lamadre_db < backup_file.sql
```

### **Aktualizacja systemu**
```bash
sudo apt update && sudo apt upgrade -y
docker system prune -f
```

## 🚨 Rozwiązywanie problemów

### **Problem: Aplikacja nie uruchamia się**
```bash
# Sprawdź logi
docker-compose logs web

# Sprawdź status kontenerów
docker-compose ps

# Restart wszystkich kontenerów
docker-compose restart
```

### **Problem: Błąd bazy danych**
```bash
# Sprawdź logi bazy
docker-compose logs db

# Sprawdź połączenie
docker-compose exec web python manage.py dbshell

# Wykonaj migracje
docker-compose exec web python manage.py migrate
```

### **Problem: Błąd Nginx**
```bash
# Test konfiguracji
sudo nginx -t

# Sprawdź logi
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### **Problem: Port 8000 zajęty**
```bash
# Sprawdź co używa portu
sudo netstat -tlnp | grep :8000

# Zatrzymaj proces lub zmień port w docker-compose.yml
```

## 🔒 Bezpieczeństwo

### **Firewall (UFW)**
```bash
# Sprawdź status
sudo ufw status

# Dodaj reguły (jeśli potrzebne)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
```

### **Regularne aktualizacje**
```bash
# Dodaj do crontab
sudo crontab -e

# Aktualizuj system co tydzień
0 2 * * 0 apt update && apt upgrade -y

# Restart aplikacji co miesiąc
0 3 1 * * /usr/local/bin/lamadre-restart
```

## 📊 Optymalizacja wydajności

### **Nginx**
```bash
# Edytuj /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
```

### **Django**
```bash
# W .env
DEBUG=False
ALLOWED_HOSTS=twoja-domena.pl

# Cache Redis
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}
```

### **PostgreSQL**
```bash
# Edytuj postgresql.conf w kontenerze
docker-compose exec db bash
nano /var/lib/postgresql/data/postgresql.conf

# Optymalizacje:
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

## 🎉 Gotowe!

Po wykonaniu wszystkich kroków:
- Django będzie dostępne na skonfigurowanej domenie
- Panel admin na `/dashboard/`
- API na `/api/` (jeśli skonfigurowane)
- SSL/HTTPS będzie działać
- Monitoring i logi będą dostępne

**Dostęp do aplikacji:**
- **Frontend**: https://twoja-domena.pl
- **Dashboard**: https://twoja-domena.pl/dashboard/
- **Admin**: https://twoja-domena.pl/admin/

---

**Potrzebujesz pomocy?** Sprawdź logi i użyj komend diagnostycznych z sekcji "Rozwiązywanie problemów". 