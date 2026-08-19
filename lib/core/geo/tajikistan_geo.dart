/// Static geographic data for Tajikistan — regions and their cities.
///
/// Used in the address form to provide cascading dropdowns (region → city)
/// so users cannot mistype region or city names.
const Map<String, List<String>> kTajikistanGeo = {
  'Душанбе': ['Душанбе'],
  'Согдийская область': [
    'Худжанд',
    'Истаравшан',
    'Бустон',
    'Гафуров',
    'Канибадам',
    'Пенджикент',
    'Табошар',
    'Шахристон',
    'Айни',
  ],
  'Хатлонская область': [
    'Бохтар',
    'Куляб',
    'Курган-Тюбе',
    'Вахш',
    'Дангара',
    'Мумин-Обод',
    'Пяндж',
    'Шаартуз',
    'Яван',
  ],
  'РРП (Районы республиканского подчинения)': [
    'Турсунзаде',
    'Вахдат',
    'Файзобод',
    'Нурек',
    'Рогун',
    'Рашт',
    'Нурободский район',
    'Варзобский район',
    'Рудаки',
  ],
  'ГБАО': [
    'Хорог',
    'Ишкашим',
    'Мургаб',
    'Рушан',
    'Шугнан',
    'Ванч',
  ],
};

/// Ordered list of region names derived from [kTajikistanGeo].
final List<String> kTajikistanRegions = kTajikistanGeo.keys.toList();
