# LaMadre Django - Sklep E-commerce

Nowoczesny sklep internetowy oparty na frameworku Django Oscar, oferujący pełną funkcjonalność e-commerce.

## 🚀 Funkcjonalności

- **Zarządzanie produktami** - katalog produktów z kategoriami
- **Koszyk zakupów** - dodawanie, edycja i usuwanie produktów
- **Proces zamawiania** - kompletny checkout z różnymi metodami płatności
- **Panel administracyjny** - zaawansowany dashboard dla administratorów
- **System użytkowników** - rejestracja, logowanie, profile klientów
- **Wyszukiwanie** - wyszukiwanie produktów z filtrami
- **Recenzje i oceny** - system oceniania produktów
- **Kupony i promocje** - system rabatów i ofert
- **Wishlisty** - listy życzeń użytkowników
- **API REST** - pełne API do integracji z frontendem

## 🛠️ Technologie

- **Backend**: Django 5.2 + Django Oscar 4.0
- **Baza danych**: PostgreSQL 15
- **Cache**: Redis 7
- **Task Queue**: Celery
- **Web Server**: Gunicorn
- **Reverse Proxy**: Nginx
- **Containerization**: Docker + Docker Compose
- **Package Manager**: Poetry
- **Frontend**: Bootstrap 5 + Custom CSS/JS

## 📋 Wymagania systemowe

- Python 3.11+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+

## 🚀 Szybki start

### 1. Klonowanie repozytorium

```bash
git clone <repository-url>
cd lamadre-django
```

### 2. Konfiguracja środowiska

```bash
# Kopiowanie pliku środowiska
cp env.example .env

# Edycja zmiennych środowiskowych
nano .env
```

### 3. Uruchomienie z Docker

```bash
# Budowanie i uruchomienie kontenerów
docker-compose up --build

# Uruchomienie w tle
docker-compose up -d
```

### 4. Inicjalizacja bazy danych

```bash
# Wykonanie migracji
docker-compose exec web python manage.py migrate

# Tworzenie superużytkownika
docker-compose exec web python manage.py createsuperuser

# Ładowanie danych początkowych Oscar
docker-compose exec web python manage.py oscar_populate_countries
docker-compose exec web python manage.py oscar_import_catalogue
```

### 5. Dostęp do aplikacji

- **Aplikacja**: http://localhost:8000
- **Panel admin**: http://localhost:8000/dashboard/
- **Django Admin**: http://localhost:8000/admin/

## 🔧 Konfiguracja

### Zmienne środowiskowe

Główne zmienne do skonfigurowania w pliku `.env`:

```bash
# Django
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Baza danych
DB_NAME=lamadre_db
DB_USER=lamadre_user
DB_PASSWORD=lamadre_password
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Email
EMAIL_HOST=localhost
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
```

### Struktura katalogów

```
lamadre-django/
├── lamadre_django/          # Główny projekt Django
├── shop/                    # Aplikacja sklepu
├── templates/               # Szablony HTML
│   ├── base.html           # Szablon bazowy
│   └── shop/               # Szablony sklepu
├── static/                  # Pliki statyczne
│   ├── css/                # Style CSS
│   ├── js/                 # Skrypty JavaScript
│   └── images/             # Obrazy
├── nginx/                   # Konfiguracja Nginx
├── logs/                    # Logi aplikacji
├── docker-compose.yml       # Konfiguracja Docker Compose
├── Dockerfile              # Obraz Docker
├── pyproject.toml          # Konfiguracja Poetry
└── README.md               # Ten plik
```

## 🐳 Docker

### Kontenery

- **web**: Aplikacja Django + Gunicorn
- **db**: Baza danych PostgreSQL
- **redis**: Cache Redis
- **celery**: Worker Celery dla zadań asynchronicznych
- **nginx**: Reverse proxy + serwer statycznych plików

### Komendy Docker

```bash
# Uruchomienie wszystkich serwisów
docker-compose up

# Uruchomienie w tle
docker-compose up -d

# Zatrzymanie serwisów
docker-compose down

# Przebudowanie obrazów
docker-compose build --no-cache

# Logi konkretnego serwisu
docker-compose logs web

# Wykonanie komendy w kontenerze
docker-compose exec web python manage.py shell
```

## 🧪 Testy

```bash
# Uruchomienie testów
docker-compose exec web python manage.py test

# Testy z pokryciem
docker-compose exec web python manage.py test --coverage

# Testy konkretnej aplikacji
docker-compose exec web python manage.py test shop
```

## 📊 Monitoring

### Health Check

- **Aplikacja**: http://localhost:8000/health/
- **Nginx**: http://localhost/health/

### Logi

```bash
# Logi Django
docker-compose exec web tail -f logs/django.log

# Logi Nginx
docker-compose logs nginx

# Logi PostgreSQL
docker-compose logs db
```

## 🔒 Bezpieczeństwo

- HTTPS/SSL (konfiguracja w Nginx)
- Headers bezpieczeństwa
- Rate limiting
- Walidacja formularzy
- Sanityzacja danych wejściowych

## 🚀 Deployment

### Produkcja

1. Ustaw `DEBUG=False` w `.env`
2. Skonfiguruj HTTPS w Nginx
3. Użyj silnego `SECRET_KEY`
4. Skonfiguruj monitoring i logi
5. Ustaw backup bazy danych

### CI/CD

Przykładowa konfiguracja GitHub Actions w `.github/workflows/deploy.yml`

## 🤝 Rozwój

### Dodawanie nowych funkcji

1. Stwórz nową aplikację Django
2. Dodaj modele w `models.py`
3. Stwórz widoki w `views.py`
4. Dodaj URL-e w `urls.py`
5. Stwórz szablony w `templates/`
6. Dodaj testy

### Code Style

- **Python**: Black, Flake8, isort
- **JavaScript**: ESLint, Prettier
- **CSS**: Stylelint

```bash
# Formatowanie kodu
docker-compose exec web black .
docker-compose exec web isort .
docker-compose exec web flake8 .
```

## 📝 Licencja

Ten projekt jest licencjonowany pod licencją MIT - zobacz plik [LICENSE](LICENSE) dla szczegółów.

## 👥 Autorzy

- **Bartel** - Główny programista

## 🙏 Podziękowania

- Django Oscar team za wspaniały framework e-commerce
- Społeczność Django za wsparcie i dokumentację
- Wszystkim kontrybutorom open source

## 📞 Wsparcie

W przypadku problemów lub pytań:

1. Sprawdź [Issues](../../issues)
2. Przeczytaj dokumentację Django Oscar
3. Skontaktuj się z zespołem deweloperskim

---

**LaMadre Django** - Twój profesjonalny sklep internetowy! 🛍️ 