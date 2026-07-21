class ReportMapperService {
  const ReportMapperService._();

  static List<Map<String, dynamic>> mapList<T>(
    Iterable<T> items,
    Map<String, dynamic> Function(T item) mapper,
  ) {
    return items.map(mapper).toList();
  }

  static Map<String, dynamic> emptyMap() {
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> emptyList() {
    return <Map<String, dynamic>>[];
  }
}
