<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReservationResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reservation_code' => $this->reservation_code,
            'status' => $this->status,
            'total_amount' => (float) $this->total_amount,
            'currency' => 'YER',
            'expires_at' => $this->expires_at?->toIso8601String(),
            'ttl_seconds_remaining' => $this->expires_at ? (int) max(0, (int) now()->diffInSeconds($this->expires_at, false)) : 0,
            'is_expired' => $this->isExpired(),
            'pharmacy' => [
                'id' => $this->pharmacy->id,
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'latitude' => (float) $this->pharmacy->latitude,
                'longitude' => (float) $this->pharmacy->longitude,
            ],
            'items' => $this->reservationItems->map(function ($item) {
                $medicine = $item->pharmacyMedicine?->medicine;

                return [
                    'medicine_name' => $medicine?->trade_name,
                    'scientific_name' => $medicine?->scientific_name,
                    'quantity' => $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'subtotal' => (float) ($item->quantity * $item->unit_price),
                ];
            }),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
