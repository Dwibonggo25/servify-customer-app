abstract interface class StaffBookingRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchBookings();

  Stream<List<Map<String, dynamic>>> watchBookings();

  Future<Map<String, dynamic>?> fetchBooking(String id);

  Future<List<Map<String, dynamic>>> fetchBookingHistory(String id);

  Future<void> respondToBooking(String id, {required bool accept});

  Future<void> updateProgress(String id, String status);
}
