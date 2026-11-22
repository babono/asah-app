// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Try again';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get done => 'Done';

  @override
  String get submit => 'Submit';

  @override
  String get open => 'Open';

  @override
  String get openAgain => 'Open again';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get someone => 'Someone';

  @override
  String get system => 'System';

  @override
  String get somethingWentWrong => 'Something went wrong. Try again.';

  @override
  String get status => 'Status';

  @override
  String get due => 'Due';

  @override
  String get submitted => 'Submitted';

  @override
  String get result => 'Result';

  @override
  String get location => 'Location';

  @override
  String get progress => 'Progress';

  @override
  String get source => 'Source';

  @override
  String get deadline => 'Deadline';

  @override
  String get owner => 'Owner';

  @override
  String get outlet => 'Outlet';

  @override
  String get outlets => 'Outlets';

  @override
  String get offline => 'Offline';

  @override
  String get language => 'Language';

  @override
  String get later => 'Later';

  @override
  String get video => 'Video';

  @override
  String get document => 'Document';

  @override
  String get read => 'Read';

  @override
  String get watch => 'Watch';

  @override
  String get review => 'Review';

  @override
  String get comment => 'Comment';

  @override
  String get feedback => 'Feedback';

  @override
  String get goals => 'Goals';

  @override
  String get training => 'Training';

  @override
  String get team => 'Team';

  @override
  String get today => 'Today';

  @override
  String get learn => 'Learn';

  @override
  String get mentor => 'Mentor';

  @override
  String get issues => 'Issues';

  @override
  String get issue => 'Issue';

  @override
  String get audits => 'Audits';

  @override
  String get me => 'Me';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get playVideo => 'Play video';

  @override
  String get pauseVideo => 'Pause video';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String get videoProcessing =>
      'The video is still processing. Try again in a minute.';

  @override
  String get needConnectionToSend => 'You need a connection to send this.';

  @override
  String get useAdminWeb =>
      'Your role works in the ASAH admin web. Open it on a computer.';

  @override
  String get signInHeadline => 'Learn it right.\nDo it right. Every shift.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSub =>
      'Use the phone number your outlet registered for you.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get sendCode => 'Send code';

  @override
  String get noAccount => 'No account yet? Ask your outlet manager to add you.';

  @override
  String get changeNumber => 'Change number';

  @override
  String get enterCode => 'Enter the 6-digit code';

  @override
  String sentTo(String phone) {
    return 'Sent by SMS to $phone';
  }

  @override
  String resendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get verifyAndContinue => 'Verify and continue';

  @override
  String get wrongCode => 'That code did not work. Check it and try again.';

  @override
  String get phoneNotRegistered =>
      'This number is not registered. Ask your outlet manager to add you.';

  @override
  String get accountNotReady => 'Your account is not ready';

  @override
  String get accountNotReadyBody =>
      'Your account has no profile yet or is inactive. Ask your outlet manager or HQ to set it up.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutQ => 'Sign out?';

  @override
  String signOutUnsynced(int count) {
    return '$count items have not synced yet and will be lost.';
  }

  @override
  String hiName(String name) {
    return 'Hi, $name';
  }

  @override
  String get todaysTasks => 'Today\'s tasks';

  @override
  String doneOfTotal(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get noTasksToday => 'No checklists for you today.';

  @override
  String get myLearning => 'My learning';

  @override
  String get myPath => 'My path';

  @override
  String get yourMentor => 'Your mentor';

  @override
  String get weeklyCheckinWithMentor => 'Weekly check-in with your mentor';

  @override
  String dayN(int n) {
    return 'Day $n';
  }

  @override
  String get shiftOpening => 'Opening shift';

  @override
  String get shiftMid => 'Mid-day shift';

  @override
  String get shiftClosing => 'Closing shift';

  @override
  String get shiftOther => 'Any time';

  @override
  String dueAt(String time) {
    return 'Due $time';
  }

  @override
  String lateDue(String time) {
    return 'Late · due $time';
  }

  @override
  String get doneLate => 'Done late';

  @override
  String get missed => 'Missed';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String needPhotoCount(int count) {
    return '$count need a photo';
  }

  @override
  String startedCount(int count) {
    return '$count answered';
  }

  @override
  String submittedAtTime(String time) {
    return 'Submitted $time';
  }

  @override
  String get startChecklist => 'Start checklist';

  @override
  String get continueChecklist => 'Continue';

  @override
  String get startAudit => 'Start audit';

  @override
  String get waitingToSync =>
      'Submitted on this phone. It will sync when you are back online.';

  @override
  String get waitingToSyncShort => 'Waiting to sync';

  @override
  String itemsWaitingToSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items waiting to sync',
      one: '1 item waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String syncFailed(String label, String error) {
    return '$label could not be sent: $error';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String doneOfDue(int done, int total, String time) {
    return '$done of $total done · Due $time';
  }

  @override
  String get offlineAnswersSaved =>
      'Offline. Answers are saved and sync when you\'re back.';

  @override
  String get photoRequired => 'Photo required';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get addAnotherPhoto => 'Add another photo';

  @override
  String get inAppCameraOnly => 'In-app camera only';

  @override
  String get inAppCamera => 'in-app camera';

  @override
  String get raisesIssue => 'This will raise an issue for the outlet manager.';

  @override
  String get outOfRangeRaisesIssue =>
      'Out of range. This will raise an issue for the outlet manager.';

  @override
  String allowedRange(String min, String max, String unit) {
    return 'Allowed $min to $max $unit';
  }

  @override
  String allowedMin(String min, String unit) {
    return 'At least $min $unit';
  }

  @override
  String allowedMax(String max, String unit) {
    return 'At most $max $unit';
  }

  @override
  String get writeANote => 'Write a note';

  @override
  String timeLocationAdded(String outlet) {
    return '$outlet · time and location added on submit';
  }

  @override
  String submitRaisesIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Submit · raises $count issues',
      one: 'Submit · raises 1 issue',
    );
    return '$_temp0';
  }

  @override
  String itemsStillMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items still need an answer or photo.',
      one: '1 item still needs an answer or photo.',
    );
    return '$_temp0';
  }

  @override
  String get locationOff =>
      'Turn on location to submit. The checklist is stamped with where it was done.';

  @override
  String get locationDenied =>
      'ASAH needs location access to submit checklists. Allow it in Settings.';

  @override
  String get outsideOutletTitle => 'You seem to be outside the outlet';

  @override
  String outsideOutletBody(String outlet, int meters) {
    return 'You are about $meters m from $outlet. Checklists can only be submitted inside the outlet area.';
  }

  @override
  String get submitAnyway => 'Try anyway';

  @override
  String get savedOfflineWillSync =>
      'Saved. It will be sent when you are back online.';

  @override
  String get submittedThanks => 'Submitted. Thank you!';

  @override
  String submittedWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Submitted. $count issues sent to the outlet manager.',
      one: 'Submitted. 1 issue sent to the outlet manager.',
    );
    return '$_temp0';
  }

  @override
  String get submittedLate => 'Submitted late';

  @override
  String get submittedOnTime => 'Submitted on time';

  @override
  String get late => 'Late';

  @override
  String get notDoneYet => 'Not done yet';

  @override
  String passedOf(int passed, int total) {
    return '$passed of $total passed';
  }

  @override
  String get insideOutlet => 'Inside the outlet';

  @override
  String get outsideOutlet => 'Outside the outlet';

  @override
  String get runMissedInfo =>
      'This checklist was not done before its deadline. The outlet manager was alerted.';

  @override
  String get runNotSubmittedYet => 'Not submitted yet.';

  @override
  String get failedRaisedIssue => 'Failed · raised an issue';

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get noModulesYet => 'No modules assigned yet.';

  @override
  String get assignedToYou => 'Assigned to you';

  @override
  String get day1 => 'Day 1';

  @override
  String get week1 => 'Week 1';

  @override
  String get month1 => 'Month 1';

  @override
  String get upNext => 'Up next';

  @override
  String upNextModuleOf(int n, int total) {
    return 'Up next · Module $n of $total';
  }

  @override
  String get pathComplete => 'Path complete. Well done!';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get refresher => 'Refresher';

  @override
  String get updated => 'Updated';

  @override
  String dueDate(String date) {
    return 'Due $date';
  }

  @override
  String moduleOfPath(int n, int total, String path) {
    return 'Module $n of $total · $path';
  }

  @override
  String get moduleCompleted => 'You completed this module.';

  @override
  String get moduleCompletedCertificate =>
      'You completed this module. Your certificate is in Me › Certificates.';

  @override
  String get markWatched => 'Mark watched';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get sopCard => 'SOP card';

  @override
  String get quiz => 'Quiz';

  @override
  String quizPassMark(int pct) {
    return 'Quiz · pass mark $pct%';
  }

  @override
  String get passed => 'Passed';

  @override
  String attemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left',
      one: '1 try left',
    );
    return '$_temp0';
  }

  @override
  String lastScore(String pct) {
    return 'Last score $pct';
  }

  @override
  String get finishLessonsFirst =>
      'Tip: watch and read the lessons before the quiz.';

  @override
  String get noAttemptsLeft =>
      'No tries left. Ask your mentor for a refresher.';

  @override
  String get startQuiz => 'Start quiz';

  @override
  String get retakeQuiz => 'Retake quiz';

  @override
  String get practicalTest => 'Practical test';

  @override
  String get practicalHowTo =>
      'Record yourself doing it in the app. Your mentor scores each line.';

  @override
  String get practicalWaiting => 'Sent. Waiting for your mentor to score it.';

  @override
  String get practicalPassed => 'Your mentor passed your practical test.';

  @override
  String get practicalRedo =>
      'Your mentor asked you to redo it. Read the feedback below.';

  @override
  String get pass => 'Pass';

  @override
  String get redo => 'Redo';

  @override
  String get mentorFeedback => 'Mentor feedback';

  @override
  String get recordPracticalTest => 'Record practical test';

  @override
  String get recordAgain => 'Record again';

  @override
  String get saveForOffline => 'Save videos for offline';

  @override
  String get savedForOffline => 'Saved. You can watch this module offline.';

  @override
  String get downloadPreparing =>
      'Preparing the download. Try again in a minute.';

  @override
  String questionOf(int n, int total) {
    return 'Question $n of $total';
  }

  @override
  String get previous => 'Back';

  @override
  String get nextQuestion => 'Next question';

  @override
  String get submitAnswers => 'Submit answers';

  @override
  String get backToModule => 'Back to module';

  @override
  String get quizHasNoQuestions => 'This quiz has no questions yet.';

  @override
  String get quizPassedMessage => 'You passed. Nice work!';

  @override
  String quizFailedMessage(int pct) {
    return 'Not yet. You need $pct% to pass. Review the lessons and try again.';
  }

  @override
  String get recordInApp => 'Recorded in the app only';

  @override
  String get whatMentorChecks => 'What your mentor checks';

  @override
  String get record => 'Record';

  @override
  String get sendToMentor => 'Send to mentor';

  @override
  String get practicalSent => 'Sent to your mentor.';

  @override
  String get learningPath => 'Learning path';

  @override
  String get certificates => 'Certificates';

  @override
  String get noCertificatesYet =>
      'No certificates yet. Finish a module to earn one.';

  @override
  String issuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String validUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get expired => 'Expired';

  @override
  String get expiresSoon => 'Expires soon';

  @override
  String get myTrainees => 'My trainees';

  @override
  String get noTraineesYet =>
      'No trainees yet. Your outlet manager assigns them.';

  @override
  String get toDo => 'To do';

  @override
  String get scorePracticalTest => 'Score practical test';

  @override
  String get weeklyCheckinDue => 'Weekly check-in due';

  @override
  String get thisWeek => 'this week';

  @override
  String get behind => 'Behind';

  @override
  String get onTrack => 'On track';

  @override
  String get failedQuizTwice => 'Failed a quiz twice';

  @override
  String pathPct(int pct) {
    return 'Path $pct%';
  }

  @override
  String lastQuiz(String pct) {
    return 'Last quiz $pct';
  }

  @override
  String modulesOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modules overdue',
      one: '1 module overdue',
    );
    return '$_temp0';
  }

  @override
  String myRatingAverage(String avg, int count) {
    return 'My rating: $avg from $count trainees. Ratings are anonymous.';
  }

  @override
  String myRatingHidden(int count) {
    return 'My rating: shown as an average after $count trainees rate you. Ratings are anonymous.';
  }

  @override
  String get weeklyCheckins => 'Weekly check-ins';

  @override
  String get weeklyCheckin => 'Weekly check-in';

  @override
  String get logCheckin => 'Log check-in';

  @override
  String get noCheckinsYet => 'No check-ins yet.';

  @override
  String get noCheckinsYetTrainee =>
      'Your mentor has not logged a check-in yet.';

  @override
  String weekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get feedbackHint => 'What went well, what to work on';

  @override
  String get goalsNextWeek => 'Goals for next week';

  @override
  String get traineeSeesCheckin => 'Your trainee can read this check-in.';

  @override
  String get saveCheckin => 'Save check-in';

  @override
  String get checkinSaved => 'Check-in saved.';

  @override
  String get rubric => 'Rubric';

  @override
  String get scoreEveryLine => 'Score every rubric line first.';

  @override
  String get practicalMarkedPassed => 'Passed. The trainee was notified.';

  @override
  String get practicalAskedRedo => 'Asked to redo. The trainee was notified.';

  @override
  String get askToRedo => 'Ask to redo';

  @override
  String feedbackFor(String name) {
    return 'Feedback for $name';
  }

  @override
  String recordedInApp(String when) {
    return 'Recorded in app · $when';
  }

  @override
  String get alreadyScored => 'This test was already scored.';

  @override
  String mentorSince(String date) {
    return 'Your mentor since $date';
  }

  @override
  String get mentorHelpNote =>
      'Ask your mentor anything about your work. They score your practical tests and check in every week.';

  @override
  String get rateYourMentor => 'Rate your mentor';

  @override
  String rateMentorPrompt(String name) {
    return 'Rate $name, your mentor';
  }

  @override
  String howWasMentor(String name) {
    return 'How was $name as your mentor?';
  }

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get ratingAnonymousNote =>
      'Your mentor only sees an average from several trainees, never your name.';

  @override
  String get sendRating => 'Send rating';

  @override
  String get thanksForRating => 'Thank you for your rating.';

  @override
  String get raiseIssue => 'Raise issue';

  @override
  String get yourArea => 'Your area';

  @override
  String get raisedByOrAssignedToYou => 'Raised by you or assigned to you';

  @override
  String get checkFix => 'Check fix';

  @override
  String get closed => 'Closed';

  @override
  String get noIssuesHere => 'Nothing here.';

  @override
  String get escalated => 'Escalated';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get assigned => 'Assigned';

  @override
  String get severityHigh => 'High';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityLow => 'Low';

  @override
  String fromChecklist(String name) {
    return 'From $name';
  }

  @override
  String fromAudit(String name) {
    return 'Audit · $name';
  }

  @override
  String get raisedByHand => 'Raised by hand';

  @override
  String closedAt(String when) {
    return 'Closed $when';
  }

  @override
  String fixWaitingForCheck(String time) {
    return 'Fixed $time · waiting for a check';
  }

  @override
  String lateSince(String when) {
    return 'Late since $when';
  }

  @override
  String dueEscalatesAfter(String when) {
    return 'Due $when · escalates to area manager after';
  }

  @override
  String get ifLate => 'If late';

  @override
  String escalatedAt(String when) {
    return 'Escalated $when';
  }

  @override
  String get escalatesToArea => 'Escalates to area manager';

  @override
  String get eventRaised => 'Raised';

  @override
  String get eventAssigned => 'Assigned';

  @override
  String get eventFixed => 'Fixed with proof photo';

  @override
  String get eventAccepted => 'Fix accepted · closed';

  @override
  String get eventReopened => 'Reopened';

  @override
  String get eventEscalated => 'Escalated to area manager';

  @override
  String get eventComment => 'Comment';

  @override
  String get waitingForManager => 'Waiting for the outlet manager';

  @override
  String get fixedWithProof => 'Fixed with proof photo';

  @override
  String get byTheOwner => 'By the owner';

  @override
  String get acceptedOrReopened => 'Accepted or reopened';

  @override
  String get notTheFixer =>
      'By whoever raised it or the area manager, not the fixer';

  @override
  String get assignTo => 'Assign to';

  @override
  String assignedNotified(String name) {
    return 'Assigned to $name, notified by push.';
  }

  @override
  String get whatDidYouFix => 'What did you fix?';

  @override
  String get optionalNote => 'Optional note';

  @override
  String get markedFixed => 'Marked fixed. Someone else will check it.';

  @override
  String get issueClosedMsg => 'Fix accepted. Issue closed.';

  @override
  String get whyReopen => 'Why reopen it?';

  @override
  String get reopenHint => 'What still needs fixing';

  @override
  String get issueReopenedMsg => 'Reopened. The fixer was notified.';

  @override
  String get addComment => 'Add a comment';

  @override
  String get commentAdded => 'Comment added.';

  @override
  String get assignRefresher => 'Assign a refresher module';

  @override
  String get refresherAssigned => 'Refresher assigned.';

  @override
  String get reopen => 'Reopen';

  @override
  String get acceptFix => 'Accept fix';

  @override
  String get assignOwner => 'Assign owner';

  @override
  String get changeOwner => 'Change owner';

  @override
  String get markFixed => 'Mark fixed';

  @override
  String get waitingForSomeoneToCheck =>
      'You fixed this. Someone else will check it.';

  @override
  String get whatIsWrong => 'What\'s wrong?';

  @override
  String get whatIsWrongHint => 'e.g. Hand soap empty';

  @override
  String get detailsOptional => 'Details (optional)';

  @override
  String get howUrgent => 'How urgent?';

  @override
  String fixWithinHours(int hours) {
    return 'Fix within $hours hours, then it escalates.';
  }

  @override
  String get addPhoto => 'Add photo';

  @override
  String get issueRaised => 'Issue raised.';

  @override
  String get outletManager => 'Outlet manager';

  @override
  String outletToday(String name) {
    return '$name · Today';
  }

  @override
  String get noOutletAssigned => 'No outlet assigned to you yet.';

  @override
  String get checklistsByShift => 'Checklists by shift';

  @override
  String get noChecklistsScheduledToday => 'No checklists scheduled today.';

  @override
  String get openIssues => 'Open issues';

  @override
  String get allIssues => 'All issues';

  @override
  String get noOpenIssues => 'No open issues.';

  @override
  String get checklistsDone => 'Checklists done';

  @override
  String get lateChecklists => 'Late checklists';

  @override
  String doneFailedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done · $count failed',
      one: 'Done · 1 failed',
    );
    return '$_temp0';
  }

  @override
  String get everyoneOnSchedule => 'Everyone is on schedule.';

  @override
  String personBehind(String name) {
    return '$name behind schedule';
  }

  @override
  String mentorName(String name) {
    return 'Mentor: $name';
  }

  @override
  String get myTasks => 'My tasks';

  @override
  String mentorsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mentors $count',
      one: 'mentors 1',
    );
    return '$_temp0';
  }

  @override
  String signoffsToSpotCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mentor sign-offs to spot-check',
      one: '1 mentor sign-off to spot-check',
    );
    return '$_temp0';
  }

  @override
  String get noMentorYet => 'No mentor yet';

  @override
  String sinceDate(String date) {
    return 'since $date';
  }

  @override
  String get assignMentor => 'Assign mentor';

  @override
  String get changeMentor => 'Change mentor';

  @override
  String get endMentorship => 'End mentorship';

  @override
  String get endMentorshipQ => 'End this mentorship?';

  @override
  String get endMentorshipBody =>
      'Do this when the trainee finished their path. The trainee can then rate the mentor.';

  @override
  String get mentorshipEnded => 'Mentorship ended.';

  @override
  String get assignModule => 'Assign module';

  @override
  String get moduleAssigned => 'Module assigned.';

  @override
  String get pickMentor => 'Pick a mentor';

  @override
  String get mentorRulesNote =>
      'Mentors need the Mentor role, a minimum level, their own path done and room for another trainee. ASAH checks this.';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String mentorAssigned(String name) {
    return '$name is now the mentor.';
  }

  @override
  String get mentorSignoffs => 'Mentor sign-offs';

  @override
  String get spotCheckExplainer =>
      'Check a sample of practical tests your mentors scored. Watch the video and say if you agree.';

  @override
  String scoredByOn(String name, String when) {
    return 'Scored by $name · $when';
  }

  @override
  String get spotChecked => 'Spot-checked';

  @override
  String get agree => 'Agree';

  @override
  String get disagree => 'Disagree';

  @override
  String get whatIsWrongWithSignoff => 'What is wrong with this sign-off?';

  @override
  String get spotCheckSaved => 'Spot check saved.';

  @override
  String get areaOverview => 'Area overview';

  @override
  String outletsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outlets',
      one: '1 outlet',
    );
    return '$_temp0';
  }

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get checklistsOnTime => 'Checklists on time';

  @override
  String get lateEscalated => 'Late issues, escalated';

  @override
  String get trainingOnSchedule => 'Training on schedule';

  @override
  String get byOutlet => 'By outlet';

  @override
  String get escalatedToYou => 'Escalated to you';

  @override
  String openIssuesN(int count) {
    return '$count open issues';
  }

  @override
  String lateN(int count) {
    return '$count late';
  }

  @override
  String get trainingOnScheduleShort => 'Training on schedule';

  @override
  String traineesBehindN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trainees behind',
      one: '1 trainee behind',
    );
    return '$_temp0';
  }

  @override
  String get noAuditYet => 'No audit yet';

  @override
  String lastAuditDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last audit $days days ago',
      one: 'Last audit yesterday',
      zero: 'Audited today',
    );
    return '$_temp0';
  }

  @override
  String get visitAudits => 'Visit audits';

  @override
  String get auditsExplainer => 'Findings become issues for the outlet';

  @override
  String get noAuditsYet =>
      'No audits yet. Start one when you visit an outlet.';

  @override
  String get noAuditForms => 'HQ has not published an audit form yet.';

  @override
  String get auditForm => 'Audit form';

  @override
  String auditScore(String score, String date) {
    return 'Score $score · $date';
  }

  @override
  String inProgressSince(String date) {
    return 'In progress since $date';
  }

  @override
  String findingsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count findings',
      one: '1 finding',
    );
    return '$_temp0';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String notificationsUnread(int count) {
    return 'Notifications, $count new';
  }
}
