<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MensWearStoreSeeder extends Seeder
{
    /**
     * Configure the store for the MensWear theme.
     */
    public function run(): void
    {
        DB::table('channels')->where('id', 1)->update([
            'theme' => 'menswear',
            'hostname' => parse_url(env('APP_URL', config('app.url')), PHP_URL_HOST) ?: 'localhost',
        ]);

        DB::table('channel_translations')->where('channel_id', 1)->update([
            'name' => 'MENSWEAR',
            'description' => 'Premium men\'s clothing — shirts, pants, jackets & accessories.',
            'home_seo' => json_encode([
                'meta_title' => 'MENSWEAR — Premium Men\'s Clothing',
                'meta_description' => 'Shop premium men\'s clothing with sizes S–XL and multiple colors. Free shipping on orders over $75.',
                'meta_keywords' => 'mens clothing, shirts, pants, jackets, menswear, fashion',
            ]),
        ]);

        DB::table('theme_customizations')
            ->where('channel_id', 1)
            ->update(['theme_code' => 'menswear']);

        DB::table('core_config')->updateOrInsert(
            ['code' => 'general.content.footer.copyright_content'],
            [
                'value' => '&copy; ' . date('Y') . ' MENSWEAR. All rights reserved.',
                'channel_code' => null,
                'locale_code' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        $this->updateServicesContent();
    }

    protected function updateServicesContent(): void
    {
        $services = DB::table('theme_customizations')
            ->where('type', 'services_content')
            ->where('channel_id', 1)
            ->first();

        if (! $services) {
            return;
        }

        DB::table('theme_customization_translations')
            ->where('theme_customization_id', $services->id)
            ->update([
                'options' => json_encode([
                    'services' => [
                        [
                            'title' => 'Free Shipping',
                            'description' => 'On all orders over $75',
                            'service_icon' => 'icon-truck',
                        ],
                        [
                            'title' => 'Easy Returns',
                            'description' => '30-day hassle-free returns',
                            'service_icon' => 'icon-return',
                        ],
                        [
                            'title' => 'Secure Checkout',
                            'description' => 'Encrypted & protected payments',
                            'service_icon' => 'icon-security',
                        ],
                        [
                            'title' => 'Premium Quality',
                            'description' => 'Curated fabrics & modern fits',
                            'service_icon' => 'icon-quality',
                        ],
                    ],
                ]),
            ]);
    }
}
