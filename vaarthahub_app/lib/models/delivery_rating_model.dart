class DeliveryRatingModel {
  final int deliveryPartnerId;
  final int readerId;
  final int ratingValue;
  final List<String> feedbackTags;
  final String? comments;

  DeliveryRatingModel({
    required this.deliveryPartnerId,
    required this.readerId,
    required this.ratingValue,
    required this.feedbackTags,
    this.comments,
  });

  // Convert the model to a JSON map for API submission
  Map<String, dynamic> toJson() {
    return {
      'deliveryPartnerId': deliveryPartnerId,
      'readerId': readerId,
      'ratingValue': ratingValue,
      'feedbackTags': feedbackTags, // This will be sent as a list of strings
      'comments': comments,
    };
  } 

  // Factory constructor to create a DeliveryRatingModel from a JSON map
  factory DeliveryRatingModel.fromJson(Map<String, dynamic> map) {
    return DeliveryRatingModel(
      deliveryPartnerId: map['deliveryPartnerId']?.toInt() ?? 0,
      readerId: map['readerId']?.toInt() ?? 0,
      ratingValue: map['ratingValue']?.toInt() ?? 0,
      feedbackTags: List<String>.from(map['feedbackTags'] ?? []),
      comments: map['comments'],
    );
  }
}