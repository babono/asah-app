// Demo walkthrough of the phone app against the demo backend (asah-be
// seed_demo.sql), one recorded scene per use case. Each scene builds on the
// one before (the mentor fixes an issue, then the manager accepts it), so run
// them in order on a freshly seeded project:
//
//   (asah-be) npm run demo:reset
//   python3 tool/record_demo.py              # records every scene to build/demo/*.mp4
//
// The test prints DEMO_REC_START <scene> / DEMO_REC_STOP <scene>; the recorder
// script starts and stops `simctl io recordVideo` on those lines. It also runs
// on its own (no videos): flutter test integration_test/demo_test.dart -d <id>
//   --dart-define-from-file=config/development.json
// DEMO_OTP in that file is the fixed code of the Supabase test numbers.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:asah/app/asah_app.dart';
import 'package:asah/core/media/camera.dart';
import 'package:asah/features/notifications/notifications_screen.dart';
import 'package:asah/l10n/app_localizations.dart';
import 'package:asah/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const otp = String.fromEnvironment('DEMO_OTP');
const onlyScene = String.fromEnvironment('DEMO_SCENE'); // run one scene, e.g. 03
final l = lookupAppLocalizations(const Locale('en'));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('ASAH demo', timeout: Timeout.none, (t) async {
    if (otp.isEmpty) fail('Set DEMO_OTP in config/development.json (the Supabase test OTP).');
    final d = Demo(t);
    AsahApp.debugWrapper = (child) => DemoStage(child: child);
    debugCameraOverride = (photo: d.fakePhoto, video: () async => null);

    await app.main();
    await d.wait(1500);
    await d.signOutIfNeeded();
    // ignore: avoid_print
    print('DEMO_READY');
    await d.wait(3000); // the recorder grants location permission here

    final scenes = <String, Future<void> Function()>{
      '01-sign-in-and-today': () => scene01SignIn(d),
      '02-training-video-and-quiz': () => scene02Learning(d),
      '03-closing-checklist': () => scene03Checklist(d),
      '04-raise-an-issue': () => scene04RaiseIssue(d),
      '05-mentor-checkin-and-fix': () => scene05Mentor(d),
      '06-outlet-manager': () => scene06Manager(d),
      '07-area-manager-audit': () => scene07AreaManager(d),
    };
    for (final MapEntry(key: name, value: run) in scenes.entries) {
      if (onlyScene.isNotEmpty && !name.startsWith(onlyScene)) continue;
      await run();
    }
  });
}

// --------------------------------------------------------------------------
// Scenes
// --------------------------------------------------------------------------

const putu = '81100000006';
const komang = '81100000005';
const madeAyu = '81100000004';
const budi = '81100000003';

Future<void> scene01SignIn(Demo d) async {
  await d.record('01-sign-in-and-today', () async {
    await d.say('Sign in', 'Putu, a new server at Dapur Berlian Seminyak, opens ASAH. The app is in Bahasa Indonesia by default.');
    await d.tap(find.text('EN'));
    await d.say('Sign in', 'She signs in with her phone number. HQ registered it, so no password is needed.');
    await d.type(find.byType(TextField).first, putu);
    await d.tap(find.text(l.sendCode));
    await d.say('Sign in', 'A one-time code arrives by SMS (a fixed test code in this demo).');
    await d.type(find.byType(EditableText).last, otp, waitAfter: 0, dismissKeyboard: false);
    await d.waitFor(find.text(l.todaysTasks), timeoutMs: 30000);
    await d.say('Today', "Her Today screen: this shift's checklists first, with due times.");
    await d.scroll(320);
    await d.say('Today', 'Below: her Server learning path and her mentor, Komang.');
    await d.scroll(320);
    await d.wait(1500);
    await d.scroll(-700);
    await d.say('Today', 'The bell holds her notifications.');
    await d.tap(find.byType(NotificationBell).first);
    await d.wait(2500);
    await d.back();
  });
  await d.signOut();
}

