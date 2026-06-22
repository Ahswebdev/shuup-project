#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

export PORT="${PORT:-10000}"

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        cat > .env <<EOF
APP_NAME=${APP_NAME:-MENSWEAR}
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY:-}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-http://localhost}
APP_ADMIN_URL=${APP_ADMIN_URL:-admin}
LOG_CHANNEL=${LOG_CHANNEL:-stderr}
DB_CONNECTION=${DB_CONNECTION:-pgsql}
DB_SSLMODE=${DB_SSLMODE:-require}
SESSION_DRIVER=${SESSION_DRIVER:-database}
CACHE_STORE=${CACHE_STORE:-file}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
FILESYSTEM_DISK=${FILESYSTEM_DISK:-public}
EOF
    fi
fi

export DB_URL="${DB_URL:-${DATABASE_URL:-}}"

# Sync Render env vars into .env for artisan
for var in APP_KEY APP_URL DATABASE_URL DB_CONNECTION DB_SSLMODE; do
    val="${!var:-}"
    if [ -n "$val" ]; then
        if grep -q "^${var}=" .env 2>/dev/null; then
            sed -i "s|^${var}=.*|${var}=${val}|" .env
        else
            echo "${var}=${val}" >> .env
        fi
    fi
done

echo "==> Configuring nginx on port ${PORT}"
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

run_setup() {
    echo "==> [setup] Waiting for database..."
    for i in $(seq 1 90); do
        if php -r "
            require 'vendor/autoload.php';
            \$app = require 'bootstrap/app.php';
            \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
            Illuminate\Support\Facades\DB::connection()->getPdo();
        " 2>/dev/null; then
            echo "==> [setup] Database is ready."
            break
        fi
        if [ "$i" -eq 90 ]; then
            echo "==> [setup] WARNING: Database not reachable — site up, setup skipped."
            return 1
        fi
        sleep 2
    done

    echo "==> [setup] Running migrations"
    php artisan migrate --force --no-interaction

    if [ "${RUN_SEED:-false}" = "true" ]; then
        echo "==> [setup] Seeding database"
        php artisan db:seed --force --no-interaction
        php artisan db:seed --class="Webkul\\Installer\\Database\\Seeders\\ProductTableSeeder" --force --no-interaction
        php artisan db:seed --class="Database\\Seeders\\MensWearStoreSeeder" --force --no-interaction
    fi

    php artisan storage:link --force 2>/dev/null || true
    php artisan optimize:clear --no-interaction
    php artisan config:cache --no-interaction
    php artisan route:cache --no-interaction
    php artisan view:cache --no-interaction

    echo "==> [setup] Complete"
}

echo "==> Starting database setup in background"
run_setup &

echo "==> Starting web server on port ${PORT}"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
