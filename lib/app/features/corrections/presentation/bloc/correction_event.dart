// lib/app/features/corrections/presentation/bloc/correction_event.dart

import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

abstract class CorrectionEvent extends Equatable {
  const CorrectionEvent();
  @override
  List<Object?> get props => [];
}

/// تحميل طلبات التصحيح المعلقة (للمشرف/الإمام)
class LoadPendingCorrections extends CorrectionEvent {
  final String mosqueId;
  const LoadPendingCorrections(this.mosqueId);
  @override
  List<Object?> get props => [mosqueId];
}

/// تحميل طلباتي (لولي الأمر)
class LoadMyCorrections extends CorrectionEvent {
  const LoadMyCorrections();
}

/// إنشاء طلب تصحيح (لولي الأمر)
class CreateCorrectionRequest extends CorrectionEvent {
  final String childId;
  final String mosqueId;
  final Prayer prayer;
  final DateTime prayerDate;
  final String? note;

  const CreateCorrectionRequest({
    required this.childId,
    required this.mosqueId,
    required this.prayer,
    required this.prayerDate,
    this.note,
  });

  @override
  List<Object?> get props => [childId, mosqueId, prayer, prayerDate, note];
}

/// موافقة على طلب (للمشرف/الإمام)
class ApproveCorrection extends CorrectionEvent {
  final String requestId;
  const ApproveCorrection(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

/// رفض طلب (للمشرف/الإمام)
class RejectCorrection extends CorrectionEvent {
  final String requestId;
  final String? reason;
  const RejectCorrection(this.requestId, {this.reason});
  @override
  List<Object?> get props => [requestId, reason];
}
