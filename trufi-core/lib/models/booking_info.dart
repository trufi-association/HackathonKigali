import 'contact_info.dart';

class BookingInfo {
  final String? message;
  final String? dropOffMessage;
  final ContactInfo? contactInfo;

  const BookingInfo({this.message, this.dropOffMessage, this.contactInfo});

  static const String _message = 'message';
  static const String _dropOffMessage = 'dropOffMessage';
  static const String _contactInfo = 'contactInfo';

  factory BookingInfo.fromJson(Map<String, dynamic> map) => BookingInfo(
    message: map[_message],
    dropOffMessage: map[_dropOffMessage],
    contactInfo:
        map[_contactInfo] != null
            ? ContactInfo.fromJson(map[_contactInfo] as Map<String, dynamic>)
            : null,
  );

  Map<String, dynamic> toJson() => {
    _message: message,
    _dropOffMessage: dropOffMessage,
    _contactInfo: contactInfo?.toJson(),
  };
}
