import '../language_keys.dart';

abstract final class In {
  static const values = <String, String>{
    LanguageKeys.appName: 'Servify',
    LanguageKeys.language: 'Bahasa',
    LanguageKeys.languageDescription: 'Pilih bahasa aplikasi',
    LanguageKeys.indonesian: 'Indonesia',
    LanguageKeys.english: 'Inggris',
    LanguageKeys.cancel: 'Batal',
    LanguageKeys.delete: 'Hapus',
    LanguageKeys.retry: 'Coba lagi',
    LanguageKeys.email: 'Email',
    LanguageKeys.password: 'Password',
    LanguageKeys.showPassword: 'Tampilkan password',
    LanguageKeys.hidePassword: 'Sembunyikan password',
    LanguageKeys.fullName: 'Nama lengkap',
    LanguageKeys.phoneNumber: 'Nomor telepon',
    LanguageKeys.customer: 'Customer',
    LanguageKeys.home: 'Beranda',
    LanguageKeys.orders: 'Pesanan',
    LanguageKeys.favorites: 'Favorit',
    LanguageKeys.profile: 'Profil',
    LanguageKeys.notifications: 'Notifikasi',
    LanguageKeys.logout: 'Keluar',
    LanguageKeys.scan: 'SCAN',
    LanguageKeys.scanQr: 'Scan QR',
    LanguageKeys.seeAll: 'Lihat semua',
    LanguageKeys.all: 'Semua',
    LanguageKeys.ongoing: 'Berjalan',
    LanguageKeys.completed: 'Selesai',
    LanguageKeys.skip: 'Lewati',
    LanguageKeys.next: 'Selanjutnya',
    LanguageKeys.startNow: 'Mulai sekarang',
    LanguageKeys.onboardingFindTitle: 'Temukan layanan tepercaya',
    LanguageKeys.onboardingFindDescription:
        'Pilih layanan terbaik sesuai kebutuhan Anda dengan proses yang mudah.',
    LanguageKeys.onboardingBookTitle: 'Atur pesanan dengan cepat',
    LanguageKeys.onboardingBookDescription:
        'Tentukan jadwal, isi detail kebutuhan, lalu konfirmasi pesanan Anda.',
    LanguageKeys.onboardingTrackTitle: 'Pantau secara realtime',
    LanguageKeys.onboardingTrackDescription:
        'Dapatkan pembaruan status sejak pesanan diterima hingga selesai.',
    LanguageKeys.welcomeBack: 'Selamat datang kembali',
    LanguageKeys.loginSubtitle:
        'Masuk untuk memesan dan memantau layanan Anda.',
    LanguageKeys.login: 'Masuk',
    LanguageKeys.loginFailed: 'Login gagal.',
    LanguageKeys.noAccount: 'Belum punya akun?',
    LanguageKeys.register: 'Daftar',
    LanguageKeys.createCustomerAccount: 'Buat akun customer',
    LanguageKeys.registerSubtitle:
        'Daftar untuk menemukan layanan yang Anda butuhkan.',
    LanguageKeys.createAccount: 'Buat akun',
    LanguageKeys.accountCreated: 'Akun berhasil dibuat.',
    LanguageKeys.accountCreatedConfirmEmail:
        'Akun dibuat. Silakan konfirmasi email sebelum masuk.',
    LanguageKeys.registerFailed: 'Pendaftaran gagal. Silakan coba lagi.',
    LanguageKeys.alreadyHaveAccount: 'Sudah punya akun?',
    LanguageKeys.generalError: 'Terjadi kesalahan. Silakan coba lagi.',
    LanguageKeys.logoutFailed: 'Gagal keluar dari akun.',
    LanguageKeys.fieldRequired: '{field} wajib diisi.',
    LanguageKeys.invalidEmail: 'Format email tidak valid.',
    LanguageKeys.minimumPassword: 'Password minimal 8 karakter.',
    LanguageKeys.continueWithGoogle: 'Lanjutkan dengan Google',
    LanguageKeys.orContinueWith: 'atau lanjutkan dengan',
    LanguageKeys.googleAuthOpened:
        'Login Google dibuka. Selesaikan prosesnya di browser.',
    LanguageKeys.googleSignInFailed:
        'Login Google gagal dibuka. Silakan coba kembali.',
    LanguageKeys.greeting: 'Halo, {name}!',
    LanguageKeys.homeQuestion: 'Layanan apa yang Anda butuhkan hari ini?',
    LanguageKeys.searchService: 'Cari layanan',
    LanguageKeys.easierBooking: 'Pesan lebih mudah',
    LanguageKeys.easierBookingDescription:
        'Pilih layanan, tentukan jadwal, dan pantau statusnya.',
    LanguageKeys.serviceCategories: 'Kategori layanan',
    LanguageKeys.trustedCategoryService: 'Layanan {category} terpercaya',
    LanguageKeys.categoryLoadFailed: 'Kategori layanan gagal dimuat.',
    LanguageKeys.categoryEmpty: 'Belum ada kategori layanan aktif di database.',
    LanguageKeys.scanComingSoon:
        'Fitur Scan QR akan ditambahkan pada tahap berikutnya.',
    LanguageKeys.pageComingSoon:
        'Halaman {page} akan ditambahkan pada tahap berikutnya.',
    LanguageKeys.askServifyAi: 'Tanya Servify AI',
    LanguageKeys.aiHomeDescription:
        'Ceritakan kebutuhan Anda dan dapatkan saran layanan',
    LanguageKeys.aiAssistant: 'Servify AI',
    LanguageKeys.aiAssistantSubtitle:
        'Temukan layanan yang sesuai melalui percakapan sederhana',
    LanguageKeys.aiWelcomeTitle: 'Ada yang bisa saya bantu?',
    LanguageKeys.aiWelcomeDescription:
        'Ceritakan kebutuhan Anda. Saya akan membantu menentukan kategori layanan yang relevan.',
    LanguageKeys.aiPromptHint: 'Ceritakan layanan yang Anda butuhkan...',
    LanguageKeys.aiPromptExample:
        'AC saya tidak dingin dan mengeluarkan suara keras.',
    LanguageKeys.aiThinking: 'Servify AI sedang menyiapkan jawaban...',
    LanguageKeys.aiResponseLabel: 'Jawaban Servify AI',
    LanguageKeys.aiSend: 'Kirim pertanyaan',
    LanguageKeys.aiEmptyPrompt: 'Ceritakan kebutuhan Anda sebelum mengirim.',
    LanguageKeys.aiRequestFailed:
        'Servify AI belum dapat menjawab. Periksa koneksi lalu coba lagi.',
    LanguageKeys.aiRequestTimedOut:
        'Respons Servify AI terlalu lama. Periksa koneksi lalu coba lagi.',
    LanguageKeys.aiRetry: 'Coba lagi',
    LanguageKeys.aiDisclaimer:
        'Saran AI mungkin tidak akurat. Konfirmasi detail layanan sebelum memesan.',
    LanguageKeys.serviceList: 'Daftar layanan',
    LanguageKeys.servicePageSubtitle:
        'Pilih bantuan tepercaya untuk kebutuhan sehari-hari.',
    LanguageKeys.findService: 'Temukan layanan yang Anda butuhkan',
    LanguageKeys.findServiceDescription:
        'Pilih tenaga profesional untuk membantu kebutuhan rumah Anda.',
    LanguageKeys.serviceResults: 'Layanan tersedia',
    LanguageKeys.serviceResultCount: '{count} ditemukan',
    LanguageKeys.clearSearch: 'Hapus pencarian',
    LanguageKeys.clearFilters: 'Hapus filter',
    LanguageKeys.reloadCategories: 'Muat ulang kategori',
    LanguageKeys.reloadServices: 'Muat ulang layanan',
    LanguageKeys.serviceLoadFailed: 'Daftar layanan gagal dimuat.',
    LanguageKeys.serviceNotFound: 'Layanan tidak ditemukan.',
    LanguageKeys.serviceNotFoundDescription:
        'Coba kata kunci lain atau hapus filter yang dipilih.',
    LanguageKeys.favoriteEmptyTitle: 'Belum ada layanan favorit',
    LanguageKeys.favoriteEmptyDescription:
        'Tekan ikon hati pada layanan yang ingin Anda simpan.',
    LanguageKeys.exploreServices: 'Jelajahi layanan',
    LanguageKeys.addFavorite: 'Tambahkan ke favorit',
    LanguageKeys.removeFavorite: 'Hapus dari favorit',
    LanguageKeys.favoritePageSubtitle:
        'Simpan layanan pilihan agar lebih mudah ditemukan kembali.',
    LanguageKeys.favoriteSavedCount: '{count} layanan tersimpan',
    LanguageKeys.favoriteCollection: 'Koleksi favorit',
    LanguageKeys.favoriteCollectionDescription:
        'Pilih layanan untuk melihat detail atau membuat pesanan.',
    LanguageKeys.favoriteRemoved: '{name} dihapus dari favorit.',
    LanguageKeys.undo: 'Urungkan',
    LanguageKeys.startingAt: 'Mulai {price}',
    LanguageKeys.serviceDetail: 'Detail layanan',
    LanguageKeys.serviceDetailSubtitle:
        'Pelajari detail layanan sebelum membuat pesanan.',
    LanguageKeys.reviewsAndEstimate: '{reviews} ulasan • Estimasi {duration}',
    LanguageKeys.reviewCount: '{count} ulasan',
    LanguageKeys.estimatedTime: 'Estimasi waktu',
    LanguageKeys.aboutThisService: 'Tentang layanan ini',
    LanguageKeys.trustedService: 'Layanan tepercaya',
    LanguageKeys.trustedServiceDescription:
        'Pesanan ditangani staf terverifikasi dan dapat dipantau melalui aplikasi.',
    LanguageKeys.similarServices: 'Layanan serupa',
    LanguageKeys.similarServicesDescription:
        'Pilihan lain dari kategori yang sama.',
    LanguageKeys.startingPrice: 'Harga mulai',
    LanguageKeys.whatYouGet: 'Yang Anda dapatkan',
    LanguageKeys.bookNow: 'Pesan sekarang',
    LanguageKeys.day: '{count} hari',
    LanguageKeys.hour: '{count} jam',
    LanguageKeys.minute: '{count} menit',
    LanguageKeys.bookingForm: 'Form pemesanan',
    LanguageKeys.bookingFormSubtitle:
        'Lengkapi informasi dan pilih jadwal layanan Anda.',
    LanguageKeys.bookingCreateFailed:
        'Pesanan gagal dibuat. Silakan coba kembali.',
    LanguageKeys.manageAddresses: 'Kelola alamat',
    LanguageKeys.addSavedAddress: 'Tambah alamat tersimpan',
    LanguageKeys.customerInformation: 'Informasi customer',
    LanguageKeys.whatsappNumber: 'Nomor WhatsApp',
    LanguageKeys.phoneExample: 'Contoh: 08123456789',
    LanguageKeys.invalidWhatsapp: 'Nomor WhatsApp belum valid.',
    LanguageKeys.serviceAddress: 'Alamat layanan',
    LanguageKeys.serviceAddressHint:
        'Masukkan alamat lengkap dan petunjuk lokasi',
    LanguageKeys.serviceSchedule: 'Jadwal layanan',
    LanguageKeys.date: 'Tanggal',
    LanguageKeys.selectServiceDate: 'Pilih tanggal layanan',
    LanguageKeys.paymentAndNotes: 'Pembayaran dan catatan',
    LanguageKeys.paymentMethod: 'Metode pembayaran',
    LanguageKeys.cash: 'Tunai',
    LanguageKeys.bankTransfer: 'Transfer bank',
    LanguageKeys.eWallet: 'E-Wallet',
    LanguageKeys.optionalNotes: 'Catatan (opsional)',
    LanguageKeys.optionalNotesHint:
        'Tambahkan detail yang perlu diketahui penyedia jasa',
    LanguageKeys.reviewOrder: 'Tinjau pesanan',
    LanguageKeys.selectDateFirst: 'Silakan pilih tanggal layanan.',
    LanguageKeys.bookingConfirmation: 'Konfirmasi pesanan',
    LanguageKeys.providerWillContact:
        'Penyedia layanan akan menghubungi Anda untuk memastikan detail pesanan sebelum jadwal dimulai.',
    LanguageKeys.viewOrderHistory: 'Lihat riwayat pesanan',
    LanguageKeys.backToHome: 'Kembali ke beranda',
    LanguageKeys.orderCreated: 'Pesanan berhasil dibuat!',
    LanguageKeys.orderNumber: 'Nomor pesanan {number}',
    LanguageKeys.orderSummary: 'Ringkasan pesanan',
    LanguageKeys.service: 'Layanan',
    LanguageKeys.schedule: 'Jadwal',
    LanguageKeys.address: 'Alamat',
    LanguageKeys.payment: 'Pembayaran',
    LanguageKeys.total: 'Total',
    LanguageKeys.myOrders: 'Pesanan saya',
    LanguageKeys.myOrdersSubtitle:
        'Pantau status dan riwayat pesanan Anda dalam satu tempat.',
    LanguageKeys.awaitingConfirmation: 'Menunggu konfirmasi',
    LanguageKeys.scheduled: 'Terjadwal',
    LanguageKeys.cancelled: 'Dibatalkan',
    LanguageKeys.noOrders: 'Belum ada pesanan pada kategori ini.',
    LanguageKeys.bookingDetail: 'Detail pesanan',
    LanguageKeys.bookingDetailSubtitle:
        'Pantau layanan, jadwal, dan rincian pembayaran Anda.',
    LanguageKeys.staffBookingDetailSubtitle:
        'Tinjau informasi pelanggan dan kelola progres pekerjaan.',
    LanguageKeys.actionSucceeded: 'Aksi berhasil.',
    LanguageKeys.actionFailed: 'Aksi gagal.',
    LanguageKeys.orderNotFound: 'Pesanan tidak ditemukan.',
    LanguageKeys.orderStatus: 'Status pesanan',
    LanguageKeys.invoice: 'Invoice',
    LanguageKeys.orderDate: 'Tanggal pesanan',
    LanguageKeys.serviceDate: 'Jadwal layanan',
    LanguageKeys.statusJourney: 'Perjalanan status',
    LanguageKeys.realtimeActive: 'Pembaruan realtime aktif',
    LanguageKeys.realtimeDisconnected: 'Realtime tidak tersambung',
    LanguageKeys.realtimeConnecting: 'Menghubungkan realtime...',
    LanguageKeys.productDetails: 'Detail produk',
    LanguageKeys.serviceOrderType: 'Jenis pesanan: Layanan jasa',
    LanguageKeys.serviceLocation: 'Alamat layanan',
    LanguageKeys.notes: 'Catatan',
    LanguageKeys.help: 'Bantuan',
    LanguageKeys.chatProvider: 'Chat penyedia jasa',
    LanguageKeys.chatProviderDescription:
        'Tanyakan detail layanan kepada penyedia',
    LanguageKeys.chatComingSoon: 'Fitur chat akan segera tersedia.',
    LanguageKeys.cancelOrder: 'Batalkan pesanan',
    LanguageKeys.cancelOrderDescription:
        'Batalkan sebelum pesanan diterima staf',
    LanguageKeys.helpCenter: 'Cek pusat bantuan',
    LanguageKeys.helpCenterDescription: 'Temukan jawaban dan bantuan lainnya',
    LanguageKeys.helpCenterComingSoon: 'Pusat bantuan akan segera tersedia.',
    LanguageKeys.cancelOrderQuestion: 'Batalkan pesanan?',
    LanguageKeys.cancelOrderWarning:
        'Pesanan yang sudah dibatalkan tidak dapat dipulihkan.',
    LanguageKeys.back: 'Kembali',
    LanguageKeys.workActions: 'Tindakan pekerjaan',
    LanguageKeys.workProof: 'Bukti pekerjaan',
    LanguageKeys.workProofSubtitle:
        'Dokumentasikan kondisi sebelum dan sesudah pekerjaan.',
    LanguageKeys.workProofPhotoCount: '{count} foto tersimpan',
    LanguageKeys.beforeWork: 'Sebelum pekerjaan',
    LanguageKeys.beforeWorkDescription:
        'Catat kondisi lokasi sebelum mulai bekerja',
    LanguageKeys.afterWork: 'Sesudah pekerjaan',
    LanguageKeys.afterWorkDescription:
        'Tunjukkan hasil akhir setelah pekerjaan selesai',
    LanguageKeys.addBeforePhoto: 'Tambah foto sebelum',
    LanguageKeys.addAfterPhoto: 'Tambah foto sesudah',
    LanguageKeys.addWorkProof: 'Tambah bukti pekerjaan',
    LanguageKeys.noWorkProofPhoto: 'Belum ada foto pada bagian ini.',
    LanguageKeys.deletePhoto: 'Hapus foto',
    LanguageKeys.deleteWorkProof: 'Hapus bukti pekerjaan?',
    LanguageKeys.deleteWorkProofConfirmation:
        'Foto ini akan dihapus permanen dan tidak dapat dipulihkan.',
    LanguageKeys.workProofUploaded: 'Bukti pekerjaan berhasil diunggah.',
    LanguageKeys.workProofDeleted: 'Bukti pekerjaan berhasil dihapus.',
    LanguageKeys.workProofActionFailed:
        'Bukti pekerjaan gagal diproses. Silakan coba lagi.',
    LanguageKeys.workProofLoadFailed: 'Bukti pekerjaan gagal dimuat.',
    LanguageKeys.workProofSelectionFailed:
        'Foto gagal dipilih. Periksa izin kamera atau galeri.',
    LanguageKeys.workProofLocked:
        'Foto hanya dapat ditambahkan setelah pesanan diterima dan saat pekerjaan berlangsung.',
    LanguageKeys.reject: 'Tolak',
    LanguageKeys.accept: 'Terima',
    LanguageKeys.leaveForLocation: 'Berangkat ke lokasi',
    LanguageKeys.scanArrivalQr: 'Scan QR kedatangan',
    LanguageKeys.scanCompletionQr: 'Scan QR penyelesaian',
    LanguageKeys.noFurtherAction:
        'Tidak ada tindakan lanjutan untuk pesanan ini.',
    LanguageKeys.qrLocationDisclosure:
        'Saat QR dipindai, Servify akan meminta lokasi perangkat dan mencatat koordinat staf sebagai bukti verifikasi.',
    LanguageKeys.paymentDetails: 'Rincian pembayaran',
    LanguageKeys.servicePrice: 'Harga layanan',
    LanguageKeys.serviceFee: 'Biaya layanan',
    LanguageKeys.totalPayment: 'Total pembayaran',
    LanguageKeys.bookingDetailLoadFailed: 'Detail pesanan gagal dimuat.',
    LanguageKeys.statusPending: 'Menunggu',
    LanguageKeys.statusConfirmed: 'Dikonfirmasi',
    LanguageKeys.statusAssigned: 'Diterima staf',
    LanguageKeys.statusOnTheWay: 'Dalam perjalanan',
    LanguageKeys.statusInProgress: 'Dikerjakan',
    LanguageKeys.qrPurposeArrival: 'kedatangan',
    LanguageKeys.qrPurposeCompletion: 'penyelesaian',
    LanguageKeys.qrVerificationTitle: 'QR verifikasi {purpose}',
    LanguageKeys.qrArrivalInstruction:
        'Tunjukkan QR ini kepada staf setelah staf tiba di lokasi.',
    LanguageKeys.qrCompletionInstruction:
        'Tunjukkan QR setelah Anda memeriksa hasil pekerjaan.',
    LanguageKeys.qrLoadFailed: 'QR gagal dimuat.',
    LanguageKeys.qrExpiresAt: 'Berlaku sampai {date}',
    LanguageKeys.showQr: 'Tampilkan QR {purpose}',
    LanguageKeys.qrSafetyNotice:
        'Jangan kirim tangkapan layar QR kepada orang lain. QR hanya dapat digunakan sekali.',
    LanguageKeys.bookingRejected: 'Pesanan berhasil ditolak.',
    LanguageKeys.bookingAccepted: 'Pesanan berhasil diterima.',
    LanguageKeys.progressUpdated: 'Status pekerjaan berhasil diperbarui.',
    LanguageKeys.bookingCancelled: 'Pesanan berhasil dibatalkan.',
    LanguageKeys.reviewAndRating: 'Review dan rating',
    LanguageKeys.reviewAndRatingDescription:
        'Bagikan pengalaman Anda untuk membantu pelanggan lain.',
    LanguageKeys.yourRating: 'Rating Anda',
    LanguageKeys.ratingRequired: 'Pilih rating terlebih dahulu.',
    LanguageKeys.reviewComment: 'Ulasan (opsional)',
    LanguageKeys.reviewCommentHint:
        'Ceritakan kualitas layanan yang Anda terima',
    LanguageKeys.submitReview: 'Kirim ulasan',
    LanguageKeys.updateReview: 'Perbarui ulasan',
    LanguageKeys.reviewSaved: 'Ulasan berhasil disimpan.',
    LanguageKeys.reviewSubmittedDescription:
        'Terima kasih telah membagikan pengalaman Anda.',
    LanguageKeys.administrator: 'Administrator',
    LanguageKeys.staff: 'Staff',
    LanguageKeys.dashboard: 'Dashboard',
    LanguageKeys.history: 'Riwayat',
    LanguageKeys.active: 'Aktif',
    LanguageKeys.staffDashboard: 'Dashboard Staff',
    LanguageKeys.staffDashboardSubtitle:
        'Kelola pekerjaan dan pantau progres hari ini',
    LanguageKeys.workSummary: 'Ringkasan pekerjaan',
    LanguageKeys.currentAccountActivity: 'Aktivitas akun Anda saat ini',
    LanguageKeys.newLabel: 'Baru',
    LanguageKeys.activeWork: 'Pekerjaan aktif',
    LanguageKeys.activeWorkDescription: 'Pesanan yang sedang Anda tangani',
    LanguageKeys.noActiveWork: 'Belum ada pekerjaan aktif',
    LanguageKeys.noActiveWorkDescription:
        'Terima pesanan masuk untuk mulai mengerjakan layanan.',
    LanguageKeys.workHistory: 'Riwayat Pekerjaan',
    LanguageKeys.workHistoryDescription:
        'Lihat kembali pekerjaan yang telah ditangani',
    LanguageKeys.incomingOrders: 'Pesanan Masuk',
    LanguageKeys.incomingOrdersDescription:
        'Pilih pesanan dan berikan respons dengan cepat',
    LanguageKeys.allHistory: 'Semua riwayat',
    LanguageKeys.orderList: 'Daftar pesanan',
    LanguageKeys.workFound: '{count} pekerjaan ditemukan',
    LanguageKeys.newOrdersWaiting: '{count} pesanan baru menunggu respons',
    LanguageKeys.noWorkHistory: 'Belum ada riwayat pekerjaan',
    LanguageKeys.noIncomingOrders: 'Belum ada pesanan masuk',
    LanguageKeys.completedWorkAppear:
        'Pekerjaan yang selesai akan muncul di halaman ini.',
    LanguageKeys.pullLatestOrders:
        'Tarik ke bawah untuk memeriksa pesanan terbaru.',
    LanguageKeys.noNewOrders: 'Tidak ada pesanan baru',
    LanguageKeys.newOrdersAvailable: '{count} pesanan baru tersedia',
    LanguageKeys.newWorkNotify:
        'Kami akan memberi tahu saat ada pekerjaan baru.',
    LanguageKeys.checkAndTakeWork:
        'Periksa detail dan ambil pekerjaan yang sesuai.',
    LanguageKeys.completedWorkCount: '{count} pekerjaan selesai',
    LanguageKeys.activeOrderCount: '{count} pesanan aktif',
    LanguageKeys.workDocumentation: 'Dokumentasi pekerjaan Anda',
    LanguageKeys.newOrdersAmong: '{count} di antaranya merupakan pesanan baru',
    LanguageKeys.ordersLoadFailed:
        'Pesanan gagal dimuat. Periksa koneksi lalu coba kembali.',
    LanguageKeys.latestDataSyncFailed: 'Data terbaru gagal disinkronkan.',
    LanguageKeys.staffRealtimeDisconnected:
        'Koneksi realtime terputus. Tarik ke bawah untuk memperbarui pesanan.',
    LanguageKeys.newOrderAwaitingResponse:
        'Pesanan baru — menunggu respons Anda',
    LanguageKeys.workValue: 'Nilai pekerjaan',
    LanguageKeys.viewDetails: 'Lihat detail',
    LanguageKeys.staffProfile: 'Profil Staff',
    LanguageKeys.staffProfileSubtitle:
        'Kelola identitas dan pengaturan akun Anda',
    LanguageKeys.staffAccountInformationDescription:
        'Data yang digunakan pada pekerjaan Anda',
    LanguageKeys.staffSettingsDescription:
        'Kelola preferensi dan keamanan akun',
    LanguageKeys.editProfileMenuDescription:
        'Ubah nama lengkap dan nomor telepon',
    LanguageKeys.workNotifications: 'Notifikasi pekerjaan',
    LanguageKeys.workNotificationsDescription:
        'Lihat pembaruan pesanan dan pekerjaan',
    LanguageKeys.staffSecurityDescription: 'Password dan keamanan akses akun',
    LanguageKeys.staffFooter: 'Servify Staff • Akun terhubung dan terlindungi',
    LanguageKeys.logoutQuestion: 'Keluar dari akun?',
    LanguageKeys.staffLogoutWarning:
        'Anda harus masuk kembali untuk menerima dan mengelola pekerjaan.',
    LanguageKeys.staffDefaultName: 'Staff Servify',
    LanguageKeys.verified: 'Terverifikasi',
    LanguageKeys.accountRole: 'Peran akun',
    LanguageKeys.serviceStaff: 'Staff layanan',
    LanguageKeys.editStaffProfile: 'Edit profil staff',
    LanguageKeys.editStaffProfileDescription:
        'Pastikan customer dapat mengenali identitas Anda.',
    LanguageKeys.staffProfileLoadFailed: 'Profil staff gagal dimuat.',
    LanguageKeys.qrVerified: 'QR berhasil diverifikasi.',
    LanguageKeys.invalidQr: 'QR tidak valid.',
    LanguageKeys.scanQrPurpose: 'Scan QR {purpose}',
    LanguageKeys.turnOnFlash: 'Nyalakan lampu',
    LanguageKeys.scanQrInstruction:
        'Arahkan kamera ke QR milik customer. Lokasi perangkat akan dicatat saat QR diverifikasi.',
    LanguageKeys.noNotifications: 'Belum ada notifikasi.',
    LanguageKeys.notificationsPageSubtitle:
        'Pantau perkembangan pesanan dan aktivitas layanan Anda.',
    LanguageKeys.notificationSummaryTitle: 'Pembaruan terbaru Anda',
    LanguageKeys.notificationUnreadSummary:
        '{count} pembaruan belum Anda buka.',
    LanguageKeys.notificationAllReadSummary: 'Semua pembaruan sudah dibaca.',
    LanguageKeys.notificationLatest: 'Notifikasi terbaru',
    LanguageKeys.notificationNew: 'Baru',
    LanguageKeys.notificationEmptyTitle: 'Belum ada pembaruan',
    LanguageKeys.notificationEmptyDescription:
        'Informasi pesanan dan layanan akan muncul di sini.',
    LanguageKeys.notificationLoadFailedTitle: 'Notifikasi gagal dimuat',
    LanguageKeys.notificationLoadFailedDescription:
        'Periksa koneksi Anda, lalu coba kembali.',
    LanguageKeys.editProfile: 'Edit profil',
    LanguageKeys.profilePageSubtitle:
        'Kelola informasi akun dan preferensi aplikasi Anda.',
    LanguageKeys.accountInformation: 'Informasi akun',
    LanguageKeys.notAdded: 'Belum ditambahkan',
    LanguageKeys.settings: 'Pengaturan',
    LanguageKeys.savedAddresses: 'Alamat tersimpan',
    LanguageKeys.savedAddressesDescription: 'Atur alamat rumah atau kantor',
    LanguageKeys.addressManagement: 'Kelola alamat',
    LanguageKeys.addressManagementSubtitle:
        'Simpan lokasi agar proses pemesanan lebih cepat.',
    LanguageKeys.savedAddressCount: '{count} alamat tersimpan',
    LanguageKeys.addAddress: 'Tambah alamat',
    LanguageKeys.editAddress: 'Edit alamat',
    LanguageKeys.deleteAddress: 'Hapus alamat',
    LanguageKeys.deleteAddressTitle: 'Hapus alamat ini?',
    LanguageKeys.deleteAddressConfirmation:
        'Alamat “{label}” akan dihapus secara permanen.',
    LanguageKeys.addressLabel: 'Label alamat',
    LanguageKeys.addressLabelHint: 'Contoh: Rumah atau Kantor',
    LanguageKeys.recipientName: 'Nama penerima',
    LanguageKeys.fullAddress: 'Alamat lengkap',
    LanguageKeys.addressNotes: 'Petunjuk lokasi (opsional)',
    LanguageKeys.addressNotesHint:
        'Warna bangunan, lantai, atau patokan terdekat',
    LanguageKeys.defaultAddress: 'Alamat utama',
    LanguageKeys.makeDefaultAddress: 'Jadikan alamat utama',
    LanguageKeys.makeDefaultAddressDescription:
        'Gunakan alamat ini terlebih dahulu saat membuat pesanan.',
    LanguageKeys.setAsDefaultAddress: 'Jadikan alamat utama',
    LanguageKeys.saveAddress: 'Simpan alamat',
    LanguageKeys.addressFormDescription:
        'Lengkapi informasi agar staf mudah menemukan lokasi.',
    LanguageKeys.addressEmptyTitle: 'Belum ada alamat tersimpan',
    LanguageKeys.addressEmptyDescription:
        'Tambahkan alamat rumah atau kantor agar pemesanan lebih cepat.',
    LanguageKeys.addressLoadFailed:
        'Alamat gagal dimuat. Periksa koneksi lalu coba kembali.',
    LanguageKeys.addressAdded: 'Alamat berhasil ditambahkan.',
    LanguageKeys.addressUpdated: 'Alamat berhasil diperbarui.',
    LanguageKeys.addressSaveFailed:
        'Alamat gagal disimpan. Silakan coba kembali.',
    LanguageKeys.defaultAddressUpdated: 'Alamat utama berhasil diperbarui.',
    LanguageKeys.addressDeleted: 'Alamat berhasil dihapus.',
    LanguageKeys.addressDeleteFailed:
        'Alamat gagal dihapus. Silakan coba kembali.',
    LanguageKeys.moreOptions: 'Pilihan lainnya',
    LanguageKeys.accountSecurity: 'Keamanan akun',
    LanguageKeys.accountSecurityDescription:
        'Ubah password dan pengaturan keamanan',
    LanguageKeys.accountSecurityPageSubtitle:
        'Kelola login, perangkat, dan perlindungan akun Anda.',
    LanguageKeys.accountSecurityLoadFailed:
        'Informasi keamanan akun gagal dimuat.',
    LanguageKeys.accountProtected: 'Perlindungan akun aktif',
    LanguageKeys.accountProtectedDescription:
        'Tinjau metode login dan sesi Anda secara berkala.',
    LanguageKeys.signInAndVerification: 'Login dan verifikasi',
    LanguageKeys.accountEmail: 'Email akun',
    LanguageKeys.emailVerification: 'Verifikasi email',
    LanguageKeys.emailVerified: 'Email terverifikasi',
    LanguageKeys.emailNotVerified: 'Email belum terverifikasi',
    LanguageKeys.signInMethod: 'Metode login',
    LanguageKeys.emailAndPassword: 'Email & password',
    LanguageKeys.passwordAndSessions: 'Password dan sesi',
    LanguageKeys.changePassword: 'Ubah password',
    LanguageKeys.changePasswordDescription:
        'Gunakan minimal 8 karakter yang sulit ditebak.',
    LanguageKeys.changePasswordFormDescription:
        'Password baru akan digunakan pada login berikutnya.',
    LanguageKeys.currentPassword: 'Password saat ini',
    LanguageKeys.currentPasswordRequired: 'Password saat ini wajib diisi.',
    LanguageKeys.newPassword: 'Password baru',
    LanguageKeys.confirmNewPassword: 'Konfirmasi password baru',
    LanguageKeys.passwordsDoNotMatch: 'Konfirmasi password belum sama.',
    LanguageKeys.saveNewPassword: 'Simpan password baru',
    LanguageKeys.passwordChanged: 'Password berhasil diperbarui.',
    LanguageKeys.accountSessions: 'Sesi akun',
    LanguageKeys.accountSessionsDescription:
        'Keluar dari semua perangkat jika ada aktivitas yang tidak dikenali.',
    LanguageKeys.signOutAllDevices: 'Keluar dari semua perangkat',
    LanguageKeys.signOutAllDevicesQuestion: 'Keluar dari semua perangkat?',
    LanguageKeys.signOutAllDevicesWarning:
        'Semua sesi, termasuk perangkat ini, akan dikeluarkan dan harus login kembali.',
    LanguageKeys.signOut: 'Keluar',
    LanguageKeys.allSessionsSignedOut: 'Semua sesi akun berhasil dikeluarkan.',
    LanguageKeys.dangerZone: 'Zona berbahaya',
    LanguageKeys.deleteAccount: 'Hapus akun',
    LanguageKeys.deleteAccountDescription:
        'Menghapus profil, alamat, favorit, dan riwayat akun secara permanen.',
    LanguageKeys.deleteAccountQuestion: 'Hapus akun secara permanen?',
    LanguageKeys.deleteAccountWarning:
        'Tindakan ini tidak dapat dibatalkan. Semua data akun Anda akan dihapus.',
    LanguageKeys.deleteAccountConfirmationWord: 'HAPUS',
    LanguageKeys.typeToConfirm: 'Ketik {word} untuk konfirmasi',
    LanguageKeys.deleteConfirmationInvalid:
        'Ketik kata konfirmasi dengan benar.',
    LanguageKeys.deletePermanently: 'Hapus permanen',
    LanguageKeys.accountDeleted: 'Akun berhasil dihapus.',
    LanguageKeys.securityActionFailed:
        'Tindakan keamanan gagal. Silakan coba kembali.',
    LanguageKeys.logoutAccount: 'Keluar dari akun',
    LanguageKeys.addressComingSoon:
        'Pengelolaan alamat akan ditambahkan pada tahap berikutnya.',
    LanguageKeys.securityComingSoon:
        'Pengaturan keamanan akan ditambahkan pada tahap berikutnya.',
    LanguageKeys.favoriteComingSoon:
        'Halaman Favorit akan ditambahkan pada tahap berikutnya.',
    LanguageKeys.profileLoadFailed:
        'Profil gagal dimuat. Silakan coba kembali.',
    LanguageKeys.profileLoadError: 'Profil tidak dapat dimuat.',
    LanguageKeys.profileUpdated: 'Profil berhasil diperbarui.',
    LanguageKeys.profileUpdateFailed:
        'Profil gagal diperbarui. Silakan coba kembali.',
    LanguageKeys.changeProfilePhoto: 'Ubah foto profil',
    LanguageKeys.chooseFromGallery: 'Pilih dari galeri',
    LanguageKeys.takePhoto: 'Ambil foto',
    LanguageKeys.profilePhotoTooLarge: 'Ukuran foto maksimal 5 MB.',
    LanguageKeys.profilePhotoSelectionFailed:
        'Foto gagal dipilih. Silakan coba kembali.',
    LanguageKeys.profilePhotoUpdated: 'Foto profil berhasil diperbarui.',
    LanguageKeys.profilePhotoUpdateFailed:
        'Foto profil gagal diunggah. Silakan coba kembali.',
    LanguageKeys.editProfileDescription:
        'Perbarui informasi yang digunakan pada pemesanan.',
    LanguageKeys.nameRequired: 'Nama lengkap wajib diisi.',
    LanguageKeys.nameTooLong: 'Nama maksimal 120 karakter.',
    LanguageKeys.invalidPhone: 'Nomor telepon belum valid.',
    LanguageKeys.saveChanges: 'Simpan perubahan',
  };
}
