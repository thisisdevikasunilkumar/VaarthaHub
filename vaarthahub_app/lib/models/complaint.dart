class Complaint {
  final String readerCode;
  final String complaintType;
  final String comments;

  Complaint({
    required this.readerCode,
    required this.complaintType,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'readerCode': readerCode,
      'complaintType': complaintType,
      'comments': comments,
    };
  }
}
