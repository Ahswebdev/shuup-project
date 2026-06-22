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

echo "==> Configuring nginx on port ${PORT}"
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "==> Waiting for database..."
for i in $(seq 1 60); do
    if php -r "
        require 'vendor/autoload.php';
        \$app = require 'bootstrap/app.php';
        \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
        try {
            Illuminate\Support\Facades\DB::connection()->getPdo();
            exit(0);
        } catch (Throwable \$e) {
            exit(1);
        }
    " 2>/dev/null; then
        echo "==> Database is ready."
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "==> ERROR: Database not reachable after 60s"
        exit 1
    fi
    sleep 2
done

echo "==> Running migrations"
php artisan migrate --force --no-interaction

if [ "${RUN_SEED:-false}" = "true" ]; then
    echo "==> Seeding database (first deploy)"
    php artisan db:seed --force --no-interaction
    php artisan db:seed --class="Webkul\\Installer\\Database\\Seeders\\ProductTableSeeder" --force --no-interaction
    php artisan db:seed --class="Database\\Seeders\\MensWearStoreSeeder" --force --no-interaction
fi

php artisan storage:link --force 2>/dev/null || true
php artisan optimize:clear --no-interaction
php artisan config:cache --no-interaction
php artisan route:cache --no-interaction
php artisan view:cache --no-interaction

echo "==> Starting services"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
