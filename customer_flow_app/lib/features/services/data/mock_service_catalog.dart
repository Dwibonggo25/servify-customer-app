import 'package:flutter/material.dart';

import '../domain/entities/service_item.dart';

abstract final class MockServiceCatalog {
  static const services = <ServiceItem>[
    ServiceItem(
      id: 'home-cleaning',
      name: 'Kebersihan Rumah',
      shortDescription: 'Rumah bersih dan nyaman tanpa repot.',
      description:
          'Layanan kebersihan menyeluruh yang dikerjakan oleh tenaga '
          'profesional dan terverifikasi. Cocok untuk rumah, apartemen, '
          'maupun kos.',
      category: 'Kebersihan',
      price: 125000,
      durationMinutes: 120,
      rating: 4.9,
      reviewCount: 328,
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF4F46E5),
      includes: [
        'Membersihkan lantai dan permukaan',
        'Membersihkan kamar mandi',
        'Membersihkan area dapur',
        'Peralatan kebersihan dasar',
      ],
    ),
    ServiceItem(
      id: 'home-repair',
      name: 'Perbaikan Rumah',
      shortDescription: 'Teknisi berpengalaman datang ke lokasi.',
      description:
          'Bantuan teknisi untuk menangani berbagai kerusakan ringan di '
          'rumah. Biaya tambahan material akan dikonfirmasi terlebih dahulu.',
      category: 'Perbaikan',
      price: 150000,
      durationMinutes: 90,
      rating: 4.8,
      reviewCount: 214,
      icon: Icons.handyman_rounded,
      color: Color(0xFFF97316),
      includes: [
        'Pemeriksaan awal oleh teknisi',
        'Perbaikan ringan hingga 90 menit',
        'Rekomendasi material yang dibutuhkan',
        'Garansi layanan selama 7 hari',
      ],
    ),
    ServiceItem(
      id: 'laundry',
      name: 'Laundry',
      shortDescription: 'Jemput, cuci, dan antar kembali.',
      description:
          'Laundry pakaian harian dengan proses higienis. Kurir menjemput '
          'pakaian dan mengantarkannya kembali setelah selesai.',
      category: 'Laundry',
      price: 75000,
      durationMinutes: 2880,
      rating: 4.7,
      reviewCount: 176,
      icon: Icons.local_laundry_service_rounded,
      color: Color(0xFF0EA5E9),
      includes: [
        'Penjemputan di lokasi customer',
        'Cuci dan pengeringan',
        'Setrika dan lipat',
        'Pengantaran kembali',
      ],
    ),
    ServiceItem(
      id: 'routine-care',
      name: 'Perawatan Rutin',
      shortDescription: 'Layanan berkala agar rumah selalu terawat.',
      description:
          'Pemeriksaan dan perawatan rutin untuk menjaga fasilitas rumah '
          'tetap dalam kondisi baik dan mencegah kerusakan lebih besar.',
      category: 'Perawatan',
      price: 200000,
      durationMinutes: 120,
      rating: 4.9,
      reviewCount: 143,
      icon: Icons.home_repair_service_rounded,
      color: Color(0xFF14B8A6),
      includes: [
        'Pemeriksaan fasilitas rumah',
        'Perawatan ringan',
        'Laporan hasil pemeriksaan',
        'Rekomendasi tindak lanjut',
      ],
    ),
    ServiceItem(
      id: 'ac-service',
      name: 'Service AC',
      shortDescription: 'AC lebih dingin dan hemat listrik.',
      description:
          'Pembersihan unit AC oleh teknisi berpengalaman untuk menjaga '
          'performa pendinginan dan kualitas udara di rumah.',
      category: 'Perawatan',
      price: 100000,
      durationMinutes: 60,
      rating: 4.8,
      reviewCount: 267,
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF0284C7),
      includes: [
        'Pembersihan filter dan evaporator',
        'Pemeriksaan tekanan dasar',
        'Pembersihan area kerja',
        'Rekomendasi kondisi unit',
      ],
    ),
    ServiceItem(
      id: 'pest-control',
      name: 'Pest Control',
      shortDescription: 'Perlindungan rumah dari hama.',
      description:
          'Penanganan hama rumah dengan metode aman dan terukur oleh petugas '
          'yang sudah terlatih.',
      category: 'Kebersihan',
      price: 250000,
      durationMinutes: 120,
      rating: 4.7,
      reviewCount: 98,
      icon: Icons.pest_control_rounded,
      color: Color(0xFF65A30D),
      includes: [
        'Survei area terdampak',
        'Penanganan hama',
        'Pembersihan area kerja',
        'Garansi kunjungan ulang 14 hari',
      ],
    ),
  ];

  static ServiceItem? findById(String id) {
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }
}
