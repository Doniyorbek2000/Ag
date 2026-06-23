import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'action_executor.dart';

class ContactManagerService {
  /// Add a new contact to the phone
  Future<ActionResult> addContact({
    required String name,
    String? phone,
    String? email,
    String? company,
  }) async {
    final status = await Permission.contacts.request();
    if (status.isDenied) {
      return const ActionResult(success: false, message: 'Kontaktlar ruxsati berilmagan');
    }

    final contact = Contact(
      givenName: name,
      phones: phone != null ? [Item(label: 'mobile', value: phone)] : null,
      emails: email != null ? [Item(label: 'work', value: email)] : null,
      company: company,
    );

    try {
      await ContactsService.addContact(contact);
      return ActionResult(
        success: true,
        message: '📞 Kontakt qo\'shildi: $name${phone != null ? ' ($phone)' : ''}',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kontakt qo\'shishda xato: $e');
    }
  }

  /// List recent contacts (for quick access)
  Future<ActionResult> listContacts({int limit = 10, String? query}) async {
    final status = await Permission.contacts.request();
    if (status.isDenied) {
      return const ActionResult(success: false, message: 'Kontaktlar ruxsati berilmagan');
    }

    try {
      final contacts = query != null
          ? await ContactsService.getContacts(query: query, withThumbnails: false)
          : await ContactsService.getContacts(withThumbnails: false);

      final list = contacts.take(limit).map((c) {
        final phone = c.phones?.isNotEmpty == true ? c.phones!.first.value ?? '' : 'raqam yo\'q';
        return '📱 ${c.displayName ?? "Nomsiz"}: $phone';
      }).toList();

      if (list.isEmpty) {
        return ActionResult(
          success: true,
          message: query != null ? '"$query" bo\'yicha kontakt topilmadi' : 'Kontaktlar bo\'sh',
        );
      }

      return ActionResult(
        success: true,
        message: 'Kontaktlar (${list.length} ta):\n${list.join('\n')}',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kontaktlarni o\'qishda xato: $e');
    }
  }

  /// Get total contact count
  Future<ActionResult> getContactCount() async {
    final status = await Permission.contacts.request();
    if (status.isDenied) {
      return const ActionResult(success: false, message: 'Kontaktlar ruxsati berilmagan');
    }

    try {
      final contacts = await ContactsService.getContacts(withThumbnails: false);
      return ActionResult(
        success: true,
        message: '📱 Telefonda ${contacts.length} ta kontakt bor',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kontaktlarni o\'qishda xato');
    }
  }

  /// Delete a contact by name
  Future<ActionResult> deleteContact(String name) async {
    final status = await Permission.contacts.request();
    if (status.isDenied) {
      return const ActionResult(success: false, message: 'Kontaktlar ruxsati berilmagan');
    }

    try {
      final contacts = await ContactsService.getContacts(query: name, withThumbnails: false);
      if (contacts.isEmpty) {
        return ActionResult(success: false, message: '"$name" nomli kontakt topilmadi');
      }
      await ContactsService.deleteContact(contacts.first);
      return ActionResult(success: true, message: '🗑️ "$name" kontakti o\'chirildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Kontaktni o\'chirishda xato: $e');
    }
  }
}
