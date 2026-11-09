<?php

namespace Database\Seeders;

use App\Models\GymClass;
use Illuminate\Database\Seeder;

class ClassSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            ['Morning Yoga', 'Studio A', 'Coach Rina', 'Yoga', 7],
            ['Core & Abs', 'Studio B', 'Coach Dimas', 'Core', 12],
            ['Yoga Flow', 'Studio A', 'Coach Rina', 'Yoga', 17],
            ['HIIT Burn', 'Studio B', 'Coach Dimas', 'HIIT', 19],
            ['Zumba Night', 'Studio A', 'Coach Sari', 'Zumba', 20],
        ];
        for ($d = 0; $d < 7; $d++) {
            foreach ($rows as [$title, $studio, $coach, $cat, $hour]) {
                GymClass::updateOrCreate(
                    ['title' => $title, 'starts_at' => today()->addDays($d)->setHour($hour)],
                    ['studio' => $studio, 'coach' => $coach, 'category' => $cat, 'capacity' => 10],
                );
            }
        }
    }
}
