import '../database/database_helper.dart';
import '../models/note_model.dart';
import '../utils/app_logger.dart';

/// Service for managing trip notes and journal entries
class NoteService {
  static final NoteService instance = NoteService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  NoteService._init();

  /// Add a new note to a trip
  Future<NoteModel> addNote({
    required int tripId,
    required String title,
    required String content,
  }) async {
    try {
      final note = NoteModel(
        tripId: tripId,
        title: title,
        content: content,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await _dbHelper.insertNote(note.toMap());
      AppLogger.info('Added note: $title');

      return note.copyWith(id: id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add note', e, stackTrace);
      rethrow;
    }
  }

  /// Get all notes for a trip
  Future<List<NoteModel>> getNotesForTrip(int tripId) async {
    try {
      final maps = await _dbHelper.getNotesByTripId(tripId);
      return maps.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get notes for trip $tripId', e, stackTrace);
      rethrow;
    }
  }

  /// Get note by ID
  Future<NoteModel?> getNoteById(int id) async {
    try {
      final map = await _dbHelper.getNoteById(id);
      if (map == null) return null;
      return NoteModel.fromMap(map);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get note $id', e, stackTrace);
      rethrow;
    }
  }

  /// Update a note
  Future<void> updateNote(NoteModel note) async {
    if (note.id == null) {
      throw Exception('Cannot update note without ID');
    }

    try {
      await _dbHelper.updateNote(note.id!, note.toMap());
      AppLogger.info('Updated note ID: ${note.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update note', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(int id) async {
    try {
      await _dbHelper.deleteNote(id);
      AppLogger.info('Deleted note ID: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete note', e, stackTrace);
      rethrow;
    }
  }

  /// Get count of notes for a trip
  Future<int> getNoteCount(int tripId) async {
    try {
      final notes = await getNotesForTrip(tripId);
      return notes.length;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get note count', e, stackTrace);
      rethrow;
    }
  }
}
