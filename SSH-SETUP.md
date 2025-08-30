# 🔑 Konfiguracja SSH dla serwera LaMadre Django

## 📋 Wymagania

- Serwer Hetzner: `37.27.44.248`
- Konto GitHub: `Luczho`
- Dostęp SSH do serwera jako root lub sudo

## 🚀 Automatyczna konfiguracja (ZALECANE)

### **1. Uruchom deployment script:**
```bash
# Na serwerze Hetzner
sudo ./deploy.sh
```

**Script automatycznie:**
- ✅ Generuje SSH key (ed25519)
- ✅ Konfiguruje SSH config
- ✅ Pokazuje public key do skopiowania
- ✅ Czeka na dodanie klucza do GitHub
- ✅ Testuje połączenie

## 🔧 Ręczna konfiguracja SSH

### **1. Generowanie SSH key:**
```bash
# Na serwerze Hetzner
ssh-keygen -t ed25519 -C "lamadre-django@37.27.44.248"
# Naciśnij Enter dla domyślnej lokalizacji
# Naciśnij Enter dla pustego hasła (lub ustaw silne)
```

### **2. Ustawienie uprawnień:**
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### **3. Konfiguracja SSH config:**
```bash
cat > ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
```

### **4. Wyświetlenie public key:**
```bash
cat ~/.ssh/id_ed25519.pub
```

## 🌐 Dodanie SSH key do GitHub

### **1. Logowanie do GitHub:**
- Idź na [github.com](https://github.com)
- Zaloguj się na konto `Luczho`

### **2. Dodanie SSH key:**
- **Settings** → **SSH and GPG keys**
- **New SSH key**
- **Title**: `lamadre-django@37.27.44.248`
- **Key type**: Authentication Key
- **Key**: Wklej public key z serwera
- **Add SSH key**

### **3. Weryfikacja:**
```bash
# Na serwerze
ssh -T git@github.com

# Powinieneś zobaczyć:
# Hi Luczho! You've successfully authenticated...
```

## 🔍 Testowanie połączenia

### **1. Test SSH:**
```bash
# Test połączenia
ssh -T git@github.com

# Test klonowania
git clone git@github.com:Luczho/lamadre_django.git test-repo
rm -rf test-repo
```

### **2. Test Git operations:**
```bash
# W katalogu aplikacji
cd /opt/lamadre-django
git remote -v
git fetch origin
git status
```

## 🚨 Rozwiązywanie problemów

### **Problem: Permission denied (publickey)**
```bash
# Sprawdź czy klucz istnieje
ls -la ~/.ssh/

# Sprawdź uprawnienia
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Test z verbose
ssh -vT git@github.com
```

### **Problem: Key not found**
```bash
# Sprawdź SSH config
cat ~/.ssh/config

# Sprawdź czy klucz jest używany
ssh-add -l

# Dodaj klucz do agenta
ssh-add ~/.ssh/id_ed25519
```

### **Problem: Host key verification failed**
```bash
# Usuń stary host key
ssh-keygen -R github.com

# Lub dodaj do known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

## 📊 Monitoring SSH

### **1. Sprawdź logi SSH:**
```bash
# Logi SSH
sudo tail -f /var/log/auth.log

# Sprawdź połączenia
ss -tuln | grep :22
```

### **2. Sprawdź status:**
```bash
# Status SSH service
sudo systemctl status ssh

# Sprawdź port 22
sudo netstat -tlnp | grep :22
```

## 🔒 Bezpieczeństwo SSH

### **1. Konfiguracja SSH server:**
```bash
# Edytuj /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Ważne ustawienia:
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

### **2. Restart SSH service:**
```bash
sudo systemctl restart ssh
sudo systemctl enable ssh
```

### **3. Firewall:**
```bash
# Sprawdź status
sudo ufw status

# Dodaj regułę SSH
sudo ufw allow 22/tcp
```

## 🎯 Finalna konfiguracja

### **Po skonfigurowaniu SSH:**
1. ✅ SSH key wygenerowany
2. ✅ Klucz dodany do GitHub
3. ✅ Połączenie SSH testowane
4. ✅ Git działa przez SSH
5. ✅ Deployment automatyczny

### **Przydatne komendy:**
```bash
lamadre-ssh-test    # Test SSH z GitHub
lamadre-update      # Aktualizacja przez SSH
git remote -v       # Sprawdź remote URLs
ssh -T git@github.com  # Test połączenia
```

## 🔄 Aktualizacje

### **Automatyczne aktualizacje:**
```bash
# Dodaj do crontab
sudo crontab -e

# Aktualizuj co godzinę
0 * * * * /usr/local/bin/lamadre-update

# Test SSH co 6 godzin
0 */6 * * * /usr/local/bin/lamadre-ssh-test
```

---

**Potrzebujesz pomocy?** Użyj `lamadre-ssh-test` lub sprawdź logi SSH! 