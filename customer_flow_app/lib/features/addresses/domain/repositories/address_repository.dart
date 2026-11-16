import '../entities/address_draft.dart';
import '../entities/customer_address.dart';

abstract interface class AddressRepository {
  Future<List<CustomerAddress>> getAddresses();

  Future<CustomerAddress> createAddress(AddressDraft draft);

  Future<CustomerAddress> updateAddress(String id, AddressDraft draft);

  Future<void> setDefaultAddress(String id);

  Future<void> deleteAddress(String id);
}
