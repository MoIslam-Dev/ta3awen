import '../models/request_post.dart';
import 'constants.dart';

/// Result of moving the create-form kind switch to [nextKind].
typedef RequestKindSwitchState =
    ({String kind, String type, String? category, String? bloodType});

/// Pure state transition behind the general/blood switcher on the request
/// create form (extracted so it is unit-testable).
///
/// Blood posts are always type `need`, always use the fixed blood category
/// and ask for a blood type. Leaving blood resets to a general category when
/// the previous one was the blood category; the user's chosen type survives.
RequestKindSwitchState applyRequestKindSwitch(
  String nextKind, {
  required String previousType,
  required String? previousCategory,
}) {
  if (nextKind == requestKindBlood) {
    return (
      kind: requestKindBlood,
      type: requestTypeNeed,
      category: kBloodCategory,
      bloodType: null,
    );
  }
  return (
    kind: requestKindGeneral,
    type: previousType,
    category:
        previousCategory == kBloodCategory ? kCategories.first : previousCategory,
    bloodType: null,
  );
}