# MENSWEAR — Premium Men's Clothing Store

A modern men's clothing e-commerce store built on [Bagisto](https://bagisto.com), featuring a clean black-and-white design inspired by Zara and H&M.

## Features

- **Premium storefront theme** — Minimal black & white design with Inter typography
- **Full e-commerce pages** — Home, Shop, Categories, Product Detail, Cart, Checkout, Wishlist, Login/Register, Order Tracking, Contact
- **Product variants** — Size (S, M, L, XL) and Color support via Bagisto's configurable products
- **Responsive design** — Mobile-first layout that works across all devices
- **Bagisto backend** — Full admin panel for products, orders, customers, and inventory

## Requirements

- PHP 8.3+
- Composer 2.5+
- MySQL 8.0+
- Node.js 18+

## Quick Start

### 1. Install dependencies

```bash
composer install
cd packages/Webkul/Shop && npm install && npm run build && cd ../../..
```

### 2. Configure environment

Copy `.env.example` to `.env` and set your database credentials:

```
DB_DATABASE=bagisto_mens
DB_USERNAME=root
DB_PASSWORD=
APP_URL=http://localhost:8000
```

### 3. Run migrations & seed

```bash
php artisan key:generate
php artisan migrate:fresh --seed --force
php artisan db:seed --class="Webkul\Installer\Database\Seeders\ProductTableSeeder" --force
php artisan db:seed --class="Database\Seeders\MensWearStoreSeeder" --force
php artisan storage:link
php artisan optimize:clear
```

### 4. Start the server

```bash
php artisan serve
```

Visit **http://localhost:8000** for the storefront.

## Admin Panel

- URL: **http://localhost:8000/admin**
- Email: `admin@example.com`
- Password: `admin123`

## Store Pages

| Page | URL |
|------|-----|
| Home | `/` |
| Shop / Search | `/search` |
| Categories | Via navigation menu |
| Product Detail | `/product/{slug}` |
| Cart | `/checkout/cart` |
| Checkout | `/checkout/onepage` |
| Wishlist | `/customer/account/wishlist` |
| Login | `/customer/login` |
| Register | `/customer/register` |
| Order Tracking | `/customer/account/orders` |
| Contact | `/contact-us` |

## Theme Customization

The MensWear theme lives in:

- **Views:** `resources/themes/menswear/views/`
- **Styles:** `public/themes/shop/menswear/css/menswear.css`
- **Config:** `config/themes.php`

To activate the theme in admin: **Settings → Channels → Edit → Theme → MensWear**

## Product Variants

Products support configurable attributes out of the box:

- **Size:** S, M, L, XL
- **Color:** Red, Green, Yellow, Black, White

Create configurable products in the admin panel under **Catalog → Products → Create → Configurable**.

## Development

Rebuild frontend assets after changes:

```bash
cd packages/Webkul/Shop
npm run dev    # development with hot reload
npm run build  # production build
```

## Host for free (client demo)

See **[DEPLOY-FREE.md](DEPLOY-FREE.md)** for step-by-step instructions to deploy at **$0/month** using:

- **Render** (free web service)
- **Neon** (free PostgreSQL — no 30-day database expiry)

Quick summary: push to GitHub → create Neon database → deploy via Render Blueprint (`render.yaml`).

---
