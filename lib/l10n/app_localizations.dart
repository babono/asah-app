import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @openAgain.
  ///
  /// In en, this message translates to:
  /// **'Open again'**
  String get openAgain;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrong;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @outlet.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get outlet;

  /// No description provided for @outlets.
  ///
  /// In en, this message translates to:
  /// **'Outlets'**
  String get outlets;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @mentor.
  ///
  /// In en, this message translates to:
  /// **'Mentor'**
  String get mentor;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @audits.
  ///
  /// In en, this message translates to:
  /// **'Audits'**
  String get audits;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideo;

  /// No description provided for @videoProcessing.
  ///
  /// In en, this message translates to:
  /// **'The video is still processing. Try again in a minute.'**
  String get videoProcessing;

  /// No description provided for @needConnectionToSend.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to send this.'**
  String get needConnectionToSend;

  /// No description provided for @useAdminWeb.
  ///
  /// In en, this message translates to:
  /// **'Your role works in the ASAH admin web. Open it on a computer.'**
  String get useAdminWeb;

  /// No description provided for @signInHeadline.
  ///
  /// In en, this message translates to:
  /// **'Learn it right.\nDo it right. Every shift.'**
  String get signInHeadline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInSub.
  ///
  /// In en, this message translates to:
  /// **'Use the phone number your outlet registered for you.'**
  String get signInSub;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Ask your outlet manager to add you.'**
  String get noAccount;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterCode;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent by SMS to {phone}'**
  String sentTo(String phone);

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyAndContinue;

  /// No description provided for @wrongCode.
  ///
  /// In en, this message translates to:
  /// **'That code did not work. Check it and try again.'**
  String get wrongCode;

  /// No description provided for @phoneNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This number is not registered. Ask your outlet manager to add you.'**
  String get phoneNotRegistered;

  /// No description provided for @accountNotReady.
  ///
  /// In en, this message translates to:
  /// **'Your account is not ready'**
  String get accountNotReady;

  /// No description provided for @accountNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has no profile yet or is inactive. Ask your outlet manager or HQ to set it up.'**
  String get accountNotReadyBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutQ.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQ;

  /// No description provided for @signOutUnsynced.
  ///
  /// In en, this message translates to:
  /// **'{count} items have not synced yet and will be lost.'**
  String signOutUnsynced(int count);

  /// No description provided for @hiName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hiName(String name);

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks'**
  String get todaysTasks;

  /// No description provided for @doneOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String doneOfTotal(int done, int total);

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No checklists for you today.'**
  String get noTasksToday;

  /// No description provided for @myLearning.
  ///
  /// In en, this message translates to:
  /// **'My learning'**
  String get myLearning;

  /// No description provided for @myPath.
  ///
  /// In en, this message translates to:
  /// **'My path'**
  String get myPath;

  /// No description provided for @yourMentor.
  ///
  /// In en, this message translates to:
  /// **'Your mentor'**
  String get yourMentor;

  /// No description provided for @weeklyCheckinWithMentor.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in with your mentor'**
  String get weeklyCheckinWithMentor;

  /// No description provided for @dayN.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String dayN(int n);

  /// No description provided for @shiftOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening shift'**
  String get shiftOpening;

  /// No description provided for @shiftMid.
  ///
  /// In en, this message translates to:
  /// **'Mid-day shift'**
  String get shiftMid;

  /// No description provided for @shiftClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing shift'**
  String get shiftClosing;

  /// No description provided for @shiftOther.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get shiftOther;

  /// No description provided for @dueAt.
  ///
  /// In en, this message translates to:
  /// **'Due {time}'**
  String dueAt(String time);

  /// No description provided for @lateDue.
  ///
  /// In en, this message translates to:
  /// **'Late · due {time}'**
  String lateDue(String time);

  /// No description provided for @doneLate.
  ///
  /// In en, this message translates to:
  /// **'Done late'**
  String get doneLate;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @needPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} need a photo'**
  String needPhotoCount(int count);

  /// No description provided for @startedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} answered'**
  String startedCount(int count);

  /// No description provided for @submittedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Submitted {time}'**
  String submittedAtTime(String time);

  /// No description provided for @startChecklist.
  ///
  /// In en, this message translates to:
  /// **'Start checklist'**
  String get startChecklist;

  /// No description provided for @continueChecklist.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueChecklist;

  /// No description provided for @startAudit.
  ///
  /// In en, this message translates to:
  /// **'Start audit'**
  String get startAudit;

  /// No description provided for @waitingToSync.
  ///
  /// In en, this message translates to:
  /// **'Submitted on this phone. It will sync when you are back online.'**
  String get waitingToSync;

  /// No description provided for @waitingToSyncShort.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get waitingToSyncShort;

  /// No description provided for @itemsWaitingToSync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item waiting to sync} other{{count} items waiting to sync}}'**
  String itemsWaitingToSync(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'{label} could not be sent: {error}'**
  String syncFailed(String label, String error);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @doneOfDue.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done · Due {time}'**
  String doneOfDue(int done, int total, String time);

  /// No description provided for @offlineAnswersSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline. Answers are saved and sync when you\'re back.'**
  String get offlineAnswersSaved;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo required'**
  String get photoRequired;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @addAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add another photo'**
  String get addAnotherPhoto;

  /// No description provided for @inAppCameraOnly.
  ///
  /// In en, this message translates to:
  /// **'In-app camera only'**
  String get inAppCameraOnly;

  /// No description provided for @inAppCamera.
  ///
  /// In en, this message translates to:
  /// **'in-app camera'**
  String get inAppCamera;

  /// No description provided for @raisesIssue.
  ///
  /// In en, this message translates to:
  /// **'This will raise an issue for the outlet manager.'**
  String get raisesIssue;

  /// No description provided for @outOfRangeRaisesIssue.
  ///
  /// In en, this message translates to:
  /// **'Out of range. This will raise an issue for the outlet manager.'**
  String get outOfRangeRaisesIssue;

  /// No description provided for @allowedRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed {min} to {max} {unit}'**
  String allowedRange(String min, String max, String unit);

  /// No description provided for @allowedMin.
  ///
  /// In en, this message translates to:
  /// **'At least {min} {unit}'**
  String allowedMin(String min, String unit);

  /// No description provided for @allowedMax.
  ///
  /// In en, this message translates to:
  /// **'At most {max} {unit}'**
  String allowedMax(String max, String unit);

  /// No description provided for @writeANote.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get writeANote;

  /// No description provided for @timeLocationAdded.
  ///
  /// In en, this message translates to:
  /// **'{outlet} · time and location added on submit'**
  String timeLocationAdded(String outlet);

  /// No description provided for @submitRaisesIssues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Submit · raises 1 issue} other{Submit · raises {count} issues}}'**
  String submitRaisesIssues(int count);

  /// No description provided for @itemsStillMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item still needs an answer or photo.} other{{count} items still need an answer or photo.}}'**
  String itemsStillMissing(int count);

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to submit. The checklist is stamped with where it was done.'**
  String get locationOff;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'ASAH needs location access to submit checklists. Allow it in Settings.'**
  String get locationDenied;

  /// No description provided for @outsideOutletTitle.
  ///
  /// In en, this message translates to:
  /// **'You seem to be outside the outlet'**
  String get outsideOutletTitle;

  /// No description provided for @outsideOutletBody.
  ///
  /// In en, this message translates to:
  /// **'You are about {meters} m from {outlet}. Checklists can only be submitted inside the outlet area.'**
  String outsideOutletBody(String outlet, int meters);

  /// No description provided for @submitAnyway.
  ///
  /// In en, this message translates to:
  /// **'Try anyway'**
  String get submitAnyway;

  /// No description provided for @savedOfflineWillSync.
  ///
  /// In en, this message translates to:
  /// **'Saved. It will be sent when you are back online.'**
  String get savedOfflineWillSync;

  /// No description provided for @submittedThanks.
  ///
  /// In en, this message translates to:
  /// **'Submitted. Thank you!'**
  String get submittedThanks;

  /// No description provided for @submittedWithIssues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Submitted. 1 issue sent to the outlet manager.} other{Submitted. {count} issues sent to the outlet manager.}}'**
  String submittedWithIssues(int count);

  /// No description provided for @submittedLate.
  ///
  /// In en, this message translates to:
  /// **'Submitted late'**
  String get submittedLate;

  /// No description provided for @submittedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Submitted on time'**
  String get submittedOnTime;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @notDoneYet.
  ///
  /// In en, this message translates to:
  /// **'Not done yet'**
  String get notDoneYet;

  /// No description provided for @passedOf.
  ///
  /// In en, this message translates to:
  /// **'{passed} of {total} passed'**
  String passedOf(int passed, int total);

  /// No description provided for @insideOutlet.
  ///
  /// In en, this message translates to:
  /// **'Inside the outlet'**
  String get insideOutlet;

  /// No description provided for @outsideOutlet.
  ///
  /// In en, this message translates to:
  /// **'Outside the outlet'**
  String get outsideOutlet;

  /// No description provided for @runMissedInfo.
  ///
  /// In en, this message translates to:
  /// **'This checklist was not done before its deadline. The outlet manager was alerted.'**
  String get runMissedInfo;

  /// No description provided for @runNotSubmittedYet.
  ///
  /// In en, this message translates to:
  /// **'Not submitted yet.'**
  String get runNotSubmittedYet;

  /// No description provided for @failedRaisedIssue.
  ///
  /// In en, this message translates to:
  /// **'Failed · raised an issue'**
  String get failedRaisedIssue;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String photoCount(int count);

  /// No description provided for @noModulesYet.
  ///
  /// In en, this message translates to:
  /// **'No modules assigned yet.'**
  String get noModulesYet;

  /// No description provided for @assignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get assignedToYou;

  /// No description provided for @day1.
  ///
  /// In en, this message translates to:
  /// **'Day 1'**
  String get day1;

  /// No description provided for @week1.
  ///
  /// In en, this message translates to:
  /// **'Week 1'**
  String get week1;

  /// No description provided for @month1.
  ///
  /// In en, this message translates to:
  /// **'Month 1'**
  String get month1;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @upNextModuleOf.
  ///
  /// In en, this message translates to:
  /// **'Up next · Module {n} of {total}'**
  String upNextModuleOf(int n, int total);

  /// No description provided for @pathComplete.
  ///
  /// In en, this message translates to:
  /// **'Path complete. Well done!'**
  String get pathComplete;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @refresher.
  ///
  /// In en, this message translates to:
  /// **'Refresher'**
  String get refresher;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDate(String date);

  /// No description provided for @moduleOfPath.
  ///
  /// In en, this message translates to:
  /// **'Module {n} of {total} · {path}'**
  String moduleOfPath(int n, int total, String path);

  /// No description provided for @moduleCompleted.
  ///
  /// In en, this message translates to:
  /// **'You completed this module.'**
  String get moduleCompleted;

  /// No description provided for @moduleCompletedCertificate.
  ///
  /// In en, this message translates to:
  /// **'You completed this module. Your certificate is in Me › Certificates.'**
  String get moduleCompletedCertificate;

  /// No description provided for @markWatched.
  ///
  /// In en, this message translates to:
  /// **'Mark watched'**
  String get markWatched;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @sopCard.
  ///
  /// In en, this message translates to:
  /// **'SOP card'**
  String get sopCard;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @quizPassMark.
  ///
  /// In en, this message translates to:
  /// **'Quiz · pass mark {pct}%'**
  String quizPassMark(int pct);

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @attemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 try left} other{{count} tries left}}'**
  String attemptsLeft(int count);

  /// No description provided for @lastScore.
  ///
  /// In en, this message translates to:
  /// **'Last score {pct}'**
  String lastScore(String pct);

  /// No description provided for @finishLessonsFirst.
  ///
  /// In en, this message translates to:
  /// **'Tip: watch and read the lessons before the quiz.'**
  String get finishLessonsFirst;

  /// No description provided for @noAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'No tries left. Ask your mentor for a refresher.'**
  String get noAttemptsLeft;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuiz;

  /// No description provided for @retakeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Retake quiz'**
  String get retakeQuiz;

  /// No description provided for @practicalTest.
  ///
  /// In en, this message translates to:
  /// **'Practical test'**
  String get practicalTest;

  /// No description provided for @practicalHowTo.
  ///
  /// In en, this message translates to:
  /// **'Record yourself doing it in the app. Your mentor scores each line.'**
  String get practicalHowTo;

  /// No description provided for @practicalWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sent. Waiting for your mentor to score it.'**
  String get practicalWaiting;

  /// No description provided for @practicalPassed.
  ///
  /// In en, this message translates to:
  /// **'Your mentor passed your practical test.'**
  String get practicalPassed;

  /// No description provided for @practicalRedo.
  ///
  /// In en, this message translates to:
  /// **'Your mentor asked you to redo it. Read the feedback below.'**
  String get practicalRedo;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @mentorFeedback.
  ///
  /// In en, this message translates to:
  /// **'Mentor feedback'**
  String get mentorFeedback;

  /// No description provided for @recordPracticalTest.
  ///
  /// In en, this message translates to:
  /// **'Record practical test'**
  String get recordPracticalTest;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @saveForOffline.
  ///
  /// In en, this message translates to:
  /// **'Save videos for offline'**
  String get saveForOffline;

  /// No description provided for @savedForOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved. You can watch this module offline.'**
  String get savedForOffline;

  /// No description provided for @downloadPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the download. Try again in a minute.'**
  String get downloadPreparing;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {total}'**
  String questionOf(int n, int total);

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get previous;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get nextQuestion;

  /// No description provided for @submitAnswers.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get submitAnswers;

  /// No description provided for @backToModule.
  ///
  /// In en, this message translates to:
  /// **'Back to module'**
  String get backToModule;

  /// No description provided for @quizHasNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This quiz has no questions yet.'**
  String get quizHasNoQuestions;

  /// No description provided for @quizPassedMessage.
  ///
  /// In en, this message translates to:
  /// **'You passed. Nice work!'**
  String get quizPassedMessage;

  /// No description provided for @quizFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Not yet. You need {pct}% to pass. Review the lessons and try again.'**
  String quizFailedMessage(int pct);

  /// No description provided for @recordInApp.
  ///
  /// In en, this message translates to:
  /// **'Recorded in the app only'**
  String get recordInApp;

  /// No description provided for @whatMentorChecks.
  ///
  /// In en, this message translates to:
  /// **'What your mentor checks'**
  String get whatMentorChecks;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @sendToMentor.
  ///
  /// In en, this message translates to:
  /// **'Send to mentor'**
  String get sendToMentor;

  /// No description provided for @practicalSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to your mentor.'**
  String get practicalSent;

  /// No description provided for @learningPath.
  ///
  /// In en, this message translates to:
  /// **'Learning path'**
  String get learningPath;

  /// No description provided for @certificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificates;

  /// No description provided for @noCertificatesYet.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet. Finish a module to earn one.'**
  String get noCertificatesYet;

  /// No description provided for @issuedOn.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String issuedOn(String date);

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntil(String date);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiresSoon.
  ///
  /// In en, this message translates to:
  /// **'Expires soon'**
  String get expiresSoon;

  /// No description provided for @myTrainees.
  ///
  /// In en, this message translates to:
  /// **'My trainees'**
  String get myTrainees;

  /// No description provided for @noTraineesYet.
  ///
  /// In en, this message translates to:
  /// **'No trainees yet. Your outlet manager assigns them.'**
  String get noTraineesYet;

  /// No description provided for @toDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get toDo;

  /// No description provided for @scorePracticalTest.
  ///
  /// In en, this message translates to:
  /// **'Score practical test'**
  String get scorePracticalTest;

  /// No description provided for @weeklyCheckinDue.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in due'**
  String get weeklyCheckinDue;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get thisWeek;

  /// No description provided for @behind.
  ///
  /// In en, this message translates to:
  /// **'Behind'**
  String get behind;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get onTrack;

  /// No description provided for @failedQuizTwice.
  ///
  /// In en, this message translates to:
  /// **'Failed a quiz twice'**
  String get failedQuizTwice;

  /// No description provided for @pathPct.
  ///
  /// In en, this message translates to:
  /// **'Path {pct}%'**
  String pathPct(int pct);

  /// No description provided for @lastQuiz.
  ///
  /// In en, this message translates to:
  /// **'Last quiz {pct}'**
  String lastQuiz(String pct);

  /// No description provided for @modulesOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 module overdue} other{{count} modules overdue}}'**
  String modulesOverdue(int count);

  /// No description provided for @myRatingAverage.
  ///
  /// In en, this message translates to:
  /// **'My rating: {avg} from {count} trainees. Ratings are anonymous.'**
  String myRatingAverage(String avg, int count);

  /// No description provided for @myRatingHidden.
  ///
  /// In en, this message translates to:
  /// **'My rating: shown as an average after {count} trainees rate you. Ratings are anonymous.'**
  String myRatingHidden(int count);

  /// No description provided for @weeklyCheckins.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-ins'**
  String get weeklyCheckins;

  /// No description provided for @weeklyCheckin.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in'**
  String get weeklyCheckin;

  /// No description provided for @logCheckin.
  ///
  /// In en, this message translates to:
  /// **'Log check-in'**
  String get logCheckin;

  /// No description provided for @noCheckinsYet.
  ///
  /// In en, this message translates to:
  /// **'No check-ins yet.'**
  String get noCheckinsYet;

  /// No description provided for @noCheckinsYetTrainee.
  ///
  /// In en, this message translates to:
  /// **'Your mentor has not logged a check-in yet.'**
  String get noCheckinsYetTrainee;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(String date);

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'What went well, what to work on'**
  String get feedbackHint;

  /// No description provided for @goalsNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Goals for next week'**
  String get goalsNextWeek;

  /// No description provided for @traineeSeesCheckin.
  ///
  /// In en, this message translates to:
  /// **'Your trainee can read this check-in.'**
  String get traineeSeesCheckin;

  /// No description provided for @saveCheckin.
  ///
  /// In en, this message translates to:
  /// **'Save check-in'**
  String get saveCheckin;

  /// No description provided for @checkinSaved.
  ///
  /// In en, this message translates to:
  /// **'Check-in saved.'**
  String get checkinSaved;

  /// No description provided for @rubric.
  ///
  /// In en, this message translates to:
  /// **'Rubric'**
  String get rubric;

  /// No description provided for @scoreEveryLine.
  ///
  /// In en, this message translates to:
  /// **'Score every rubric line first.'**
  String get scoreEveryLine;

  /// No description provided for @practicalMarkedPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed. The trainee was notified.'**
  String get practicalMarkedPassed;

  /// No description provided for @practicalAskedRedo.
  ///
  /// In en, this message translates to:
  /// **'Asked to redo. The trainee was notified.'**
  String get practicalAskedRedo;

  /// No description provided for @askToRedo.
  ///
  /// In en, this message translates to:
  /// **'Ask to redo'**
  String get askToRedo;

  /// No description provided for @feedbackFor.
  ///
  /// In en, this message translates to:
  /// **'Feedback for {name}'**
  String feedbackFor(String name);

  /// No description provided for @recordedInApp.
  ///
  /// In en, this message translates to:
  /// **'Recorded in app · {when}'**
  String recordedInApp(String when);

  /// No description provided for @alreadyScored.
  ///
  /// In en, this message translates to:
  /// **'This test was already scored.'**
  String get alreadyScored;

  /// No description provided for @mentorSince.
  ///
  /// In en, this message translates to:
  /// **'Your mentor since {date}'**
  String mentorSince(String date);

  /// No description provided for @mentorHelpNote.
  ///
  /// In en, this message translates to:
  /// **'Ask your mentor anything about your work. They score your practical tests and check in every week.'**
  String get mentorHelpNote;

  /// No description provided for @rateYourMentor.
  ///
  /// In en, this message translates to:
  /// **'Rate your mentor'**
  String get rateYourMentor;

  /// No description provided for @rateMentorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}, your mentor'**
  String rateMentorPrompt(String name);

  /// No description provided for @howWasMentor.
  ///
  /// In en, this message translates to:
  /// **'How was {name} as your mentor?'**
  String howWasMentor(String name);

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @ratingAnonymousNote.
  ///
  /// In en, this message translates to:
  /// **'Your mentor only sees an average from several trainees, never your name.'**
  String get ratingAnonymousNote;

  /// No description provided for @sendRating.
  ///
  /// In en, this message translates to:
  /// **'Send rating'**
  String get sendRating;

  /// No description provided for @thanksForRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your rating.'**
  String get thanksForRating;

  /// No description provided for @raiseIssue.
  ///
  /// In en, this message translates to:
  /// **'Raise issue'**
  String get raiseIssue;

  /// No description provided for @yourArea.
  ///
  /// In en, this message translates to:
  /// **'Your area'**
  String get yourArea;

  /// No description provided for @raisedByOrAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Raised by you or assigned to you'**
  String get raisedByOrAssignedToYou;

  /// No description provided for @checkFix.
  ///
  /// In en, this message translates to:
  /// **'Check fix'**
  String get checkFix;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @noIssuesHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get noIssuesHere;

  /// No description provided for @escalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get escalated;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @fromChecklist.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromChecklist(String name);

  /// No description provided for @fromAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit · {name}'**
  String fromAudit(String name);

  /// No description provided for @raisedByHand.
  ///
  /// In en, this message translates to:
  /// **'Raised by hand'**
  String get raisedByHand;

  /// No description provided for @closedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed {when}'**
  String closedAt(String when);

  /// No description provided for @fixWaitingForCheck.
  ///
  /// In en, this message translates to:
  /// **'Fixed {time} · waiting for a check'**
  String fixWaitingForCheck(String time);

  /// No description provided for @lateSince.
  ///
  /// In en, this message translates to:
  /// **'Late since {when}'**
  String lateSince(String when);

  /// No description provided for @dueEscalatesAfter.
  ///
  /// In en, this message translates to:
  /// **'Due {when} · escalates to area manager after'**
  String dueEscalatesAfter(String when);

  /// No description provided for @ifLate.
  ///
  /// In en, this message translates to:
  /// **'If late'**
  String get ifLate;

  /// No description provided for @escalatedAt.
  ///
  /// In en, this message translates to:
  /// **'Escalated {when}'**
  String escalatedAt(String when);

  /// No description provided for @escalatesToArea.
  ///
  /// In en, this message translates to:
  /// **'Escalates to area manager'**
  String get escalatesToArea;

  /// No description provided for @eventRaised.
  ///
  /// In en, this message translates to:
  /// **'Raised'**
  String get eventRaised;

  /// No description provided for @eventAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get eventAssigned;

  /// No description provided for @eventFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed with proof photo'**
  String get eventFixed;

  /// No description provided for @eventAccepted.
  ///
  /// In en, this message translates to:
  /// **'Fix accepted · closed'**
  String get eventAccepted;

  /// No description provided for @eventReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get eventReopened;

  /// No description provided for @eventEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated to area manager'**
  String get eventEscalated;

  /// No description provided for @eventComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get eventComment;

  /// No description provided for @waitingForManager.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the outlet manager'**
  String get waitingForManager;

  /// No description provided for @fixedWithProof.
  ///
  /// In en, this message translates to:
  /// **'Fixed with proof photo'**
  String get fixedWithProof;

  /// No description provided for @byTheOwner.
  ///
  /// In en, this message translates to:
  /// **'By the owner'**
  String get byTheOwner;

  /// No description provided for @acceptedOrReopened.
  ///
  /// In en, this message translates to:
  /// **'Accepted or reopened'**
  String get acceptedOrReopened;

  /// No description provided for @notTheFixer.
  ///
  /// In en, this message translates to:
  /// **'By whoever raised it or the area manager, not the fixer'**
  String get notTheFixer;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get assignTo;

  /// No description provided for @assignedNotified.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}, notified by push.'**
  String assignedNotified(String name);

  /// No description provided for @whatDidYouFix.
  ///
  /// In en, this message translates to:
  /// **'What did you fix?'**
  String get whatDidYouFix;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get optionalNote;

  /// No description provided for @markedFixed.
  ///
  /// In en, this message translates to:
  /// **'Marked fixed. Someone else will check it.'**
  String get markedFixed;

  /// No description provided for @issueClosedMsg.
  ///
  /// In en, this message translates to:
  /// **'Fix accepted. Issue closed.'**
  String get issueClosedMsg;

  /// No description provided for @whyReopen.
  ///
  /// In en, this message translates to:
  /// **'Why reopen it?'**
  String get whyReopen;

  /// No description provided for @reopenHint.
  ///
  /// In en, this message translates to:
  /// **'What still needs fixing'**
  String get reopenHint;

  /// No description provided for @issueReopenedMsg.
  ///
  /// In en, this message translates to:
  /// **'Reopened. The fixer was notified.'**
  String get issueReopenedMsg;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addComment;

  /// No description provided for @commentAdded.
  ///
  /// In en, this message translates to:
  /// **'Comment added.'**
  String get commentAdded;

  /// No description provided for @assignRefresher.
  ///
  /// In en, this message translates to:
  /// **'Assign a refresher module'**
  String get assignRefresher;

  /// No description provided for @refresherAssigned.
  ///
  /// In en, this message translates to:
  /// **'Refresher assigned.'**
  String get refresherAssigned;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @acceptFix.
  ///
  /// In en, this message translates to:
  /// **'Accept fix'**
  String get acceptFix;

  /// No description provided for @assignOwner.
  ///
  /// In en, this message translates to:
  /// **'Assign owner'**
  String get assignOwner;

  /// No description provided for @changeOwner.
  ///
  /// In en, this message translates to:
  /// **'Change owner'**
  String get changeOwner;

  /// No description provided for @markFixed.
  ///
  /// In en, this message translates to:
  /// **'Mark fixed'**
  String get markFixed;

  /// No description provided for @waitingForSomeoneToCheck.
  ///
  /// In en, this message translates to:
  /// **'You fixed this. Someone else will check it.'**
  String get waitingForSomeoneToCheck;

  /// No description provided for @whatIsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get whatIsWrong;

  /// No description provided for @whatIsWrongHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hand soap empty'**
  String get whatIsWrongHint;

  /// No description provided for @detailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get detailsOptional;

  /// No description provided for @howUrgent.
  ///
  /// In en, this message translates to:
  /// **'How urgent?'**
  String get howUrgent;

  /// No description provided for @fixWithinHours.
  ///
  /// In en, this message translates to:
  /// **'Fix within {hours} hours, then it escalates.'**
  String fixWithinHours(int hours);

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @issueRaised.
  ///
  /// In en, this message translates to:
  /// **'Issue raised.'**
  String get issueRaised;

  /// No description provided for @outletManager.
  ///
  /// In en, this message translates to:
  /// **'Outlet manager'**
  String get outletManager;

  /// No description provided for @outletToday.
  ///
  /// In en, this message translates to:
  /// **'{name} · Today'**
  String outletToday(String name);

  /// No description provided for @noOutletAssigned.
  ///
  /// In en, this message translates to:
  /// **'No outlet assigned to you yet.'**
  String get noOutletAssigned;

  /// No description provided for @checklistsByShift.
  ///
  /// In en, this message translates to:
  /// **'Checklists by shift'**
  String get checklistsByShift;

  /// No description provided for @noChecklistsScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'No checklists scheduled today.'**
  String get noChecklistsScheduledToday;

  /// No description provided for @openIssues.
  ///
  /// In en, this message translates to:
  /// **'Open issues'**
  String get openIssues;

  /// No description provided for @allIssues.
  ///
  /// In en, this message translates to:
  /// **'All issues'**
  String get allIssues;

  /// No description provided for @noOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'No open issues.'**
  String get noOpenIssues;

  /// No description provided for @checklistsDone.
  ///
  /// In en, this message translates to:
  /// **'Checklists done'**
  String get checklistsDone;

  /// No description provided for @lateChecklists.
  ///
  /// In en, this message translates to:
  /// **'Late checklists'**
  String get lateChecklists;

  /// No description provided for @doneFailedItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Done · 1 failed} other{Done · {count} failed}}'**
  String doneFailedItems(int count);

  /// No description provided for @everyoneOnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Everyone is on schedule.'**
  String get everyoneOnSchedule;

  /// No description provided for @personBehind.
  ///
  /// In en, this message translates to:
  /// **'{name} behind schedule'**
  String personBehind(String name);

  /// No description provided for @mentorName.
  ///
  /// In en, this message translates to:
  /// **'Mentor: {name}'**
  String mentorName(String name);

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get myTasks;

  /// No description provided for @mentorsN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{mentors 1} other{mentors {count}}}'**
  String mentorsN(int count);

  /// No description provided for @signoffsToSpotCheck.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mentor sign-off to spot-check} other{{count} mentor sign-offs to spot-check}}'**
  String signoffsToSpotCheck(int count);

  /// No description provided for @noMentorYet.
  ///
  /// In en, this message translates to:
  /// **'No mentor yet'**
  String get noMentorYet;

  /// No description provided for @sinceDate.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String sinceDate(String date);

  /// No description provided for @assignMentor.
  ///
  /// In en, this message translates to:
  /// **'Assign mentor'**
  String get assignMentor;

  /// No description provided for @changeMentor.
  ///
  /// In en, this message translates to:
  /// **'Change mentor'**
  String get changeMentor;

  /// No description provided for @endMentorship.
  ///
  /// In en, this message translates to:
  /// **'End mentorship'**
  String get endMentorship;

  /// No description provided for @endMentorshipQ.
  ///
  /// In en, this message translates to:
  /// **'End this mentorship?'**
  String get endMentorshipQ;

  /// No description provided for @endMentorshipBody.
  ///
  /// In en, this message translates to:
  /// **'Do this when the trainee finished their path. The trainee can then rate the mentor.'**
  String get endMentorshipBody;

  /// No description provided for @mentorshipEnded.
  ///
  /// In en, this message translates to:
  /// **'Mentorship ended.'**
  String get mentorshipEnded;

  /// No description provided for @assignModule.
  ///
  /// In en, this message translates to:
  /// **'Assign module'**
  String get assignModule;

  /// No description provided for @moduleAssigned.
  ///
  /// In en, this message translates to:
  /// **'Module assigned.'**
  String get moduleAssigned;

  /// No description provided for @pickMentor.
  ///
  /// In en, this message translates to:
  /// **'Pick a mentor'**
  String get pickMentor;

  /// No description provided for @mentorRulesNote.
  ///
  /// In en, this message translates to:
  /// **'Mentors need the Mentor role, a minimum level, their own path done and room for another trainee. ASAH checks this.'**
  String get mentorRulesNote;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelN(int n);

  /// No description provided for @mentorAssigned.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the mentor.'**
  String mentorAssigned(String name);

  /// No description provided for @mentorSignoffs.
  ///
  /// In en, this message translates to:
  /// **'Mentor sign-offs'**
  String get mentorSignoffs;

  /// No description provided for @spotCheckExplainer.
  ///
  /// In en, this message translates to:
  /// **'Check a sample of practical tests your mentors scored. Watch the video and say if you agree.'**
  String get spotCheckExplainer;

  /// No description provided for @scoredByOn.
  ///
  /// In en, this message translates to:
  /// **'Scored by {name} · {when}'**
  String scoredByOn(String name, String when);

  /// No description provided for @spotChecked.
  ///
  /// In en, this message translates to:
  /// **'Spot-checked'**
  String get spotChecked;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// No description provided for @disagree.
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get disagree;

  /// No description provided for @whatIsWrongWithSignoff.
  ///
  /// In en, this message translates to:
  /// **'What is wrong with this sign-off?'**
  String get whatIsWrongWithSignoff;

  /// No description provided for @spotCheckSaved.
  ///
  /// In en, this message translates to:
  /// **'Spot check saved.'**
  String get spotCheckSaved;

  /// No description provided for @areaOverview.
  ///
  /// In en, this message translates to:
  /// **'Area overview'**
  String get areaOverview;

  /// No description provided for @outletsN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 outlet} other{{count} outlets}}'**
  String outletsN(int count);

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @checklistsOnTime.
  ///
  /// In en, this message translates to:
  /// **'Checklists on time'**
  String get checklistsOnTime;

  /// No description provided for @lateEscalated.
  ///
  /// In en, this message translates to:
  /// **'Late issues, escalated'**
  String get lateEscalated;

  /// No description provided for @trainingOnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Training on schedule'**
  String get trainingOnSchedule;

  /// No description provided for @byOutlet.
  ///
  /// In en, this message translates to:
  /// **'By outlet'**
  String get byOutlet;

  /// No description provided for @escalatedToYou.
  ///
  /// In en, this message translates to:
  /// **'Escalated to you'**
  String get escalatedToYou;

  /// No description provided for @openIssuesN.
  ///
  /// In en, this message translates to:
  /// **'{count} open issues'**
  String openIssuesN(int count);

  /// No description provided for @lateN.
  ///
  /// In en, this message translates to:
  /// **'{count} late'**
  String lateN(int count);

  /// No description provided for @trainingOnScheduleShort.
  ///
  /// In en, this message translates to:
  /// **'Training on schedule'**
  String get trainingOnScheduleShort;

  /// No description provided for @traineesBehindN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trainee behind} other{{count} trainees behind}}'**
  String traineesBehindN(int count);

  /// No description provided for @noAuditYet.
  ///
  /// In en, this message translates to:
  /// **'No audit yet'**
  String get noAuditYet;

  /// No description provided for @lastAuditDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Audited today} =1{Last audit yesterday} other{Last audit {days} days ago}}'**
  String lastAuditDaysAgo(int days);

  /// No description provided for @visitAudits.
  ///
  /// In en, this message translates to:
  /// **'Visit audits'**
  String get visitAudits;

  /// No description provided for @auditsExplainer.
  ///
  /// In en, this message translates to:
  /// **'Findings become issues for the outlet'**
  String get auditsExplainer;

  /// No description provided for @noAuditsYet.
  ///
  /// In en, this message translates to:
  /// **'No audits yet. Start one when you visit an outlet.'**
  String get noAuditsYet;

  /// No description provided for @noAuditForms.
  ///
  /// In en, this message translates to:
  /// **'HQ has not published an audit form yet.'**
  String get noAuditForms;

  /// No description provided for @auditForm.
  ///
  /// In en, this message translates to:
  /// **'Audit form'**
  String get auditForm;

  /// No description provided for @auditScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score} · {date}'**
  String auditScore(String score, String date);

  /// No description provided for @inProgressSince.
  ///
  /// In en, this message translates to:
  /// **'In progress since {date}'**
  String inProgressSince(String date);

  /// No description provided for @findingsN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 finding} other{{count} findings}}'**
  String findingsN(int count);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotifications;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} new'**
  String notificationsUnread(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
