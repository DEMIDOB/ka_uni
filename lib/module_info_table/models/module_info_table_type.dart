enum ModuleInfoTableType {
  common,
  exam,
  milestones,
  appointments;

  bool get isSensible => this != ModuleInfoTableType.common;

  static ModuleInfoTableType fromCaption(String caption) {
    final lowerCaseCaption = caption.toLowerCase();

    if (lowerCaseCaption.contains("prüfung")) {
      return ModuleInfoTableType.exam;
    }

    if (lowerCaseCaption.contains("teilleistungen")) {
      return ModuleInfoTableType.milestones;
    }

    if (lowerCaseCaption.contains("veranstaltungen")) {
      return ModuleInfoTableType.appointments;
    }

    return common;
  }
}