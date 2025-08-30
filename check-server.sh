#!/bin/bash

# LaMadre Django - Server Health Check Script
# Server IP: 37.27.44.248
# Domain: shop.lamadre.pl

echo "🏥 Sprawdzam zdrowie serwera LaMadre Django..."
echo "📍 Serwer: 37.27.44.248"
echo "🌐 Domena: shop.lamadre.pl"
echo "🕐 Data: $(date)"
echo ""

# Kolory
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funkcje
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

check_warning() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${YELLOW}⚠️  $2${NC}"
    fi
}

echo -e "${BLUE}=== STATUS SYSTEMU ===${NC}"

# Sprawdź uptime
echo -n "Uptime: "
uptime | awk '{print $3, $4}' | sed 's/,//'

# Sprawdź użycie dysku
echo -n "Dysk: "
df -h / | awk 'NR==2 {print $5 " użyte z " $2 " (" $3 ")"}'

# Sprawdź RAM
echo -n "RAM: "
free -h | awk 'NR==2 {print $3 " użyte z " $2 " (" $4 " wolne)"}'

# Sprawdź CPU
echo -n "CPU: "
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1 "%"}'

echo ""

echo -e "${BLUE}=== STATUS SERWISÓW ===${NC}"

# Sprawdź Docker
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker: uruchomiony${NC}"
else
    echo -e "${RED}❌ Docker: zatrzymany${NC}"
fi

# Sprawdź Nginx
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx: uruchomiony${NC}"
else
    echo -e "${RED}❌ Nginx: zatrzymany${NC}"
fi

# Sprawdź Firewall
if ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}✅ Firewall: aktywny${NC}"
else
    echo -e "${YELLOW}⚠️  Firewall: nieaktywny${NC}"
fi

echo ""

echo -e "${BLUE}=== STATUS APLIKACJI ===${NC}"

# Sprawdź czy katalog aplikacji istnieje
if [ -d "/opt/lamadre-django" ]; then
    echo -e "${GREEN}✅ Katalog aplikacji: istnieje${NC}"
    
    # Sprawdź status kontenerów
    cd /opt/lamadre-django
    if [ -f "docker-compose.yml" ]; then
        echo "Status kontenerów:"
        docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${RED}❌ docker-compose.yml nie istnieje${NC}"
    fi
else
    echo -e "${RED}❌ Katalog aplikacji: nie istnieje${NC}"
fi

echo ""

echo -e "${BLUE}=== PORTY ===${NC}"

# Sprawdź port 80 (HTTP)
if netstat -tlnp | grep -q ":80 "; then
    echo -e "${GREEN}✅ Port 80: otwarty${NC}"
else
    echo -e "${RED}❌ Port 80: zamknięty${NC}"
fi

# Sprawdź port 8000 (Django)
if netstat -tlnp | grep -q ":8000 "; then
    echo -e "${GREEN}✅ Port 8000: otwarty${NC}"
else
    echo -e "${YELLOW}⚠️  Port 8000: zamknięty${NC}"
fi

# Sprawdź port 22 (SSH)
if netstat -tlnp | grep -q ":22 "; then
    echo -e "${GREEN}✅ Port 22: otwarty${NC}"
else
    echo -e "${RED}❌ Port 22: zamknięty${NC}"
fi

echo ""

echo -e "${BLUE}=== DOSTĘPNOŚĆ ===${NC}"

# Sprawdź dostępność przez HTTP
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ HTTP (localhost): dostępne${NC}"
else
    echo -e "${RED}❌ HTTP (localhost): niedostępne${NC}"
fi

# Sprawdź dostępność Django
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ Django (localhost:8000): dostępne${NC}"
else
    echo -e "${YELLOW}⚠️  Django (localhost:8000): niedostępne${NC}"
fi

# Sprawdź dostępność przez IP
if curl -s -o /dev/null -w "%{http_code}" http://37.27.44.248 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ HTTP (37.27.44.248): dostępne${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP (37.27.44.248): niedostępne${NC}"
fi

echo ""

echo -e "${BLUE}=== DNS I DOMENA ===${NC}"

# Sprawdź rozwiązywanie DNS
if nslookup shop.lamadre.pl > /dev/null 2>&1; then
    echo -e "${GREEN}✅ DNS shop.lamadre.pl: rozwiązywane${NC}"
    echo "   IP: $(nslookup shop.lamadre.pl | grep 'Address:' | tail -1 | awk '{print $2}')"
else
    echo -e "${YELLOW}⚠️  DNS shop.lamadre.pl: problem z rozwiązywaniem${NC}"
fi

# Sprawdź czy domena wskazuje na nasz serwer
DNS_IP=$(nslookup shop.lamadre.pl 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}')
if [ "$DNS_IP" = "37.27.44.248" ]; then
    echo -e "${GREEN}✅ DNS shop.lamadre.pl → 37.27.44.248${NC}"
else
    echo -e "${YELLOW}⚠️  DNS shop.lamadre.pl → $DNS_IP (oczekiwane: 37.27.44.248)${NC}"
fi

echo ""

echo -e "${BLUE}=== LOGI (ostatnie 5 linii) ===${NC}"

# Logi Django
if [ -f "/opt/lamadre-django/logs/django.log" ]; then
    echo "Django logi:"
    tail -5 /opt/lamadre-django/logs/django.log
else
    echo -e "${YELLOW}⚠️  Plik logów Django nie istnieje${NC}"
fi

echo ""

echo -e "${BLUE}=== REKOMENDACJE ===${NC}"

# Sprawdź czy są problemy
if ! systemctl is-active --quiet docker; then
    echo -e "${RED}🔧 Uruchom Docker: sudo systemctl start docker${NC}"
fi

if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}🔧 Uruchom Nginx: sudo systemctl start nginx${NC}"
fi

if ! netstat -tlnp | grep -q ":80 "; then
    echo -e "${RED}🔧 Port 80 nie jest otwarty - sprawdź Nginx${NC}"
fi

if ! netstat -tlnp | grep -q ":8000 "; then
    echo -e "${YELLOW}🔧 Port 8000 nie jest otwarty - sprawdź Django${NC}"
fi

if [ "$DNS_IP" != "37.27.44.248" ]; then
    echo -e "${YELLOW}🔧 Skonfiguruj DNS w CloudFlare: shop.lamadre.pl → 37.27.44.248${NC}"
fi

echo ""
echo "🏁 Sprawdzanie zakończone!"
echo "📊 Aby zobaczyć szczegółowy status: lamadre-status"
echo "🔄 Aby zrestartować: lamadre-restart"
echo "🔒 Aby skonfigurować SSL: lamadre-ssl"
echo "📝 Logi Django: docker-compose logs -f web"
echo ""
echo "🌐 Dostęp:"
echo "   - Przez IP: http://37.27.44.248"
echo "   - Przez domenę: http://shop.lamadre.pl (po skonfigurowaniu DNS)"
echo "   - Django bezpośrednio: http://37.27.44.248:8000" 