Future<void> scene02Learning(Demo d) async {
  await d.signInQuietly(putu);
  await d.record('02-training-video-and-quiz', () async {
    await d.say('Asuh · Learning', 'Next on her path: "3 Seconds Rule of Eye Contact", the real HQ training video.');
    await d.tap(find.text('3 Seconds Rule of Eye Contact'));
    await d.waitFor(find.text(l.markWatched));
    await d.say('Asuh · Learning', 'She plays the video in the app. It streams over a signed, short-lived link.');
    await d.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await d.wait(9000);
    await d.tap(find.text(l.markWatched));
    await d.say('Asuh · Learning', 'Then the SOP card: the same steps, to read on shift.');
    await d.reveal(find.text(l.markAsRead));
    await d.wait(2500);
    await d.tap(find.text(l.markAsRead));
    await d.say('Asuh · Quiz', 'The quiz unlocks once the lessons are done. Pass mark 75%, 3 attempts.');
    await d.tap(find.text(l.startQuiz));
    const correct = [
      'About 3 seconds',
      'When they arrive, when they order and when they leave',
      'Make eye contact, nod and smile so they know you have seen them',
      'It shows the guest they are welcome and listened to',
    ];
    for (var i = 0; i < 4; i++) {
      await d.waitFor(find.text(l.questionOf(i + 1, 4)));
      if (i == 0) await d.say('Asuh · Quiz', 'Questions come from the shared question bank, in random order.');
      final answer = correct.firstWhere((c) => find.text(c).evaluate().isNotEmpty);
      await d.wait(1200);
      await d.tap(find.text(answer));
      await d.tap(find.text(i == 3 ? l.submitAnswers : l.nextQuestion));
    }
    await d.waitFor(find.text(l.quizPassedMessage), timeoutMs: 20000);
    await d.say('Asuh · Quiz', 'Passed. The server grades the answers, so they never reach the phone.');
    await d.tap(find.text(l.backToModule));
    await d.say('Asuh · Certificate', 'Module complete: a certificate valid for one year, with a reminder before it expires.');
    await d.scroll(-2000);
    await d.wait(2000);
    await d.back();
    await d.tapTab(l.me);
    await d.tap(find.text(l.certificates));
    await d.wait(3000);
    await d.back();
  });
  await d.signOut();
}

Future<void> scene03Checklist(Demo d) async {
  await d.signInQuietly(putu);
  await d.record('03-closing-checklist', () async {
    await d.say('Aksi · Checklist', 'Closing time. Putu opens the closing checklist from Today.');
    await d.tap(find.text(l.startChecklist));
    await d.waitFor(find.textContaining('Gas valves off'), timeoutMs: 20000);
    await d.say('Aksi · Checklist', 'Items with "Photo required" need a photo from the in-app camera. The gallery is not allowed.');
    await d.answer('Gas valves off', yes: true, photo: 'Gas valves off');
    await d.answer('Floor swept and mopped', yes: true);
    await d.say('Aksi · Checklist', 'The rubbish was not taken out. A "No" here will raise an issue for the manager.');
    await d.answer('Rubbish taken out', yes: false);
    await d.say('Aksi · Checklist', 'Cash in the drawer is counted and entered.');
    await d.answerNumber('Cash in drawer', '2450000');
    await d.answer('Doors and windows locked', yes: true, photo: 'Back door locked');
    await d.say('Aksi · Checklist', 'Submitting adds the time and location: it has to be done at the outlet.');
    await d.tap(find.text(l.submitRaisesIssues(1)));
    await d.waitFor(find.text(l.todaysTasks), timeoutMs: 30000);
    await d.say('Aksi · Checklist', 'Done. The failed item became an issue for the outlet manager, with a deadline.');
    await d.wait(2000);
  });
  await d.signOut();
}

