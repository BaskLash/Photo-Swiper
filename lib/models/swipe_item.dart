import 'package:photo_manager/photo_manager.dart';

enum SwipeDecision { pending, keep, delete, later }

class SwipeItem {
  final AssetEntity asset;
  SwipeDecision decision;
  int? fileSizeBytes;
  bool isSelectedForDeletion;

  SwipeItem({required this.asset})
      : decision = SwipeDecision.pending,
        isSelectedForDeletion = true;

  String get fileSizeDisplay {
    if (fileSizeBytes == null) return '';
    final bytes = fileSizeBytes!;
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String get formattedDate {
    final d = asset.createDateTime;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m';
  }
}
