/// API sunucusunun adresi.
///
/// - Android emülatörü, geliştirme bilgisayarının localhost'una
///   10.0.2.2 üzerinden erişir — bu yüzden varsayılan bu.
/// - Gerçek bir Android/iOS cihazda test ederken bilgisayarının yerel
///   ağ IP'sini kullanman gerekir (örn. http://192.168.1.34:8000/api),
///   telefonun aynı Wi-Fi ağında olduğundan emin ol.
/// - iOS simülatöründe 'localhost' doğrudan çalışır.
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
