import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String? getStatus(String? status, AppLocalizations localizations) {
  switch (status) {
    case 'Đang duyệt':
      return localizations.pending;
    case 'Được thông qua':
      return localizations.accepted;
    case 'Không được thông qua':
      return localizations.rejected;
    case 'Đang diễn ra':
      return localizations.inProgress;
    case 'Quá hạn':
      return localizations.expired;
    case 'Chưa bắt đầu':
      return localizations.notStarted;
    default:
      return null;
  }
}

String? getTaskStatus(String? status, AppLocalizations localizations) {
  switch (status) {
    case 'Bản nháp':
      return localizations.draft;
    case 'Đang chờ':
      return localizations.pendingTask;
    case 'Việc cần làm':
      return localizations.toDo;
    case 'Đang thực hiện':
      return localizations.inProgress;
    case 'Xem xét':
      return localizations.review;
    case 'Đã hoàn thành':
      return localizations.done;
    default:
      return null;
  }
}
