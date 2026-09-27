import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect_client/data/models/medicine_search_model.dart';
import 'package:pharma_connect_client/data/models/reservation_model.dart';
import 'package:pharma_connect_client/core/network/api_service.dart';

void main() {
  group('PharmaConnect Data Models & API Unit Tests', () {
    test('MedicineSearchItem correctly parses JSON payload', () {
      final jsonMap = {
        'stock_id': 101,
        'medicine': {
          'id': 1,
          'trade_name': 'Panadol Extra',
          'scientific_name': 'Paracetamol + Caffeine',
          'dosage_form': 'Tablets',
          'strength': '500mg',
          'manufacturer': 'GSK',
          'category': 'Pain Relief',
          'is_prescription_required': false,
        },
        'pharmacy': {
          'id': 5,
          'name': 'صيدلية النور',
          'phone': '+967771234567',
          'address': 'شارع الزبيري - صنعاء',
          'latitude': 15.3500,
          'longitude': 44.2000,
        },
        'available_quantity': 12,
        'price': 1500.0,
        'currency': 'YER',
        'status': 'available',
        'distance_km': 2.4,
      };

      final item = MedicineSearchItem.fromJson(jsonMap);

      expect(item.stockId, 101);
      expect(item.medicine.tradeName, 'Panadol Extra');
      expect(item.pharmacy.name, 'صيدلية النور');
      expect(item.availableQuantity, 12);
      expect(item.price, 1500.0);
      expect(item.distanceKm, 2.4);
    });

    test('ReservationModel correctly parses JSON payload', () {
      final jsonMap = {
        'id': 77,
        'reservation_code': 'RES-998877',
        'status': 'pending',
        'total_amount': 3000.0,
        'currency': 'YER',
        'expires_at': '2026-09-18T23:00:00Z',
        'ttl_seconds_remaining': 1800,
        'is_expired': false,
        'pharmacy': {
          'id': 5,
          'name': 'صيدلية النور',
          'phone': '+967771234567',
          'address': 'شارع الزبيري - صنعاء',
          'latitude': 15.3500,
          'longitude': 44.2000,
        },
        'items': [
          {
            'medicine_name': 'Panadol Extra',
            'scientific_name': 'Paracetamol + Caffeine',
            'quantity': 2,
            'unit_price': 1500.0,
            'subtotal': 3000.0,
          }
        ],
        'created_at': '2026-09-18T22:30:00Z',
      };

      final res = ReservationModel.fromJson(jsonMap);

      expect(res.id, 77);
      expect(res.reservationCode, 'RES-998877');
      expect(res.status, 'pending');
      expect(res.totalAmount, 3000.0);
      expect(res.items.length, 1);
      expect(res.items.first.quantity, 2);
    });

    test('ApiService fallback search returns filtered results', () async {
      final api = ApiService();
      final allItems = await api.searchMedicines();
      expect(allItems.isNotEmpty, true);

      final augItems = await api.searchMedicines(query: 'Augmentin');
      expect(augItems.any((i) => i.medicine.tradeName.contains('Augmentin')), true);
    });

    test('ApiService login fails with invalid credentials and does not authenticate', () async {
      final api = ApiService();
      final result = await api.login('nonexistent@example.com', 'wrongpassword');
      expect(result.success, false);
      expect(api.isAuthenticated, false);
      expect(result.errorMessage, isNotNull);
    });
  });
}
