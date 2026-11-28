// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Batal';

  @override
  String get retry => 'Coba lagi';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String get done => 'Selesai';

  @override
  String get submit => 'Kirim';

  @override
  String get open => 'Buka';

  @override
  String get openAgain => 'Buka lagi';

  @override
  String get dismiss => 'Tutup';

  @override
  String get someone => 'Seseorang';

  @override
  String get system => 'Sistem';

  @override
  String get somethingWentWrong => 'Terjadi kesalahan. Coba lagi.';

  @override
  String get status => 'Status';

  @override
  String get due => 'Tenggat';

  @override
  String get submitted => 'Dikirim';

  @override
  String get result => 'Hasil';

  @override
  String get location => 'Lokasi';

  @override
  String get progress => 'Progres';

  @override
  String get source => 'Sumber';

  @override
  String get deadline => 'Tenggat';

  @override
  String get owner => 'Penanggung jawab';

  @override
  String get outlet => 'Outlet';

  @override
  String get outlets => 'Outlet';

  @override
  String get offline => 'Offline';

  @override
  String get language => 'Bahasa';

  @override
  String get later => 'Nanti';

  @override
  String get video => 'Video';

  @override
  String get document => 'Dokumen';

  @override
  String get read => 'Dibaca';

  @override
  String get watch => 'Tonton';

  @override
  String get review => 'Tinjau';

  @override
  String get comment => 'Komentar';

  @override
  String get feedback => 'Masukan';

  @override
  String get goals => 'Target';

  @override
  String get training => 'Pelatihan';

  @override
  String get team => 'Tim';

  @override
  String get today => 'Hari ini';

  @override
  String get learn => 'Belajar';

  @override
  String get mentor => 'Mentor';

  @override
  String get issues => 'Masalah';

  @override
  String get issue => 'Masalah';

  @override
  String get audits => 'Audit';

  @override
  String get me => 'Saya';

  @override
  String get removePhoto => 'Hapus foto';

  @override
  String get playVideo => 'Putar video';

  @override
  String get pauseVideo => 'Jeda video';

  @override
  String get fullScreen => 'Layar penuh';

  @override
  String get exitFullScreen => 'Keluar layar penuh';

  @override
  String get videoProcessing =>
      'Video masih diproses. Coba lagi sebentar lagi.';

  @override
  String get needConnectionToSend =>
      'Perlu koneksi internet untuk mengirim ini.';

  @override
  String get useAdminWeb =>
      'Peran Anda bekerja di web admin ASAH. Buka di komputer.';

  @override
  String get signInHeadline => 'Belajar benar.\nKerja benar. Setiap shift.';

  @override
  String get signIn => 'Masuk';

  @override
  String get signInSub => 'Gunakan nomor HP yang didaftarkan outlet Anda.';

  @override
  String get phoneNumber => 'Nomor HP';

  @override
  String get sendCode => 'Kirim kode';

  @override
  String get noAccount =>
      'Belum punya akun? Minta manajer outlet untuk menambahkan Anda.';

  @override
  String get changeNumber => 'Ganti nomor';

  @override
  String get enterCode => 'Masukkan 6 digit kode';

  @override
  String sentTo(String phone) {
    return 'Dikirim lewat SMS ke $phone';
  }

  @override
  String resendIn(int seconds) {
    return 'Kirim ulang kode dalam $seconds dtk';
  }

  @override
  String get resendCode => 'Kirim ulang kode';

  @override
  String get verifyAndContinue => 'Verifikasi dan lanjut';

  @override
  String get wrongCode => 'Kode salah. Periksa lalu coba lagi.';

  @override
  String get phoneNotRegistered =>
      'Nomor ini belum terdaftar. Minta manajer outlet untuk menambahkan Anda.';

  @override
  String get accountNotReady => 'Akun Anda belum siap';

  @override
  String get accountNotReadyBody =>
      'Akun Anda belum punya profil atau tidak aktif. Minta manajer outlet atau HQ untuk mengaturnya.';

  @override
  String get signOut => 'Keluar';

  @override
  String get signOutQ => 'Keluar?';

  @override
  String signOutUnsynced(int count) {
    return '$count data belum tersinkron dan akan hilang.';
  }

  @override
  String hiName(String name) {
    return 'Halo, $name';
  }

  @override
  String get todaysTasks => 'Tugas hari ini';

  @override
  String doneOfTotal(int done, int total) {
    return '$done dari $total selesai';
  }

  @override
  String get noTasksToday => 'Tidak ada checklist untuk Anda hari ini.';

  @override
  String get myLearning => 'Belajar saya';

  @override
  String get myPath => 'Jalur saya';

  @override
  String get yourMentor => 'Mentor Anda';

  @override
  String get weeklyCheckinWithMentor => 'Check-in mingguan dengan mentor';

  @override
  String dayN(int n) {
    return 'Hari ke-$n';
  }

  @override
  String get shiftOpening => 'Shift buka';

  @override
  String get shiftMid => 'Shift siang';

  @override
  String get shiftClosing => 'Shift tutup';

  @override
  String get shiftOther => 'Kapan saja';

  @override
  String dueAt(String time) {
    return 'Tenggat $time';
  }

  @override
  String lateDue(String time) {
    return 'Terlambat · tenggat $time';
  }

  @override
  String get doneLate => 'Selesai terlambat';

  @override
  String get missed => 'Terlewat';

  @override
  String itemsCount(int count) {
    return '$count item';
  }

  @override
  String needPhotoCount(int count) {
    return '$count perlu foto';
  }

  @override
  String startedCount(int count) {
    return '$count dijawab';
  }

  @override
  String submittedAtTime(String time) {
    return 'Dikirim $time';
  }

  @override
  String get startChecklist => 'Mulai checklist';

  @override
  String get continueChecklist => 'Lanjutkan';

  @override
  String get startAudit => 'Mulai audit';

  @override
  String get waitingToSync =>
      'Sudah dikirim di HP ini. Akan tersinkron saat online.';

  @override
  String get waitingToSyncShort => 'Menunggu sinkron';

  @override
  String itemsWaitingToSync(int count) {
    return '$count data menunggu sinkron';
  }

  @override
  String syncFailed(String label, String error) {
    return '$label gagal dikirim: $error';
  }

  @override
  String get syncNow => 'Sinkron sekarang';

  @override
  String doneOfDue(int done, int total, String time) {
    return '$done dari $total selesai · Tenggat $time';
  }

  @override
  String get offlineAnswersSaved =>
      'Offline. Jawaban tersimpan dan tersinkron saat online.';

  @override
  String get photoRequired => 'Wajib foto';

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get addAnotherPhoto => 'Tambah foto';

  @override
  String get inAppCameraOnly => 'Hanya kamera aplikasi';

  @override
  String get inAppCamera => 'kamera aplikasi';

  @override
  String get raisesIssue =>
      'Ini akan membuat laporan masalah untuk manajer outlet.';

  @override
  String get outOfRangeRaisesIssue =>
      'Di luar batas. Ini akan membuat laporan masalah untuk manajer outlet.';

  @override
  String allowedRange(String min, String max, String unit) {
    return 'Batas $min sampai $max $unit';
  }

  @override
  String allowedMin(String min, String unit) {
    return 'Minimal $min $unit';
  }

  @override
  String allowedMax(String max, String unit) {
    return 'Maksimal $max $unit';
  }

  @override
  String get writeANote => 'Tulis catatan';

  @override
  String timeLocationAdded(String outlet) {
    return '$outlet · waktu dan lokasi ditambahkan saat kirim';
  }

  @override
  String submitRaisesIssues(int count) {
    return 'Kirim · membuat $count masalah';
  }

  @override
  String itemsStillMissing(int count) {
    return '$count item masih perlu jawaban atau foto.';
  }

  @override
  String get locationOff =>
      'Nyalakan lokasi untuk mengirim. Checklist dicatat dengan lokasi pengisian.';

  @override
  String get locationDenied =>
      'ASAH perlu akses lokasi untuk mengirim checklist. Izinkan di Pengaturan.';

  @override
  String get outsideOutletTitle => 'Sepertinya Anda di luar outlet';

  @override
  String outsideOutletBody(String outlet, int meters) {
    return 'Anda sekitar $meters m dari $outlet. Checklist hanya bisa dikirim di area outlet.';
  }

  @override
  String get submitAnyway => 'Coba saja';

  @override
  String get savedOfflineWillSync => 'Tersimpan. Akan dikirim saat online.';

  @override
  String get submittedThanks => 'Terkirim. Terima kasih!';

  @override
  String submittedWithIssues(int count) {
    return 'Terkirim. $count masalah dikirim ke manajer outlet.';
  }

  @override
  String get submittedLate => 'Dikirim terlambat';

  @override
  String get submittedOnTime => 'Dikirim tepat waktu';

  @override
  String get late => 'Terlambat';

  @override
  String get notDoneYet => 'Belum selesai';

  @override
  String passedOf(int passed, int total) {
    return '$passed dari $total lulus';
  }

  @override
  String get insideOutlet => 'Di dalam outlet';

  @override
  String get outsideOutlet => 'Di luar outlet';

  @override
  String get runMissedInfo =>
      'Checklist ini tidak dikerjakan sebelum tenggat. Manajer outlet sudah diberi tahu.';

  @override
  String get runNotSubmittedYet => 'Belum dikirim.';

  @override
  String get failedRaisedIssue => 'Gagal · masalah dibuat';

  @override
  String photoCount(int count) {
    return '$count foto';
  }

  @override
  String get noModulesYet => 'Belum ada modul.';

  @override
  String get assignedToYou => 'Ditugaskan untuk Anda';

  @override
  String get day1 => 'Hari pertama';

  @override
  String get week1 => 'Minggu pertama';

  @override
  String get month1 => 'Bulan pertama';

  @override
  String get upNext => 'Berikutnya';

  @override
  String upNextModuleOf(int n, int total) {
    return 'Berikutnya · Modul $n dari $total';
  }

  @override
  String get pathComplete => 'Jalur selesai. Kerja bagus!';

  @override
  String minutesShort(int n) {
    return '$n mnt';
  }

  @override
  String get overdue => 'Lewat tenggat';

  @override
  String get refresher => 'Penyegaran';

  @override
  String get updated => 'Diperbarui';

  @override
  String dueDate(String date) {
    return 'Tenggat $date';
  }

  @override
  String moduleOfPath(int n, int total, String path) {
    return 'Modul $n dari $total · $path';
  }

  @override
  String get moduleCompleted => 'Anda sudah menyelesaikan modul ini.';

  @override
  String get moduleCompletedCertificate =>
      'Modul selesai. Sertifikat ada di Saya › Sertifikat.';

  @override
  String get markWatched => 'Tandai ditonton';

  @override
  String get markAsRead => 'Tandai sudah dibaca';

  @override
  String get sopCard => 'Kartu SOP';

  @override
  String get quiz => 'Kuis';

  @override
  String quizPassMark(int pct) {
    return 'Kuis · nilai lulus $pct%';
  }

  @override
  String get passed => 'Lulus';

  @override
  String attemptsLeft(int count) {
    return 'Sisa $count kali';
  }

  @override
  String lastScore(String pct) {
    return 'Nilai terakhir $pct';
  }

  @override
  String get finishLessonsFirst => 'Tips: tonton dan baca materi sebelum kuis.';

  @override
  String get noAttemptsLeft =>
      'Tidak ada kesempatan lagi. Minta mentor untuk penyegaran.';

  @override
  String get startQuiz => 'Mulai kuis';

  @override
  String get retakeQuiz => 'Ulangi kuis';

  @override
  String get practicalTest => 'Tes praktik';

  @override
  String get practicalHowTo =>
      'Rekam diri Anda melakukannya di aplikasi. Mentor menilai setiap poin.';

  @override
  String get practicalWaiting => 'Terkirim. Menunggu penilaian mentor.';

  @override
  String get practicalPassed => 'Mentor meluluskan tes praktik Anda.';

  @override
  String get practicalRedo =>
      'Mentor meminta Anda mengulang. Baca masukan di bawah.';

  @override
  String get pass => 'Lulus';

  @override
  String get redo => 'Ulang';

  @override
  String get mentorFeedback => 'Masukan mentor';

  @override
  String get recordPracticalTest => 'Rekam tes praktik';

  @override
  String get recordAgain => 'Rekam ulang';

  @override
  String get saveForOffline => 'Simpan video untuk offline';

  @override
  String get savedForOffline => 'Tersimpan. Modul ini bisa ditonton offline.';

  @override
  String get downloadPreparing =>
      'Menyiapkan unduhan. Coba lagi sebentar lagi.';

  @override
  String questionOf(int n, int total) {
    return 'Soal $n dari $total';
  }

  @override
  String get previous => 'Kembali';

  @override
  String get nextQuestion => 'Soal berikutnya';

  @override
  String get submitAnswers => 'Kirim jawaban';

  @override
  String get backToModule => 'Kembali ke modul';

  @override
  String get quizHasNoQuestions => 'Kuis ini belum punya soal.';

  @override
  String get quizPassedMessage => 'Anda lulus. Kerja bagus!';

  @override
  String quizFailedMessage(int pct) {
    return 'Belum lulus. Perlu $pct% untuk lulus. Pelajari lagi lalu coba lagi.';
  }

  @override
  String get recordInApp => 'Hanya direkam di aplikasi';

  @override
  String get whatMentorChecks => 'Yang dinilai mentor';

  @override
  String get record => 'Rekam';

  @override
  String get sendToMentor => 'Kirim ke mentor';

  @override
  String get practicalSent => 'Terkirim ke mentor.';

  @override
  String get learningPath => 'Jalur belajar';

  @override
  String get certificates => 'Sertifikat';

  @override
  String get noCertificatesYet =>
      'Belum ada sertifikat. Selesaikan modul untuk mendapatkannya.';

  @override
  String issuedOn(String date) {
    return 'Terbit $date';
  }

  @override
  String validUntil(String date) {
    return 'Berlaku sampai $date';
  }

  @override
  String get expired => 'Kedaluwarsa';

  @override
  String get expiresSoon => 'Segera berakhir';

  @override
  String get myTrainees => 'Trainee saya';

  @override
  String get noTraineesYet =>
      'Belum ada trainee. Manajer outlet yang menugaskan.';

  @override
  String get toDo => 'Yang perlu dikerjakan';

  @override
  String get scorePracticalTest => 'Nilai tes praktik';

  @override
  String get weeklyCheckinDue => 'Check-in mingguan';

  @override
  String get thisWeek => 'minggu ini';

  @override
  String get behind => 'Tertinggal';

  @override
  String get onTrack => 'Sesuai jadwal';

  @override
  String get failedQuizTwice => 'Gagal kuis dua kali';

  @override
  String pathPct(int pct) {
    return 'Jalur $pct%';
  }

  @override
  String lastQuiz(String pct) {
    return 'Kuis terakhir $pct';
  }

  @override
  String modulesOverdue(int count) {
    return '$count modul lewat tenggat';
  }

  @override
  String myRatingAverage(String avg, int count) {
    return 'Rating saya: $avg dari $count trainee. Rating bersifat anonim.';
  }

  @override
  String myRatingHidden(int count) {
    return 'Rating saya: tampil sebagai rata-rata setelah $count trainee menilai. Rating bersifat anonim.';
  }

  @override
  String get weeklyCheckins => 'Check-in mingguan';

  @override
  String get weeklyCheckin => 'Check-in mingguan';

  @override
  String get logCheckin => 'Catat check-in';

  @override
  String get noCheckinsYet => 'Belum ada check-in.';

  @override
  String get noCheckinsYetTrainee => 'Mentor belum mencatat check-in.';

  @override
  String weekOf(String date) {
    return 'Minggu $date';
  }

  @override
  String get feedbackHint => 'Apa yang sudah baik, apa yang perlu diperbaiki';

  @override
  String get goalsNextWeek => 'Target minggu depan';

  @override
  String get traineeSeesCheckin => 'Trainee bisa membaca check-in ini.';

  @override
  String get saveCheckin => 'Simpan check-in';

  @override
  String get checkinSaved => 'Check-in tersimpan.';

  @override
  String get rubric => 'Rubrik';

  @override
  String get scoreEveryLine => 'Nilai semua poin rubrik dulu.';

  @override
  String get practicalMarkedPassed => 'Lulus. Trainee sudah diberi tahu.';

  @override
  String get practicalAskedRedo =>
      'Diminta mengulang. Trainee sudah diberi tahu.';

  @override
  String get askToRedo => 'Minta ulang';

  @override
  String feedbackFor(String name) {
    return 'Masukan untuk $name';
  }

  @override
  String recordedInApp(String when) {
    return 'Direkam di aplikasi · $when';
  }

  @override
  String get alreadyScored => 'Tes ini sudah dinilai.';

  @override
  String mentorSince(String date) {
    return 'Mentor Anda sejak $date';
  }

  @override
  String get mentorHelpNote =>
      'Tanyakan apa saja tentang pekerjaan ke mentor. Mentor menilai tes praktik dan check-in setiap minggu.';

  @override
  String get rateYourMentor => 'Nilai mentor Anda';

  @override
  String rateMentorPrompt(String name) {
    return 'Beri nilai untuk $name, mentor Anda';
  }

  @override
  String howWasMentor(String name) {
    return 'Bagaimana $name sebagai mentor Anda?';
  }

  @override
  String get commentOptional => 'Komentar (opsional)';

  @override
  String get ratingAnonymousNote =>
      'Mentor hanya melihat rata-rata dari beberapa trainee, tidak pernah nama Anda.';

  @override
  String get sendRating => 'Kirim nilai';

  @override
  String get thanksForRating => 'Terima kasih atas penilaian Anda.';

  @override
  String get raiseIssue => 'Laporkan masalah';

  @override
  String get yourArea => 'Area Anda';

  @override
  String get raisedByOrAssignedToYou => 'Dilaporkan atau ditugaskan ke Anda';

  @override
  String get checkFix => 'Cek perbaikan';

  @override
  String get closed => 'Selesai';

  @override
  String get noIssuesHere => 'Tidak ada.';

  @override
  String get escalated => 'Dieskalasi';

  @override
  String get notAssigned => 'Belum ditugaskan';

  @override
  String get assigned => 'Ditugaskan';

  @override
  String get severityHigh => 'Tinggi';

  @override
  String get severityMedium => 'Sedang';

  @override
  String get severityLow => 'Rendah';

  @override
  String fromChecklist(String name) {
    return 'Dari $name';
  }

  @override
  String fromAudit(String name) {
    return 'Audit · $name';
  }

  @override
  String get raisedByHand => 'Dilaporkan manual';

  @override
  String closedAt(String when) {
    return 'Selesai $when';
  }

  @override
  String fixWaitingForCheck(String time) {
    return 'Diperbaiki $time · menunggu dicek';
  }

  @override
  String lateSince(String when) {
    return 'Terlambat sejak $when';
  }

  @override
  String dueEscalatesAfter(String when) {
    return 'Tenggat $when · dieskalasi ke area manager setelahnya';
  }

  @override
  String get ifLate => 'Jika terlambat';

  @override
  String escalatedAt(String when) {
    return 'Dieskalasi $when';
  }

  @override
  String get escalatesToArea => 'Dieskalasi ke area manager';

  @override
  String get eventRaised => 'Dilaporkan';

  @override
  String get eventAssigned => 'Ditugaskan';

  @override
  String get eventFixed => 'Diperbaiki dengan foto bukti';

  @override
  String get eventAccepted => 'Perbaikan diterima · selesai';

  @override
  String get eventReopened => 'Dibuka lagi';

  @override
  String get eventEscalated => 'Dieskalasi ke area manager';

  @override
  String get eventComment => 'Komentar';

  @override
  String get waitingForManager => 'Menunggu manajer outlet';

  @override
  String get fixedWithProof => 'Diperbaiki dengan foto bukti';

  @override
  String get byTheOwner => 'Oleh penanggung jawab';

  @override
  String get acceptedOrReopened => 'Diterima atau dibuka lagi';

  @override
  String get notTheFixer =>
      'Oleh pelapor atau area manager, bukan yang memperbaiki';

  @override
  String get assignTo => 'Tugaskan ke';

  @override
  String assignedNotified(String name) {
    return 'Ditugaskan ke $name, sudah diberi notifikasi.';
  }

  @override
  String get whatDidYouFix => 'Apa yang diperbaiki?';

  @override
  String get optionalNote => 'Catatan opsional';

  @override
  String get markedFixed => 'Ditandai selesai. Orang lain akan mengeceknya.';

  @override
  String get issueClosedMsg => 'Perbaikan diterima. Masalah selesai.';

  @override
  String get whyReopen => 'Kenapa dibuka lagi?';

  @override
  String get reopenHint => 'Apa yang masih perlu diperbaiki';

  @override
  String get issueReopenedMsg =>
      'Dibuka lagi. Yang memperbaiki sudah diberi tahu.';

  @override
  String get addComment => 'Tambah komentar';

  @override
  String get commentAdded => 'Komentar ditambahkan.';

  @override
  String get assignRefresher => 'Tugaskan modul penyegaran';

  @override
  String get refresherAssigned => 'Modul penyegaran ditugaskan.';

  @override
  String get reopen => 'Buka lagi';

  @override
  String get acceptFix => 'Terima perbaikan';

  @override
  String get assignOwner => 'Tugaskan';

  @override
  String get changeOwner => 'Ganti';

  @override
  String get markFixed => 'Tandai selesai';

  @override
  String get waitingForSomeoneToCheck =>
      'Anda sudah memperbaiki. Orang lain akan mengecek.';

  @override
  String get whatIsWrong => 'Apa masalahnya?';

  @override
  String get whatIsWrongHint => 'mis. Sabun cuci tangan habis';

  @override
  String get detailsOptional => 'Detail (opsional)';

  @override
  String get howUrgent => 'Seberapa mendesak?';

  @override
  String fixWithinHours(int hours) {
    return 'Perbaiki dalam $hours jam, lalu dieskalasi.';
  }

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String get issueRaised => 'Masalah dilaporkan.';

  @override
  String get outletManager => 'Manajer outlet';

  @override
  String outletToday(String name) {
    return '$name · Hari ini';
  }

  @override
  String get noOutletAssigned => 'Belum ada outlet yang ditugaskan.';

  @override
  String get checklistsByShift => 'Checklist per shift';

  @override
  String get noChecklistsScheduledToday => 'Tidak ada checklist hari ini.';

  @override
  String get openIssues => 'Masalah terbuka';

  @override
  String get allIssues => 'Semua masalah';

  @override
  String get noOpenIssues => 'Tidak ada masalah terbuka.';

  @override
  String get checklistsDone => 'Checklist selesai';

  @override
  String get lateChecklists => 'Checklist terlambat';

  @override
  String doneFailedItems(int count) {
    return 'Selesai · $count gagal';
  }

  @override
  String get everyoneOnSchedule => 'Semua sesuai jadwal.';

  @override
  String personBehind(String name) {
    return '$name tertinggal';
  }

  @override
  String mentorName(String name) {
    return 'Mentor: $name';
  }

  @override
  String get myTasks => 'Tugas saya';

  @override
  String mentorsN(int count) {
    return 'mentor $count orang';
  }

  @override
  String signoffsToSpotCheck(int count) {
    return '$count penilaian mentor untuk dicek';
  }

  @override
  String get noMentorYet => 'Belum ada mentor';

  @override
  String sinceDate(String date) {
    return 'sejak $date';
  }

  @override
  String get assignMentor => 'Tugaskan mentor';

  @override
  String get changeMentor => 'Ganti mentor';

  @override
  String get endMentorship => 'Akhiri mentoring';

  @override
  String get endMentorshipQ => 'Akhiri mentoring ini?';

  @override
  String get endMentorshipBody =>
      'Lakukan ini saat trainee menyelesaikan jalurnya. Trainee lalu bisa menilai mentor.';

  @override
  String get mentorshipEnded => 'Mentoring diakhiri.';

  @override
  String get assignModule => 'Tugaskan modul';

  @override
  String get moduleAssigned => 'Modul ditugaskan.';

  @override
  String get pickMentor => 'Pilih mentor';

  @override
  String get mentorRulesNote =>
      'Mentor perlu peran Mentor, level minimum, jalur sendiri selesai, dan masih ada slot trainee. ASAH akan mengecek.';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String mentorAssigned(String name) {
    return '$name sekarang menjadi mentor.';
  }

  @override
  String get mentorSignoffs => 'Penilaian mentor';

  @override
  String get spotCheckExplainer =>
      'Cek sebagian tes praktik yang dinilai mentor. Tonton videonya lalu nyatakan setuju atau tidak.';

  @override
  String scoredByOn(String name, String when) {
    return 'Dinilai $name · $when';
  }

  @override
  String get spotChecked => 'Sudah dicek';

  @override
  String get agree => 'Setuju';

  @override
  String get disagree => 'Tidak setuju';

  @override
  String get whatIsWrongWithSignoff => 'Apa yang salah dengan penilaian ini?';

  @override
  String get spotCheckSaved => 'Pengecekan tersimpan.';

  @override
  String get areaOverview => 'Ringkasan area';

  @override
  String outletsN(int count) {
    return '$count outlet';
  }

  @override
  String get last7Days => '7 hari terakhir';

  @override
  String get checklistsOnTime => 'Checklist tepat waktu';

  @override
  String get lateEscalated => 'Masalah terlambat, dieskalasi';

  @override
  String get trainingOnSchedule => 'Pelatihan sesuai jadwal';

  @override
  String get byOutlet => 'Per outlet';

  @override
  String get escalatedToYou => 'Dieskalasi ke Anda';

  @override
  String openIssuesN(int count) {
    return '$count masalah terbuka';
  }

  @override
  String lateN(int count) {
    return '$count terlambat';
  }

  @override
  String get trainingOnScheduleShort => 'Pelatihan sesuai jadwal';

  @override
  String traineesBehindN(int count) {
    return '$count trainee tertinggal';
  }

  @override
  String get noAuditYet => 'Belum diaudit';

  @override
  String lastAuditDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Audit terakhir $days hari lalu',
      zero: 'Diaudit hari ini',
    );
    return '$_temp0';
  }

  @override
  String get visitAudits => 'Audit kunjungan';

  @override
  String get auditsExplainer => 'Temuan menjadi masalah untuk outlet';

  @override
  String get noAuditsYet =>
      'Belum ada audit. Mulai saat Anda berkunjung ke outlet.';

  @override
  String get noAuditForms => 'HQ belum menerbitkan formulir audit.';

  @override
  String get auditForm => 'Formulir audit';

  @override
  String auditScore(String score, String date) {
    return 'Skor $score · $date';
  }

  @override
  String inProgressSince(String date) {
    return 'Berjalan sejak $date';
  }

  @override
  String findingsN(int count) {
    return '$count temuan';
  }

  @override
  String get notifications => 'Notifikasi';

  @override
  String get markAllRead => 'Tandai semua dibaca';

  @override
  String get noNotifications => 'Belum ada notifikasi.';

  @override
  String notificationsUnread(int count) {
    return 'Notifikasi, $count baru';
  }

  @override
  String get formalTraining => 'Pelatihan formal';

  @override
  String get formalTrainings => 'Pelatihan formal';

  @override
  String get requestFormalTraining => 'Ajukan pelatihan formal';

  @override
  String get requestShort => 'Ajukan';

  @override
  String formalTrainingIntro(String name) {
    return 'Pelatihan 30 menit langsung di tempat. $name menyetujui waktunya, lalu manajer Anda bisa melihat dan ikut hadir.';
  }

  @override
  String get formalTrainingTopic => 'Topik';

  @override
  String get formalTrainingTopicHint => 'mis. Menyiapkan stasiun grill';

  @override
  String get formalTrainingNote => 'Catatan (opsional)';

  @override
  String get pickDate => 'Tanggal';

  @override
  String get pickTime => 'Jam';

  @override
  String get pickFutureTime => 'Pilih waktu yang akan datang.';

  @override
  String get sendRequest => 'Kirim permintaan';

  @override
  String formalTrainingRequestSent(String name) {
    return 'Permintaan dikirim ke $name';
  }

  @override
  String get noFormalTrainings => 'Belum ada pelatihan formal.';

  @override
  String ftWaitingFor(String name) {
    return 'Menunggu $name';
  }

  @override
  String get ftWaitingForYou => 'Menunggu Anda';

  @override
  String get ftScheduled => 'Terjadwal';

  @override
  String get ftHeld => 'Selesai';

  @override
  String get ftDeclined => 'Ditolak';

  @override
  String get ftCancelled => 'Dibatalkan';

  @override
  String get ftExpired => 'Kedaluwarsa';

  @override
  String get approve => 'Setujui';

  @override
  String get decline => 'Tolak';

  @override
  String get declineFormalTraining => 'Tolak permintaan ini?';

  @override
  String get reasonOptional => 'Alasan (opsional)';

  @override
  String get cancelFormalTraining => 'Batalkan pelatihan';

  @override
  String cancelFormalTrainingConfirm(String name) {
    return 'Batalkan pelatihan formal ini? $name akan diberi tahu.';
  }

  @override
  String get formalTrainingApproved => 'Pelatihan formal dijadwalkan';

  @override
  String get formalTrainingDeclined => 'Permintaan ditolak';

  @override
  String get formalTrainingCancelled => 'Pelatihan formal dibatalkan';

  @override
  String requestedByName(String name) {
    return 'Diajukan oleh $name';
  }

  @override
  String mentorWithTrainee(String mentor, String trainee) {
    return '$mentor dengan $trainee';
  }

  @override
  String formalTrainingRequestTitle(String name) {
    return '$name mengajukan pelatihan formal';
  }

  @override
  String get managersCanJoin =>
      'Setelah disetujui, manajer outlet dan area bisa melihat sesi ini dan mungkin ikut hadir.';

  @override
  String get managersCanJoinScheduled =>
      'Manajer outlet dan area bisa melihat sesi ini dan mungkin ikut hadir.';

  @override
  String get formalTrainingsScheduled => 'Pelatihan formal terjadwal';

  @override
  String get reply => 'Balasan';

  @override
  String get youLabel => 'Anda';
}
