<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MedicineSearchResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $medicine = $this->medicine;
        $pharmacy = $this->pharmacy;

        return [
            'stock_id' => $this->id,
            'medicine' => [
                'id' => $medicine->id,
                'trade_name' => $medicine->trade_name,
                'scientific_name' => $medicine->scientific_name,
                'barcode' => $medicine->barcode,
                'dosage_form' => $medicine->dosage_form,
                'strength' => $medicine->strength,
                'manufacturer' => $medicine->manufacturer,
                'category' => $medicine->category?->name,
                'is_prescription_required' => $medicine->is_prescription_required,
            ],
            'pharmacy' => [
                'id' => $pharmacy->id,
                'name' => $pharmacy->name,
                'phone' => $pharmacy->phone,
                'address' => $pharmacy->address,
                'latitude' => (float) $pharmacy->latitude,
                'longitude' => (float) $pharmacy->longitude,
            ],
            'available_quantity' => $this->available_quantity,
            'price' => (float) $this->price,
            'currency' => 'YER',
            'status' => $this->status,
            'distance_km' => isset($this->distance_km) ? (float) $this->distance_km : null,
        ];
    }
}