Future<void> scene04RaiseIssue(Demo d) async {
  await d.signInQuietly(putu);
  await d.record('04-raise-an-issue', () async {
    await d.say('Standar · Issues', 'Putu spots a problem on the floor and raises an issue herself.');
    await d.tapTab(l.issues);
    await d.tap(find.text(l.raiseIssue).first);
    await d.type(find.widgetWithText(TextField, l.whatIsWrong), 'Light above table 4 is out');
    await d.type(find.widgetWithText(TextField, l.detailsOptional), 'Guests at table 4 are sitting in the dark.');
    await d.tap(find.text(l.severityMedium));
    await d.say('Standar · Issues', 'Medium: it must be fixed within 24 hours, or it escalates to the area manager.');
    await d.tap(find.text(l.addPhoto), photoLabel: 'Light above table 4');
    await d.wait(1200);
    await d.tap(find.widgetWithText(FilledButton, l.raiseIssue));
    await d.waitFor(find.text(l.progress), timeoutMs: 20000);
    await d.say('Standar · Issues', 'The issue page shows the photo, the deadline and each step until it is closed.');
    await d.scroll(400);
    await d.wait(2500);
  });
  await d.signOut();
}

Future<void> scene05Mentor(Demo d) async {
  await d.signInQuietly(komang);
  await d.record('05-mentor-checkin-and-fix', () async {
    await d.say('Asuh · Mentor', 'Komang is a captain and mentors new staff. His Mentor tab lists his trainees.');
    await d.tapTab(l.mentor);
    await d.waitFor(find.text('Putu Sari Dewi'));
    await d.wait(2000);
    await d.tap(find.text('Putu Sari Dewi'));
    await d.say('Asuh · Mentor', "Putu's progress: she just finished the eye-contact module.");
    await d.scroll(400);
    await d.wait(2000);
    await d.say('Asuh · Mentor', 'Every week the mentor logs a check-in. Putu sees it too.');
    await d.tap(find.text(l.logCheckin));
    await d.type(find.widgetWithText(TextField, l.feedback),
        'Great first week. Greets every table and holds eye contact with guests.');
    await d.type(find.widgetWithText(TextField, l.goalsNextWeek), 'Start Table setting. Shadow me at closing.');
    await d.tap(find.text(l.saveCheckin));
    await d.wait(1500);
    await d.back();
    await d.say('Standar · Issues', 'An issue was assigned to Komang: the soap dispenser in the guest toilet.');
    await d.tapTab(l.issues);
    await d.tap(find.text('Soap dispenser in the guest toilet is broken'));
    await d.wait(2000);
    await d.say('Standar · Issues', 'He fixes it, then proves it with a photo from the in-app camera.');
    await d.tap(find.text(l.markFixed), photoLabel: 'Soap dispenser fixed');
    await d.type(find.byType(TextField).last, 'Replaced the pump.', dismissKeyboard: false);
    await d.tap(find.text(l.ok));
    await d.waitFor(find.text(l.waitingForSomeoneToCheck), timeoutMs: 20000);
    await d.say('Standar · Issues', 'Now it waits for someone else to check it. Nobody can close their own fix.');
    await d.wait(2500);
  });
  await d.signOut();
}

Future<void> scene06Manager(Demo d) async {
  await d.signInQuietly(madeAyu);
  await d.record('06-outlet-manager', () async {
    await d.say('Outlet manager', "Made Ayu runs Seminyak. Her Today screen shows the outlet's day at a glance.");
    await d.wait(2000);
    await d.scroll(450);
    await d.say('Outlet manager', 'Checklists by shift, then open issues, then training: Gede is behind on Food safety.');
    await d.scroll(500);
    await d.wait(2500);
    await d.scroll(-1500);
    await d.say('Standar · Issues', 'Two fixes are waiting for her check.');
    await d.tapTab(l.issues);
    await d.tap(d.segment(l.checkFix));
    await d.tap(find.text('Soap dispenser in the guest toilet is broken'));
    await d.reveal(find.text(l.acceptFix));
    await d.say('Standar · Issues', "Komang's proof photo. She accepts the fix and the issue closes.");
    await d.scroll(300);
    await d.wait(1500);
    await d.tap(find.text(l.acceptFix));
    await d.wait(1500);
    await d.back();
    await d.tap(d.segment(l.open));
    await d.say('Standar · Issues', "Putu's new issue has no owner yet. Made Ayu assigns it.");
    await d.tap(find.text('Light above table 4 is out'));
    await d.tap(find.text(l.assignOwner));
    await d.tap(find.textContaining('Komang').last);
    await d.say('Standar · Issues', 'Komang is notified and the deadline clock is running.');
    await d.wait(2500);
    await d.back();
    await d.say('Team', 'The Team tab: everyone at the outlet, their mentor and their training.');
    await d.tapTab(l.team);
    await d.wait(1500);
    await d.tap(find.text('Gede Pramana'));
    await d.wait(3000);
    await d.back();
  });
  await d.signOut();
}

