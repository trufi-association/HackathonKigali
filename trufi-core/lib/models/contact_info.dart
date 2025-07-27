class ContactInfo {
  final String? phoneNumber;
  final String? infoUrl;
  final String? bookingUrl;

  const ContactInfo({this.phoneNumber, this.infoUrl, this.bookingUrl});

  static const String _phoneNumber = 'phoneNumber';
  static const String _infoUrl = 'infoUrl';
  static const String _bookingUrl = 'bookingUrl';

  factory ContactInfo.fromJson(Map<String, dynamic> map) => ContactInfo(
    phoneNumber: map[_phoneNumber],
    infoUrl: map[_infoUrl],
    bookingUrl: map[_bookingUrl],
  );

  Map<String, dynamic> toJson() => {
    _phoneNumber: phoneNumber,
    _infoUrl: infoUrl,
    _bookingUrl: bookingUrl,
  };
}
