enum ProcessStatus { queued, running, completed, failed }
enum ProcessType { copy, move, delete, compress, extract }

class ProcessItem {
  final String id;
  final String title;
  final ProcessType type;
  final ProcessStatus status;
  final double progress; // 0.0 to 1.0
  final int totalBytes;
  final int processedBytes;
  final String? errorMessage;

  const ProcessItem({
    required this.id,
    required this.title,
    required this.type,
    this.status = ProcessStatus.queued,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.processedBytes = 0,
    this.errorMessage,
  });

  ProcessItem copyWith({
    ProcessStatus? status,
    double? progress,
    int? totalBytes,
    int? processedBytes,
    String? errorMessage,
  }) {
    return ProcessItem(
      id: id,
      title: title,
      type: type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      processedBytes: processedBytes ?? this.processedBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