Future<void> scene07AreaManager(Demo d) async {
  await d.signInQuietly(budi);
  await d.record('07-area-manager-audit', () async {
    await d.say('Area manager', 'Budi oversees all five outlets. The last 7 days, against the 90% on-time target.');
    await d.wait(2500);
    await d.scroll(420);
    await d.say('Area manager', 'Kopi Berlian Kuta is falling behind: late checklists and escalated issues.');
    await d.reveal(find.text('Kopi Berlian Kuta'));
    await d.wait(1500);
    await d.tap(find.text('Kopi Berlian Kuta'));
    await d.say('Area manager', "He sees Kuta's day the way its manager does.");
    await d.scroll(450);
    await d.wait(2500);
    await d.back();
    // ignore: avoid_print
    print('DEMO_LOCATION -8.7180,115.1690'); // the recorder moves the simulator to Kopi Berlian Kuta
    await d.say('Standar · Audit', 'He visits Kuta and runs an audit from the phone.');
    await d.tapTab(l.audits);
    await d.tap(find.text(l.startAudit).first);
    await d.waitFor(find.text(l.auditForm));
    await d.tap(find.byType(DropdownButtonFormField<String>).first);
    await d.tap(find.text('Kopi Berlian Kuta').last);
    await d.tap(find.widgetWithText(FilledButton, l.startAudit));
    await d.waitFor(find.textContaining('Opening checklist done on time'), timeoutMs: 20000);
    await d.answer('Opening checklist done on time this week', yes: true);
    await d.answer('Kitchen floor and drains clean', yes: true, photo: 'Kitchen floor');
    await d.say('Standar · Audit', 'Two findings: a barista without an apron, and guests waiting to be greeted.');
    await d.answer('Staff in full uniform', yes: false);
    await d.answer('Food labelled with dates', yes: true, photo: 'Labelled containers');
    await d.answer('Guests greeted within 30 seconds', yes: false);
    await d.tap(find.text(l.submitRaisesIssues(2)));
    await d.waitFor(find.text(l.visitAudits), timeoutMs: 30000);
    await d.say('Standar · Audit', 'Each finding is now an issue for Kuta with a deadline. The score goes into the dashboards.');
    await d.wait(3000);
  });
  await d.signOut();
}

// --------------------------------------------------------------------------
// Driver
// --------------------------------------------------------------------------

class Demo {
  Demo(this.t);
  final WidgetTester t;
  String _photoLabel = 'Photo';

