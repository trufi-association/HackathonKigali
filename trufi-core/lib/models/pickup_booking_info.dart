import 'contact_info.dart';

class PickupBookingInfo {
  final String? message;
  final ContactInfo? contactInfo;

  const PickupBookingInfo({this.message, this.contactInfo});

  static const String _message = 'message';
  static const String _contactInfo = 'contactInfo';

  factory PickupBookingInfo.fromJson(Map<String, dynamic> map) =>
      PickupBookingInfo(
        message: map[_message],
        contactInfo:
            map[_contactInfo] != null
                ? ContactInfo.fromJson(
                  map[_contactInfo] as Map<String, dynamic>,
                )
                : null,
      );

  Map<String, dynamic> toJson() => {
    _message: message,
    _contactInfo: contactInfo?.toJson(),
  };
}
