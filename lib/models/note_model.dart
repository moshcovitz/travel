class NoteModel {
  final int? id;
  final int tripId;
  final String title;
  final String content;
  final int timestamp;

  NoteModel({
    this.id,
    required this.tripId,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  NoteModel copyWith({
    int? id,
    int? tripId,
    String? title,
    String? content,
    int? timestamp,
  }) {
    return NoteModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