  Future<void> wait(int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await t.pump();
    }
  }

  Future<Finder> waitFor(Finder f, {int timeoutMs = 15000}) async {
    final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (f.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('Timed out waiting for $f');
      }
      await wait(100);
    }
    return f;
  }

  /// Shows a caption for long enough to read it.
  Future<void> say(String scene, String text) async {
    DemoStage.caption.value = (scene, text);
    await wait(1200 + text.length * 28);
  }

  Future<void> record(String name, Future<void> Function() body) async {
    // ignore: avoid_print
    print('DEMO_REC_START $name');
    await wait(2500);
    await body();
    await wait(1200);
    // ignore: avoid_print
    print('DEMO_REC_STOP $name');
    DemoStage.caption.value = null;
    await wait(1500);
  }

  /// Scrolls [f] into view if it is off screen, scrolling down to build it if needed.
  Future<void> reveal(Finder f) async {
    for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
      await wait(400);
      if (f.evaluate().isEmpty) await scroll(280);
    }
    await waitFor(f);
    final el = f.evaluate().first;
    final box = el.renderObject as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = t.view.physicalSize.height / t.view.devicePixelRatio;
    if (top < 140 || top + box.size.height > screen - 120) {
      await Scrollable.ensureVisible(el, duration: const Duration(milliseconds: 500), alignment: 0.4);
      await wait(250);
    }
  }

  Future<void> tap(Finder f, {Finder? fallback, String? photoLabel, int after = 800}) async {
    var target = f;
    if (fallback != null) {
      try {
        await waitFor(f, timeoutMs: 4000);
      } on TestFailure {
        target = fallback;
      }
    }
    await waitFor(target);
    await reveal(target);
    if (photoLabel != null) _photoLabel = photoLabel;
    final at = t.getCenter(target.first);
    DemoStage.tapAt(at);
    await wait(250);
    await t.tapAt(at);
    await wait(after);
  }

  Future<void> type(Finder field, String text, {int waitAfter = 500, bool dismissKeyboard = true}) async {
    await tap(field, after: 500);
    final editable = find.descendant(of: field.first, matching: find.byType(EditableText), matchRoot: true).first;
    for (var i = 1; i <= text.length; i++) {
      await t.enterText(editable, text.substring(0, i));
      await wait(45);
    }
    await wait(waitAfter);
    if (dismissKeyboard) {
      FocusManager.instance.primaryFocus?.unfocus();
      await wait(600);
    }
  }

  Future<void> back() async {
    await tap(find.byType(BackButton).last);
  }

  Future<void> tapTab(String label) =>
      tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));

  Finder segment(String label) =>
      find.descendant(of: find.byWidgetPredicate((w) => w is SegmentedButton), matching: find.text(label));

  /// Scrolls the main list by [dy] logical pixels, smoothly.
  Future<void> scroll(double dy) async {
    ScrollableState? best;
    var bestArea = 0.0;
    for (final el in find.byType(Scrollable).hitTestable().evaluate()) {
      final s = (el as StatefulElement).state as ScrollableState;
      if (s.axisDirection != AxisDirection.down) continue;
      final size = (el.renderObject as RenderBox).size;
      if (size.width * size.height > bestArea) {
        bestArea = size.width * size.height;
        best = s;
      }
    }
    if (best == null) return;
    final p = best.position;
    final to = (p.pixels + dy).clamp(p.minScrollExtent, p.maxScrollExtent);
    await p.animateTo(to, duration: Duration(milliseconds: (dy.abs() * 1.6).clamp(300, 1400).round()), curve: Curves.easeInOut);
    await wait(300);
  }

  Future<void> answer(String label, {required bool yes, String? photo}) async {
    await reveal(find.textContaining(label));
    final card = _itemCard(label);
    await tap(find.descendant(of: card, matching: find.text(yes ? l.yes : l.no)));
    if (photo != null) {
      await tap(find.descendant(of: card, matching: find.text(l.takePhoto)), photoLabel: photo);
      await wait(600);
    }
  }

  Future<void> answerNumber(String label, String value) async {
    await reveal(find.textContaining(label));
    await type(find.descendant(of: _itemCard(label), matching: find.byType(TextField)), value);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(400);
  }

  /// The checklist item card: the nearest ancestor of the label that also holds its buttons.
  Finder _itemCard(String label) {
    final labelFinder = find.textContaining(label);
    final candidates = find.ancestor(of: labelFinder, matching: find.byWidgetPredicate((w) => w is Column));
    for (final el in candidates.evaluate()) {
      final f = find.byElementPredicate((e) => e == el);
      if (find.descendant(of: f, matching: find.text(l.yes)).evaluate().isNotEmpty ||
          find.descendant(of: f, matching: find.byType(TextField)).evaluate().isNotEmpty) {
        return f;
      }
    }
    throw TestFailure('No checklist item "$label"');
  }

  Future<void> signInQuietly(String phone) async {
    DemoStage.caption.value = null;
    if (find.byType(NavigationBar).evaluate().isNotEmpty) await signOut();
    await waitFor(find.text('EN'), timeoutMs: 20000);
    if (find.text(l.sendCode).evaluate().isEmpty) await t.tap(find.text('EN'));
    await waitFor(find.text(l.sendCode), timeoutMs: 20000);
    await t.enterText(find.byType(TextField).first, phone);
    await t.tap(find.text(l.sendCode));
    await waitFor(find.text(l.verifyAndContinue), timeoutMs: 20000);
    await t.enterText(find.byType(EditableText).last, otp);
    await waitFor(find.byType(NavigationBar), timeoutMs: 30000);
    await wait(2500);
  }

  Future<void> signOut() async {
    DemoStage.caption.value = null;
    while (find.byType(NavigationBar).evaluate().isEmpty && find.byType(BackButton).evaluate().isNotEmpty) {
      await t.tap(find.byType(BackButton).last);
      await wait(600);
    }
    await t.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(l.me)));
    await wait(800);
    final button = find.text(l.signOut);
    await t.ensureVisible(button);
    await t.tap(button);
    await wait(800);
    if (find.text(l.signOut).evaluate().length > 1) {
      await t.tap(find.text(l.signOut).last);
    }
    await waitFor(find.text('EN'), timeoutMs: 15000);
    await wait(800);
  }

  Future<void> signOutIfNeeded() async {
    await wait(2000);
    if (find.byType(NavigationBar).evaluate().isNotEmpty) await signOut();
  }

  /// A stand-in for the camera, labelled so nobody mistakes it for a real photo.
  Future<XFile?> fakePhoto() async {
    const w = 1200.0, h = 900.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(w, h),
            [const Color(0xFF51606B), const Color(0xFF2E3A40)]),
    );
    void text(String s, double size, double y, {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: w - 120);
      tp.paint(c, Offset((w - tp.width) / 2, y));
    }

    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.photo_camera_outlined.codePoint),
        style: TextStyle(fontSize: 200, fontFamily: Icons.photo_camera_outlined.fontFamily, color: Colors.white54),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    icon.paint(c, Offset((w - icon.width) / 2, 170));
    text(_photoLabel, 64, 430);
    text('Simulated camera photo · demo recording', 34, 540, color: Colors.white70, weight: FontWeight.w500);
    final image = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demo-${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return XFile(file.path);
  }
}

