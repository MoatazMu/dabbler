class LocalizedError {
  final String code;
  final String message;
  final String locale;
  final String? details;

  const LocalizedError({
    required this.code,
    required this.message,
    required this.locale,
    this.details,
  });

  factory LocalizedError.fromJson(Map<String, dynamic> json) {
    return LocalizedError(
      code: json['code']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? 'Unknown error',
      locale: json['locale']?.toString() ?? 'en',
      details: json['details']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'locale': locale,
        if (details != null) 'details': details,
      };
}
