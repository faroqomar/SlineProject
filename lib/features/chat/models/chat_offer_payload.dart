/// Canonical offer payload for chat. Wire format uses `days` (backend validates).
/// Read path supports legacy `delivery` for display during compatibility window.
class ChatOfferPayload {
  const ChatOfferPayload({
    required this.price,
    required this.days,
    this.title,
    this.description,
    this.status = 'pending',
  });

  final int price;
  final int days;
  final String? title;
  final String? description;
  final String status;

  /// Wire map: uses `days` only (no `delivery`). Backend requires price + days.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'price': price,
      'days': days,
      'status': status,
    };
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    return map;
  }

  /// Read: prefers `days`, falls back to `delivery` for legacy payloads.
  static int daysFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return 0;
    final d = payload['days'];
    if (d != null) return (d is int) ? d : int.tryParse(d.toString()) ?? 0;
    final leg = payload['delivery'];
    if (leg != null)
      return (leg is int) ? leg : int.tryParse(leg.toString()) ?? 0;
    return 0;
  }

  /// Build from JSON (e.g. message payload). Reads `days` or legacy `delivery`.
  factory ChatOfferPayload.fromJson(Map<String, dynamic> json) {
    return ChatOfferPayload(
      price: (json['price'] is int)
          ? json['price'] as int
          : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      days: daysFromPayload(json),
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
