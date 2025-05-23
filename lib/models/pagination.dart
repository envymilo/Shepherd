class Pagination {
  final int totalCount;
  final int totalPage;
  final int pageNumber;
  final int pageSize;
  final int skip;

  Pagination({
    required this.totalCount,
    required this.totalPage,
    required this.pageNumber,
    required this.pageSize,
    required this.skip,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalCount: json['totalCount'],
      totalPage: json['totalPage'],
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
      skip: json['skip'],
    );
  }
}
