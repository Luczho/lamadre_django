.PHONY: help install test run clean docker-build docker-up docker-down docker-logs migrate superuser shell

help: ## Show this help message
	@echo "LaMadre Django - Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies with Poetry
	poetry install

test: ## Run tests
	poetry run python manage.py test

run: ## Run development server
	poetry run python manage.py runserver

clean: ## Clean Python cache files
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +

docker-build: ## Build Docker images
	docker-compose build

docker-up: ## Start Docker services
	docker-compose up -d

docker-down: ## Stop Docker services
	docker-compose down

docker-logs: ## Show Docker logs
	docker-compose logs -f

migrate: ## Run database migrations
	docker-compose exec web python manage.py migrate

superuser: ## Create superuser
	docker-compose exec web python manage.py createsuperuser

shell: ## Open Django shell
	docker-compose exec web python manage.py shell

collectstatic: ## Collect static files
	docker-compose exec web python manage.py collectstatic --noinput

oscar-setup: ## Setup Oscar initial data
	docker-compose exec web python manage.py oscar_populate_countries
	docker-compose exec web python manage.py oscar_import_catalogue

format: ## Format code with Black and isort
	poetry run black .
	poetry run isort .

lint: ## Run linting checks
	poetry run flake8 .
	poetry run black --check .
	poetry run isort --check-only .

setup-dev: ## Setup development environment
	cp env.example .env
	poetry install
	docker-compose up -d
	sleep 10
	docker-compose exec web python manage.py migrate
	docker-compose exec web python manage.py collectstatic --noinput
	@echo "Development environment setup complete!"
	@echo "Access the application at: http://localhost:8000"
	@echo "Access the dashboard at: http://localhost:8000/dashboard/" 