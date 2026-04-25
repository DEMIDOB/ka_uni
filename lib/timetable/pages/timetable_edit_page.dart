import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_types/module_info_table_sensible.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/timetable/models/timetable_appointment.dart';
import 'package:kit_mobile/timetable/models/timetable_daily.dart';
import 'package:kit_mobile/timetable/models/timetable_weekly.dart';
import 'package:kit_mobile/timetable/views/timetable_weekly_view.dart';
import 'package:kit_mobile/tutorials/data/tutorial_manager.dart';
import 'package:kit_mobile/tutorials/models/tutorial.dart';
import 'package:kit_mobile/utils/string_prettifiers.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

class TimetableEditPage extends StatefulWidget {
  const TimetableEditPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TimetableEditPageState();
  }
}

class _TimetableEditPageState extends State<TimetableEditPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<TutorialManager>()
          .ensureSemesterLoaded(KITProvider.currentSemesterString);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KITProvider>();
    final tutorialManager = context.watch<TutorialManager>();
    final semester = KITProvider.currentSemesterString;
    final tutorials = tutorialManager
        .tutorialsForSemester(semester)
        .map(
          (tutorial) => _withModuleTitle(
            tutorial,
            vm.campusManager.rowModules.values,
          ),
        )
        .toList(growable: false);

    final modulesById =
        _modulesById(vm.campusManager.rowModules.values);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stundenplan anpassen"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Tutorien",
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Verknüpfe Tutorien mit deinen Modulen und lege deren Zeitfenster fest. "
                    "Die Zeiten entsprechen den regulären Campus-Blöcken.",
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  if (!tutorialManager.isSemesterLoaded(semester))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (tutorials.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Noch keine Tutorien gespeichert. "
                        "Nutze den Plus-Button, um das erste Tutorium zu erstellen.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tutorials.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) => _TutorialListTile(
                        tutorial: tutorials[index],
                        modulesById: modulesById,
                        onEdit: () => _openTutorialDialog(
                          context,
                          modulesById: modulesById,
                          existing: tutorials[index],
                        ),
                        onDelete: () => _confirmRemoveTutorial(
                          context,
                          tutorial: tutorials[index],
                        ),
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.add),
                          onPressed: modulesById.isEmpty
                              ? () => _showNoModulesDialog(context)
                              : () => _openTutorialDialog(context,
                                  modulesById: modulesById)),
                    ],
                  ),

                  SizedBox(height: 24,),

                  Row(
                    children: [
                      Text(
                        "Vorlesungen und Übungen",
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Füge Termine zum Stundenplan hizu, indem du auf das Stern-Icon klickst.",
                    style: theme.textTheme.bodyMedium,
                  ),

                  Column(
                    children: vm.campusManager.moduleInfoTablesWithAppointments.keys.map((rowId) {
                      final tables = vm.campusManager.moduleInfoTablesWithAppointments[rowId]!;
                      if (tables.isEmpty) {
                        return Row(children: [],);
                      }

                      return Column(
                        children: [
                          SizedBox(height: 32,),

                          Text(sanitizeModuleTitle(tables.first.parentModule.title), style: theme.textTheme.titleLarge, textAlign: TextAlign.center,),

                          SizedBox(height: 8,),

                          BlockContainer(
                            child: Column(
                              children: tables.map((table) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: ModuleInfoTableSensible(table: table),
                                );
                              }
                              ).toList(),
                            ),
                          )
                        ],
                      );
                    }).toList(),
                  ),

                  // const SizedBox(height: 24),
                  // Text(
                  //   "Aktueller Stundenplan (Vorschau)",
                  //   style: theme.textTheme.titleLarge,
                  // ),
                  // const SizedBox(height: 12),
                ],
              ),
            ),
            TimetableWeeklyView(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Map<String, KITModule> _modulesById(Iterable<KITModule> modules) {
    final result = <String, KITModule>{};
    for (final module in modules) {
      if (module.id.isEmpty) continue;
      result[module.id] = module;
    }
    return result;
  }

  Tutorial _withModuleTitle(
    Tutorial tutorial,
    Iterable<KITModule> modules,
  ) {
    for (final module in modules) {
      if (module.id == tutorial.moduleId &&
          module.title.trim().isNotEmpty &&
          module.title.trim() != tutorial.moduleTitle) {
        return tutorial.copyWith(moduleTitle: module.title.trim());
      }
    }
    return tutorial;
  }

  Future<void> _openTutorialDialog(
    BuildContext context, {
    required Map<String, KITModule> modulesById,
    Tutorial? existing,
  }) async {
    final theme = Theme.of(context);
    final moduleList = modulesById.values
        .where((module) => module.id.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.title.compareTo(b.title));

    if (moduleList.isEmpty) {
      await _showNoModulesDialog(context);
      return;
    }

    String selectedModuleId = existing?.moduleId ?? moduleList.first.id;
    Weekday selectedWeekday = existing?.weekday ?? Weekday.monday;
    int selectedBlockIndex = existing?.blockIndex ?? _defaultBlockIndex;
    final TextEditingController notesController = TextEditingController(
      text: existing?.notes ?? "",
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: theme.scaffoldBackgroundColor.withAlpha(100),
      builder: (dialogContext) {
        // final theme = Theme.of(dialogContext);
        return LayoutBuilder(
          builder: (context, constraints) {
            final mediaWidth = MediaQuery.of(dialogContext).size.width;
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : mediaWidth;
            final double dialogWidth =
                availableWidth > 520 ? 520 : availableWidth * 0.92;

            return Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return GlassContainer(
                        shape: LiquidRoundedSuperellipse(
                            borderRadius: appBorderRadiusDouble),
                        // settings: LiquidGlassSettings(
                        //   glassColor: Colors.white.withOpacity(0.7),
                        //   blur: 4,
                        //   // blend: 1
                        // ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: dialogWidth,
                            maxHeight:
                                MediaQuery.of(dialogContext).size.height * 0.85,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              child: Card(
                                color: Colors.white.withAlpha(0),
                                shadowColor: Colors.grey.withAlpha(0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      existing == null
                                          ? "Tutorium hinzufügen"
                                          : "Tutorium bearbeiten",
                                      style: theme.textTheme.titleLarge,
                                    ),

                                    const SizedBox(height: 16),

                                    DropdownButtonFormField<String>(
                                      value: selectedModuleId,
                                      decoration: const InputDecoration(
                                          labelText: "Modul auswählen"),
                                      items: moduleList
                                          .map(
                                            (module) => DropdownMenuItem(
                                              value: module.id,
                                              child: Text(module.title),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(
                                            () => selectedModuleId = value);
                                      },
                                    ),

                                    const SizedBox(height: 12),

                                    DropdownButtonFormField<Weekday>(
                                      value: selectedWeekday,
                                      decoration: const InputDecoration(
                                          labelText: "Wochentag"),
                                      items: workingWeekdays
                                          .map(
                                            (weekday) => DropdownMenuItem(
                                              value: weekday,
                                              child:
                                                  Text(_weekdayLabel(weekday)),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() => selectedWeekday = value);
                                      },
                                    ),

                                    const SizedBox(height: 12),

                                    DropdownButtonFormField<int>(
                                      value: selectedBlockIndex,
                                      decoration: const InputDecoration(
                                          labelText: "Zeitblock"),
                                      items: _blockOptions
                                          .map(
                                            (option) => DropdownMenuItem(
                                              value: option.index,
                                              child: Text(option.label),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(
                                            () => selectedBlockIndex = value);
                                      },
                                    ),

                                    // const SizedBox(height: 12),
                                    //
                                    // TextField(
                                    //   controller: notesController,
                                    //   decoration: const InputDecoration(
                                    //     labelText: "Notizen (optional)",
                                    //     hintText:
                                    //         "z.B. Raum, Ansprechpartner, Hinweise",
                                    //   ),
                                    //   maxLines: 3,
                                    // ),

                                    const SizedBox(height: 24),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        CupertinoButton(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          onPressed: () =>
                                              Navigator.of(dialogContext).pop(),
                                          child: const Text("Abbrechen"),
                                        ),
                                        const SizedBox(width: 12),
                                        CupertinoButton.filled(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          onPressed: () async {
                                            final module =
                                                modulesById[selectedModuleId];
                                            if (module == null) {
                                              return;
                                            }

                                            final tutorial = existing != null
                                                ? existing.copyWith(
                                                    moduleId: module.id,
                                                    moduleTitle: module.title
                                                            .trim()
                                                            .isEmpty
                                                        ? module.title
                                                        : module.title.trim(),
                                                    weekday: selectedWeekday,
                                                    blockIndex:
                                                        selectedBlockIndex,
                                                    notes: notesController.text
                                                            .trim()
                                                            .isEmpty
                                                        ? null
                                                        : notesController.text
                                                            .trim(),
                                                  )
                                                : Tutorial.createNew(
                                                    moduleId: module.id,
                                                    moduleTitle: module.title
                                                            .trim()
                                                            .isEmpty
                                                        ? module.title
                                                        : module.title.trim(),
                                                    weekday: selectedWeekday,
                                                    blockIndex:
                                                        selectedBlockIndex,
                                                    semesterString: KITProvider
                                                        .currentSemesterString,
                                                    notes: notesController.text
                                                            .trim()
                                                            .isEmpty
                                                        ? null
                                                        : notesController.text
                                                            .trim(),
                                                  );

                                            await context
                                                .read<TutorialManager>()
                                                .addOrUpdateTutorial(tutorial);
                                            if (mounted) {
                                              Navigator.of(dialogContext).pop();
                                            }
                                          },
                                          child: const Text("Speichern"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRemoveTutorial(
    BuildContext context, {
    required Tutorial tutorial,
  }) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text("Tutorium löschen"),
        content: Text(
          "Möchtest du das Tutorium für \"${tutorial.moduleTitle}\" wirklich entfernen?",
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Abbrechen"),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            isDestructiveAction: true,
            child: const Text("Löschen"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await context.read<TutorialManager>().removeTutorial(
          semesterString: tutorial.semesterString,
          tutorialId: tutorial.tutorialId,
        );
  }

  Future<void> _showNoModulesDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return LayoutBuilder(
          builder: (context, constraints) {
            final mediaWidth = MediaQuery.of(dialogContext).size.width;
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : mediaWidth;
            final double dialogWidth =
                availableWidth > 420 ? 420 : availableWidth * 0.9;

            return Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: GlassContainer(
                    // shape: LiquidRoundedSuperellipse(
                    //     borderRadius: appBorderRadiusDouble),
                    // // settings: GlassContainerSettings(
                    // //   glassColor: theme.colorScheme.surface.withOpacity(0.75),
                    // // ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: dialogWidth),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Keine Module verfügbar",
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Aktuell sind noch keine Module im Cache. "
                              "Öffne ein Modul in der App, damit es für die Tutorien verwendet "
                              "werden kann.",
                            ),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text("Verstanden"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _weekdayLabel(Weekday weekday) {
    switch (weekday) {
      case Weekday.monday:
        return "Montag";
      case Weekday.tuesday:
        return "Dienstag";
      case Weekday.wednesday:
        return "Mittwoch";
      case Weekday.thursday:
        return "Donnerstag";
      case Weekday.friday:
        return "Freitag";
      case Weekday.saturday:
        return "Samstag";
      case Weekday.sunday:
        return "Sonntag";
    }
  }

  static final List<_BlockOption> _blockOptions =
      TimetableDaily.genericAppointmentsSchedule
          .asMap()
          .entries
          .where(
            (entry) => entry.value.type != TimetableAppointmentType.lunchBreak,
          )
          .map(
            (entry) => _BlockOption(
              index: entry.key,
              label:
                  "${entry.value.begin.hour.toString().padLeft(2, "0")}:${entry.value.begin.minute.toString().padLeft(2, "0")} - "
                  "${entry.value.end.hour.toString().padLeft(2, "0")}:${entry.value.end.minute.toString().padLeft(2, "0")}",
            ),
          )
          .toList(growable: false);

  static int get _defaultBlockIndex =>
      _blockOptions.isNotEmpty ? _blockOptions.first.index : 0;
}

class _BlockOption {
  final int index;
  final String label;

  const _BlockOption({required this.index, required this.label});
}

class _TutorialListTile extends StatelessWidget {
  final Tutorial tutorial;
  final Map<String, KITModule> modulesById;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TutorialListTile({
    required this.tutorial,
    required this.modulesById,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final module = modulesById[tutorial.moduleId];
    final title = module?.title ?? tutorial.moduleTitle;
    final blockLabel = _TimetableEditPageState._blockOptions
        .firstWhere(
          (option) => option.index == tutorial.blockIndex,
          orElse: () => _BlockOption(index: tutorial.blockIndex, label: ""),
        )
        .label;

    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        "${_TimetableEditPageState._weekdayLabel(tutorial.weekday)} · $blockLabel",
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: onEdit,
            child: const Icon(CupertinoIcons.pencil),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: onDelete,
            child: Icon(CupertinoIcons.trash, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