/// Caption bar above the app and a ring where each tap lands.
class DemoStage extends StatelessWidget {
  const DemoStage({super.key, required this.child});
  final Widget child;

  static final caption = ValueNotifier<(String, String)?>(null);
  static final _taps = ValueNotifier<List<(int, Offset)>>([]);
  static var _tapId = 0;

  static void tapAt(Offset at) {
    final id = ++_tapId;
    _taps.value = [..._taps.value, (id, at)];
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      _taps.value = _taps.value.where((e) => e.$1 != id).toList();
    });
  }

  /// Height of the caption strip below the status bar.
  static const strip = 96.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // The app lays out below the strip: its SafeAreas and app bars see a taller top inset.
    final inset = mq.copyWith(
      padding: mq.padding.copyWith(top: mq.padding.top + strip),
      viewPadding: mq.viewPadding.copyWith(top: mq.viewPadding.top + strip),
    );
    return Stack(
      children: [
        MediaQuery(data: inset, child: child),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: mq.padding.top + strip,
          child: IgnorePointer(
            child: Container(
              color: const Color(0xFF161B1A),
              padding: EdgeInsets.fromLTRB(20, mq.padding.top + 6, 20, 10),
              alignment: Alignment.topLeft,
              child: ValueListenableBuilder(
                valueListenable: caption,
                builder: (context, value, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (current, previous) =>
                      Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                  child: Column(
                    key: ValueKey(value),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text((value?.$1 ?? 'ASAH · Juta Berlian Culinary').toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF2B85C),
                              decoration: TextDecoration.none)),
                      const SizedBox(height: 5),
                      Text(value?.$2 ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: ValueListenableBuilder(
            valueListenable: _taps,
            builder: (context, taps, _) => Stack(
              children: [
                for (final (id, at) in taps)
                  Positioned(
                    key: ValueKey(id),
                    left: at.dx - 28,
                    top: at.dy - 28,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 850),
                      builder: (context, v, _) => Opacity(
                        opacity: (1 - v).clamp(0, 1),
                        child: Transform.scale(
                          scale: 0.6 + v * 0.6,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x55F2B85C),
                              border: Border.all(color: const Color(0xFFF2B85C), width: 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
