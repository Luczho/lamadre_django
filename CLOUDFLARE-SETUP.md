# 🌐 Konfiguracja CloudFlare dla shop.lamadre.pl

## 📋 Wymagania

- Domena `lamadre.pl` w CloudFlare
- Serwer Hetzner: `37.27.44.248`
- Dostęp do panelu CloudFlare

## 🚀 Kroki konfiguracji

### **1. Logowanie do CloudFlare**

1. Idź na [dash.cloudflare.com](https://dash.cloudflare.com)
2. Zaloguj się na swoje konto
3. Wybierz domenę `lamadre.pl`

### **2. Konfiguracja DNS**

#### **A) Dodaj A record dla shop.lamadre.pl:**

| Typ | Nazwa | IPv4 address | Proxy status | TTL |
|-----|-------|---------------|--------------|-----|
| A | shop | 37.27.44.248 | DNS only | Auto |

#### **B) Dodaj A record dla www.shop.lamadre.pl:**

| Typ | Nazwa | IPv4 address | Proxy status | TTL |
|-----|-------|---------------|--------------|-----|
| A | www.shop | 37.27.44.248 | DNS only | Auto |

### **3. Ustawienia CloudFlare**

#### **SSL/TLS:**
- **Encryption mode**: Full (strict)
- **Always Use HTTPS**: On
- **Minimum TLS Version**: 1.2

#### **Security:**
- **Security Level**: Medium
- **Browser Integrity Check**: On
- **Challenge Passage**: 30 minutes

#### **Performance:**
- **Auto Minify**: CSS, JavaScript, HTML
- **Brotli**: On
- **Rocket Loader**: On

### **4. Weryfikacja konfiguracji**

#### **Sprawdź DNS:**
```bash
# Na serwerze lub lokalnie
nslookup shop.lamadre.pl
nslookup www.shop.lamadre.pl
```

**Oczekiwany wynik:**
```
shop.lamadre.pl
Address: 37.27.44.248

www.shop.lamadre.pl
Address: 37.27.44.248
```

#### **Sprawdź propagację:**
- [whatsmydns.net](https://whatsmydns.net) - sprawdź propagację DNS
- [dnschecker.org](https://dnschecker.org) - sprawdź z różnych lokalizacji

## 🔒 Konfiguracja SSL po deploymentzie

### **1. Po uruchomieniu Django na serwerze:**
```bash
# Na serwerze Hetzner
cd /opt/lamadre-django
lamadre-ssl
```

### **2. Automatyczna konfiguracja:**
- Certbot automatycznie skonfiguruje SSL
- Nginx zostanie zrestartowany
- HTTPS będzie dostępne

## 🧪 Testowanie

### **1. Przed SSL:**
```bash
# HTTP przez IP
curl -I http://37.27.44.248

# HTTP przez domenę (po skonfigurowaniu DNS)
curl -I http://shop.lamadre.pl
```

### **2. Po SSL:**
```bash
# HTTPS przez domenę
curl -I https://shop.lamadre.pl

# Sprawdź certyfikat
openssl s_client -connect shop.lamadre.pl:443 -servername shop.lamadre.pl
```

## 🚨 Rozwiązywanie problemów

### **Problem: DNS nie rozwiązywane**
```bash
# Sprawdź czy A record istnieje
dig shop.lamadre.pl A

# Sprawdź propagację
nslookup shop.lamadre.pl 8.8.8.8
nslookup shop.lamadre.pl 1.1.1.1
```

### **Problem: CloudFlare proxy blokuje**
- Ustaw **Proxy status** na **DNS only** (szara chmura)
- Poczekaj na propagację (może potrwać do 24h)

### **Problem: SSL nie działa**
```bash
# Sprawdź certyfikat
sudo certbot certificates

# Sprawdź logi Nginx
sudo tail -f /var/log/nginx/error.log
```

## 📊 Monitoring

### **CloudFlare Analytics:**
- **Traffic**: Liczba requestów
- **Security**: Blokowane ataki
- **Performance**: Cache hit ratio
- **Reliability**: Uptime

### **Serwer monitoring:**
```bash
# Sprawdź status
lamadre-status

# Sprawdź zdrowie
./check-server.sh

# Logi w czasie rzeczywistym
docker-compose logs -f web
```

## 🔄 Aktualizacje

### **Automatyczne aktualizacje SSL:**
```bash
# Dodaj do crontab
sudo crontab -e

# Odnawiaj certyfikat co 60 dni
0 12 * * * /usr/bin/certbot renew --quiet
```

### **Aktualizacje Django:**
```bash
# Aktualizuj z Git
lamadre-update

# Restart aplikacji
lamadre-restart
```

## 🎯 Finalna konfiguracja

### **Po skonfigurowaniu CloudFlare:**
1. ✅ DNS wskazuje na `37.27.44.248`
2. ✅ Aplikacja działa na `http://shop.lamadre.pl`
3. ✅ SSL skonfigurowane (`lamadre-ssl`)
4. ✅ HTTPS dostępne na `https://shop.lamadre.pl`

### **Dostęp do aplikacji:**
- **Frontend**: https://shop.lamadre.pl
- **Dashboard**: https://shop.lamadre.pl/dashboard/
- **Admin**: https://shop.lamadre.pl/admin/
- **API**: https://shop.lamadre.pl/api/ (jeśli skonfigurowane)

---

**Potrzebujesz pomocy?** Sprawdź logi i użyj skryptów diagnostycznych! 