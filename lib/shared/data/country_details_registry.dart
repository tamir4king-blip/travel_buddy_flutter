/// Sub-items within each country, shown in the country detail page.
class CountryItem {
  final String name;
  final String description;
  final String emoji;
  final double? latitude;
  final double? longitude;

  const CountryItem({
    required this.name,
    required this.description,
    required this.emoji,
    this.latitude,
    this.longitude,
  });
}

class CountryDetail {
  final List<CountryItem> cities;
  final List<CountryItem> landmarks;
  final List<CountryItem> food;
  final List<CountryItem> activities;

  const CountryDetail({
    this.cities = const [],
    this.landmarks = const [],
    this.food = const [],
    this.activities = const [],
  });
}

/// Maps achievement IDs to country detail data.
const countryDetailsRegistry = <String, CountryDetail>{
  // ══════════════════════════════════════════════════
  // FRANCE
  // ══════════════════════════════════════════════════
  'europe-france': CountryDetail(
    cities: [
      CountryItem(name: 'Paris', description: 'The City of Light — art, fashion & the Eiffel Tower', emoji: '\u{1F5FC}', latitude: 48.8566, longitude: 2.3522),
      CountryItem(name: 'Lyon', description: 'Gastronomic capital of France', emoji: '\u{1F372}', latitude: 45.7640, longitude: 4.8357),
      CountryItem(name: 'Nice', description: 'Glamorous jewel of the French Riviera', emoji: '\u{1F3D6}', latitude: 43.7102, longitude: 7.2620),
      CountryItem(name: 'Marseille', description: 'France\'s oldest city and vibrant port', emoji: '\u{26F5}', latitude: 43.2965, longitude: 5.3698),
      CountryItem(name: 'Bordeaux', description: 'World-famous wine region and elegant city', emoji: '\u{1F377}', latitude: 44.8378, longitude: -0.5792),
    ],
    landmarks: [
      CountryItem(name: 'Eiffel Tower', description: 'The iconic iron tower on the Champ de Mars', emoji: '\u{1F5FC}'),
      CountryItem(name: 'Louvre Museum', description: 'World\'s largest art museum, home of the Mona Lisa', emoji: '\u{1F5BC}'),
      CountryItem(name: 'Mont Saint-Michel', description: 'Medieval abbey perched on a tidal island', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Palace of Versailles', description: 'Opulent royal chateau and gardens', emoji: '\u{1F451}'),
    ],
    food: [
      CountryItem(name: 'Croissant', description: 'Flaky, buttery pastry — the quintessential French breakfast', emoji: '\u{1F950}'),
      CountryItem(name: 'Coq au Vin', description: 'Chicken braised in wine with mushrooms & garlic', emoji: '\u{1F357}'),
      CountryItem(name: 'Crème Brûlée', description: 'Rich custard with a caramelized sugar crust', emoji: '\u{1F36E}'),
      CountryItem(name: 'Baguette & Cheese', description: 'Artisan bread with hundreds of regional cheeses', emoji: '\u{1F956}'),
    ],
    activities: [
      CountryItem(name: 'Wine Tasting', description: 'Tour the vineyards of Bordeaux, Burgundy or Champagne', emoji: '\u{1F377}'),
      CountryItem(name: 'Seine River Cruise', description: 'Glide past Parisian landmarks by boat', emoji: '\u{1F6F3}'),
      CountryItem(name: 'Skiing in the Alps', description: 'Hit the slopes in Chamonix or Val d\'Isère', emoji: '\u{26F7}'),
      CountryItem(name: 'Lavender Fields', description: 'Walk through the purple fields of Provence', emoji: '\u{1F33B}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // ITALY
  // ══════════════════════════════════════════════════
  'europe-italy': CountryDetail(
    cities: [
      CountryItem(name: 'Rome', description: 'The Eternal City — millennia of history', emoji: '\u{1F3DB}', latitude: 41.9028, longitude: 12.4964),
      CountryItem(name: 'Florence', description: 'Renaissance art capital of Tuscany', emoji: '\u{1F3A8}', latitude: 43.7696, longitude: 11.2558),
      CountryItem(name: 'Venice', description: 'Floating city of canals and gondolas', emoji: '\u{1F6F6}', latitude: 45.4408, longitude: 12.3155),
      CountryItem(name: 'Milan', description: 'Fashion and design capital of the world', emoji: '\u{1F457}', latitude: 45.4642, longitude: 9.1900),
      CountryItem(name: 'Naples', description: 'Birthplace of pizza, gateway to Pompeii', emoji: '\u{1F355}', latitude: 40.8518, longitude: 14.2681),
    ],
    landmarks: [
      CountryItem(name: 'Colosseum', description: 'Ancient gladiatorial arena of Rome', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Leaning Tower of Pisa', description: 'The famously tilted bell tower', emoji: '\u{1F3D7}'),
      CountryItem(name: 'Amalfi Coast', description: 'Stunning coastal cliffs and colorful villages', emoji: '\u{1F3D6}'),
      CountryItem(name: 'Cinque Terre', description: 'Five picturesque coastal villages', emoji: '\u{1F3E0}'),
    ],
    food: [
      CountryItem(name: 'Pizza Napoletana', description: 'Wood-fired Neapolitan pizza with San Marzano tomatoes', emoji: '\u{1F355}'),
      CountryItem(name: 'Pasta Carbonara', description: 'Creamy Roman pasta with guanciale and pecorino', emoji: '\u{1F35D}'),
      CountryItem(name: 'Gelato', description: 'Italy\'s famous artisan ice cream', emoji: '\u{1F368}'),
      CountryItem(name: 'Risotto', description: 'Creamy Arborio rice dish from northern Italy', emoji: '\u{1F35A}'),
    ],
    activities: [
      CountryItem(name: 'Gondola Ride', description: 'Drift through Venice\'s canals in a gondola', emoji: '\u{1F6F6}'),
      CountryItem(name: 'Vespa Tour', description: 'Explore Tuscan countryside on a classic Vespa', emoji: '\u{1F6F5}'),
      CountryItem(name: 'Cooking Class', description: 'Learn to make pasta from an Italian nonna', emoji: '\u{1F468}\u{200D}\u{1F373}'),
      CountryItem(name: 'Roman Forum Walk', description: 'Walk through the ruins of ancient Rome', emoji: '\u{1F3DB}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // SPAIN
  // ══════════════════════════════════════════════════
  'europe-spain': CountryDetail(
    cities: [
      CountryItem(name: 'Madrid', description: 'Spain\'s grand capital of art and nightlife', emoji: '\u{1F3A8}', latitude: 40.4168, longitude: -3.7038),
      CountryItem(name: 'Barcelona', description: 'Gaudi\'s playground on the Mediterranean', emoji: '\u{26F2}', latitude: 41.3874, longitude: 2.1686),
      CountryItem(name: 'Seville', description: 'Flamenco, tapas, and Moorish palaces', emoji: '\u{1F483}', latitude: 37.3891, longitude: -5.9845),
      CountryItem(name: 'Valencia', description: 'Home of paella and the City of Arts', emoji: '\u{1F958}', latitude: 39.4699, longitude: -0.3763),
      CountryItem(name: 'Granada', description: 'The Alhambra and Andalusian charm', emoji: '\u{1F3F0}', latitude: 37.1773, longitude: -3.5986),
    ],
    landmarks: [
      CountryItem(name: 'Sagrada Familia', description: 'Gaudi\'s unfinished masterpiece in Barcelona', emoji: '\u{26EA}'),
      CountryItem(name: 'Alhambra', description: 'Stunning Moorish palace complex in Granada', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Park Guell', description: 'Gaudi\'s colorful mosaic park', emoji: '\u{1F3A8}'),
      CountryItem(name: 'Plaza de Espana', description: 'Grand semicircular plaza in Seville', emoji: '\u{26F2}'),
    ],
    food: [
      CountryItem(name: 'Paella', description: 'Saffron-infused rice with seafood from Valencia', emoji: '\u{1F958}'),
      CountryItem(name: 'Tapas', description: 'Small plates of endless variety', emoji: '\u{1F372}'),
      CountryItem(name: 'Churros con Chocolate', description: 'Fried dough with thick hot chocolate', emoji: '\u{1F36B}'),
      CountryItem(name: 'Jamon Iberico', description: 'World-famous cured Iberian ham', emoji: '\u{1F356}'),
    ],
    activities: [
      CountryItem(name: 'Flamenco Show', description: 'Watch passionate flamenco in Seville', emoji: '\u{1F483}'),
      CountryItem(name: 'Camino de Santiago', description: 'Walk the ancient pilgrimage route', emoji: '\u{1F6B6}'),
      CountryItem(name: 'Beach Life', description: 'Sun and swim along the Costa Brava', emoji: '\u{1F3D6}'),
      CountryItem(name: 'La Tomatina', description: 'Join the world\'s biggest tomato fight', emoji: '\u{1F345}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // GERMANY
  // ══════════════════════════════════════════════════
  'europe-germany': CountryDetail(
    cities: [
      CountryItem(name: 'Berlin', description: 'History, art, and buzzing nightlife', emoji: '\u{1F3A4}', latitude: 52.5200, longitude: 13.4050),
      CountryItem(name: 'Munich', description: 'Bavarian capital — beer gardens and alpine views', emoji: '\u{1F37A}', latitude: 48.1351, longitude: 11.5820),
      CountryItem(name: 'Hamburg', description: 'Germany\'s gateway to the world', emoji: '\u{26F5}', latitude: 53.5511, longitude: 9.9937),
      CountryItem(name: 'Cologne', description: 'Gothic cathedral and Rhenish culture', emoji: '\u{26EA}', latitude: 50.9375, longitude: 6.9603),
    ],
    landmarks: [
      CountryItem(name: 'Brandenburg Gate', description: 'Iconic neoclassical monument in Berlin', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Neuschwanstein Castle', description: 'Fairytale castle in the Bavarian Alps', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Cologne Cathedral', description: 'Towering Gothic masterpiece', emoji: '\u{26EA}'),
      CountryItem(name: 'Berlin Wall Memorial', description: 'Remnants of the Cold War division', emoji: '\u{1F9F1}'),
    ],
    food: [
      CountryItem(name: 'Bratwurst', description: 'Grilled sausage, the ultimate German street food', emoji: '\u{1F32D}'),
      CountryItem(name: 'Pretzel', description: 'Soft, salty Bavarian pretzel', emoji: '\u{1F968}'),
      CountryItem(name: 'Schnitzel', description: 'Breaded and fried pork or veal cutlet', emoji: '\u{1F356}'),
      CountryItem(name: 'Black Forest Cake', description: 'Chocolate sponge with cherries and cream', emoji: '\u{1F370}'),
    ],
    activities: [
      CountryItem(name: 'Oktoberfest', description: 'The world\'s largest beer festival in Munich', emoji: '\u{1F37A}'),
      CountryItem(name: 'Rhine Cruise', description: 'Sail past castles and vineyards on the Rhine', emoji: '\u{1F6F3}'),
      CountryItem(name: 'Christmas Markets', description: 'Magical winter markets across Germany', emoji: '\u{1F384}'),
      CountryItem(name: 'Black Forest Hiking', description: 'Explore dense forests and waterfalls', emoji: '\u{1F332}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // UNITED KINGDOM
  // ══════════════════════════════════════════════════
  'europe-uk': CountryDetail(
    cities: [
      CountryItem(name: 'London', description: 'Historic capital with world-class museums', emoji: '\u{1F4F7}', latitude: 51.5074, longitude: -0.1278),
      CountryItem(name: 'Edinburgh', description: 'Scotland\'s dramatic castle-topped capital', emoji: '\u{1F3F0}', latitude: 55.9533, longitude: -3.1883),
      CountryItem(name: 'Manchester', description: 'Industrial heritage and music culture', emoji: '\u{1F3B5}', latitude: 53.4808, longitude: -2.2426),
      CountryItem(name: 'Oxford', description: 'Dreaming spires of the ancient university', emoji: '\u{1F393}', latitude: 51.7520, longitude: -1.2577),
    ],
    landmarks: [
      CountryItem(name: 'Big Ben', description: 'Iconic clock tower at the Palace of Westminster', emoji: '\u{1F554}'),
      CountryItem(name: 'Tower of London', description: 'Medieval fortress guarding the crown jewels', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Stonehenge', description: 'Mysterious prehistoric stone circle', emoji: '\u{1FAA8}'),
      CountryItem(name: 'Buckingham Palace', description: 'Official residence of the British monarch', emoji: '\u{1F451}'),
    ],
    food: [
      CountryItem(name: 'Fish and Chips', description: 'Battered fish with thick-cut chips', emoji: '\u{1F35F}'),
      CountryItem(name: 'Full English Breakfast', description: 'Eggs, bacon, sausage, beans, toast & more', emoji: '\u{1F373}'),
      CountryItem(name: 'Afternoon Tea', description: 'Scones, sandwiches and tea service', emoji: '\u{2615}'),
      CountryItem(name: 'Shepherd\'s Pie', description: 'Hearty meat pie topped with mashed potato', emoji: '\u{1F967}'),
    ],
    activities: [
      CountryItem(name: 'West End Show', description: 'Catch a world-class theatre production', emoji: '\u{1F3AD}'),
      CountryItem(name: 'Pub Crawl', description: 'Experience traditional British pub culture', emoji: '\u{1F37B}'),
      CountryItem(name: 'Scottish Highlands', description: 'Road trip through dramatic landscapes', emoji: '\u{1F3DE}'),
      CountryItem(name: 'Premier League Match', description: 'Watch top-flight English football', emoji: '\u{26BD}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // NETHERLANDS
  // ══════════════════════════════════════════════════
  'europe-netherlands': CountryDetail(
    cities: [
      CountryItem(name: 'Amsterdam', description: 'Canal-laced capital with world-class art', emoji: '\u{1F3A8}', latitude: 52.3676, longitude: 4.9041),
      CountryItem(name: 'Rotterdam', description: 'Modern architecture and Europe\'s largest port', emoji: '\u{1F3D7}', latitude: 51.9244, longitude: 4.4777),
      CountryItem(name: 'The Hague', description: 'Seat of government and the World Court', emoji: '\u{2696}', latitude: 52.0705, longitude: 4.3007),
      CountryItem(name: 'Utrecht', description: 'Charming university city with medieval canals', emoji: '\u{26F2}', latitude: 52.0907, longitude: 5.1214),
    ],
    landmarks: [
      CountryItem(name: 'Anne Frank House', description: 'The wartime hiding place, now a powerful museum', emoji: '\u{1F4D6}'),
      CountryItem(name: 'Rijksmuseum', description: 'Home of Rembrandt\'s Night Watch', emoji: '\u{1F5BC}'),
      CountryItem(name: 'Keukenhof Gardens', description: 'Millions of tulips in spring bloom', emoji: '\u{1F337}'),
      CountryItem(name: 'Windmills of Kinderdijk', description: 'UNESCO-listed 18th-century windmills', emoji: '\u{1F3E1}'),
    ],
    food: [
      CountryItem(name: 'Stroopwafel', description: 'Two thin waffles with caramel syrup filling', emoji: '\u{1F9C7}'),
      CountryItem(name: 'Bitterballen', description: 'Crispy fried meat ragout balls', emoji: '\u{1F35E}'),
      CountryItem(name: 'Herring', description: 'Raw herring with onions — a Dutch tradition', emoji: '\u{1F41F}'),
      CountryItem(name: 'Gouda Cheese', description: 'World-famous Dutch cheese from Gouda', emoji: '\u{1F9C0}'),
    ],
    activities: [
      CountryItem(name: 'Canal Bike Tour', description: 'Cycle along Amsterdam\'s iconic canals', emoji: '\u{1F6B2}'),
      CountryItem(name: 'Tulip Season', description: 'Visit during April for peak tulip bloom', emoji: '\u{1F337}'),
      CountryItem(name: 'King\'s Day', description: 'Join the orange-clad national celebration', emoji: '\u{1F451}'),
      CountryItem(name: 'Cheese Market', description: 'Watch traditional cheese trading in Alkmaar', emoji: '\u{1F9C0}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // GREECE
  // ══════════════════════════════════════════════════
  'europe-greece': CountryDetail(
    cities: [
      CountryItem(name: 'Athens', description: 'Cradle of Western civilization', emoji: '\u{1F3DB}', latitude: 37.9838, longitude: 23.7275),
      CountryItem(name: 'Santorini', description: 'Iconic white and blue cliffside island', emoji: '\u{1F3D6}', latitude: 36.3932, longitude: 25.4615),
      CountryItem(name: 'Mykonos', description: 'Vibrant party island with windmills', emoji: '\u{1F389}', latitude: 37.4467, longitude: 25.3289),
      CountryItem(name: 'Thessaloniki', description: 'Coastal city with Ottoman and Byzantine heritage', emoji: '\u{26F2}', latitude: 40.6401, longitude: 22.9444),
    ],
    landmarks: [
      CountryItem(name: 'Acropolis', description: 'Ancient citadel and the Parthenon above Athens', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Meteora', description: 'Monasteries perched on towering rock pillars', emoji: '\u{26EA}'),
      CountryItem(name: 'Delphi', description: 'Ancient sanctuary of the Oracle', emoji: '\u{1F52E}'),
      CountryItem(name: 'Palace of Knossos', description: 'Minoan palace on the island of Crete', emoji: '\u{1F3F0}'),
    ],
    food: [
      CountryItem(name: 'Moussaka', description: 'Layered eggplant, meat, and béchamel bake', emoji: '\u{1F372}'),
      CountryItem(name: 'Souvlaki', description: 'Grilled meat skewers wrapped in pita', emoji: '\u{1F356}'),
      CountryItem(name: 'Greek Salad', description: 'Fresh tomatoes, feta, olives, and olive oil', emoji: '\u{1F957}'),
      CountryItem(name: 'Baklava', description: 'Layers of filo pastry with honey and nuts', emoji: '\u{1F36F}'),
    ],
    activities: [
      CountryItem(name: 'Island Hopping', description: 'Sail between the Cycladic islands', emoji: '\u{26F5}'),
      CountryItem(name: 'Sunset at Oia', description: 'Watch the famous Santorini sunset', emoji: '\u{1F305}'),
      CountryItem(name: 'Beach Day', description: 'Crystal-clear waters on Navagio Beach', emoji: '\u{1F3CA}'),
      CountryItem(name: 'Ancient Ruins Walk', description: 'Explore 3,000 years of history on foot', emoji: '\u{1F3DB}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // SWITZERLAND
  // ══════════════════════════════════════════════════
  'europe-switzerland': CountryDetail(
    cities: [
      CountryItem(name: 'Zurich', description: 'Financial hub on a stunning lake', emoji: '\u{1F3E6}', latitude: 47.3769, longitude: 8.5417),
      CountryItem(name: 'Geneva', description: 'International city on Lac Léman', emoji: '\u{1F30D}', latitude: 46.2044, longitude: 6.1432),
      CountryItem(name: 'Lucerne', description: 'Fairy-tale city beneath alpine peaks', emoji: '\u{1F3DE}', latitude: 47.0502, longitude: 8.3093),
      CountryItem(name: 'Interlaken', description: 'Adventure capital between two lakes', emoji: '\u{1F3D4}', latitude: 46.6863, longitude: 7.8632),
    ],
    landmarks: [
      CountryItem(name: 'Matterhorn', description: 'The iconic pyramid peak of the Alps', emoji: '\u{1F3D4}'),
      CountryItem(name: 'Chapel Bridge', description: 'Europe\'s oldest covered wooden bridge in Lucerne', emoji: '\u{1F309}'),
      CountryItem(name: 'Jet d\'Eau', description: 'Geneva\'s towering lakeside water fountain', emoji: '\u{26F2}'),
      CountryItem(name: 'Jungfraujoch', description: 'The Top of Europe railway station', emoji: '\u{1F682}'),
    ],
    food: [
      CountryItem(name: 'Fondue', description: 'Melted cheese dipped with bread cubes', emoji: '\u{1F9C0}'),
      CountryItem(name: 'Raclette', description: 'Melted cheese scraped over potatoes', emoji: '\u{1F9C0}'),
      CountryItem(name: 'Swiss Chocolate', description: 'The world\'s finest chocolate tradition', emoji: '\u{1F36B}'),
      CountryItem(name: 'Rösti', description: 'Crispy grated potato pancake', emoji: '\u{1F954}'),
    ],
    activities: [
      CountryItem(name: 'Alpine Skiing', description: 'Ski world-class resorts like Zermatt and St. Moritz', emoji: '\u{26F7}'),
      CountryItem(name: 'Glacier Express', description: 'Scenic train ride through the Alps', emoji: '\u{1F682}'),
      CountryItem(name: 'Paragliding', description: 'Soar above the Alps from Interlaken', emoji: '\u{1FA82}'),
      CountryItem(name: 'Lake Swimming', description: 'Swim in pristine alpine lakes', emoji: '\u{1F3CA}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // PORTUGAL
  // ══════════════════════════════════════════════════
  'europe-portugal': CountryDetail(
    cities: [
      CountryItem(name: 'Lisbon', description: 'Hilly capital with pastel buildings and trams', emoji: '\u{1F68B}', latitude: 38.7223, longitude: -9.1393),
      CountryItem(name: 'Porto', description: 'River city famous for port wine', emoji: '\u{1F377}', latitude: 41.1579, longitude: -8.6291),
      CountryItem(name: 'Faro', description: 'Gateway to the stunning Algarve coast', emoji: '\u{1F3D6}', latitude: 37.0194, longitude: -7.9322),
      CountryItem(name: 'Sintra', description: 'Romantic hilltop palaces and gardens', emoji: '\u{1F3F0}', latitude: 38.8029, longitude: -9.3817),
    ],
    landmarks: [
      CountryItem(name: 'Belém Tower', description: 'Fortified tower guarding Lisbon\'s harbor', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Pena Palace', description: 'Colorful Romanticist castle in Sintra', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Dom Luís I Bridge', description: 'Iron arch bridge spanning Porto\'s Douro River', emoji: '\u{1F309}'),
      CountryItem(name: 'Jerónimos Monastery', description: 'Ornate Manueline monastery in Belém', emoji: '\u{26EA}'),
    ],
    food: [
      CountryItem(name: 'Pastel de Nata', description: 'Iconic Portuguese custard tart', emoji: '\u{1F967}'),
      CountryItem(name: 'Bacalhau', description: 'Salt cod prepared 365 different ways', emoji: '\u{1F41F}'),
      CountryItem(name: 'Francesinha', description: 'Porto\'s legendary meat-stuffed sandwich', emoji: '\u{1F354}'),
      CountryItem(name: 'Bifana', description: 'Marinated pork sandwich in a crusty roll', emoji: '\u{1F956}'),
    ],
    activities: [
      CountryItem(name: 'Tram 28', description: 'Ride the vintage tram through Lisbon\'s old town', emoji: '\u{1F68B}'),
      CountryItem(name: 'Port Wine Tasting', description: 'Sample port in the cellars of Vila Nova de Gaia', emoji: '\u{1F377}'),
      CountryItem(name: 'Surfing', description: 'Catch waves at Nazaré or Ericeira', emoji: '\u{1F3C4}'),
      CountryItem(name: 'Fado Night', description: 'Listen to soulful Portuguese Fado music', emoji: '\u{1F3B6}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // CZECH REPUBLIC
  // ══════════════════════════════════════════════════
  'europe-czech': CountryDetail(
    cities: [
      CountryItem(name: 'Prague', description: 'City of a hundred spires', emoji: '\u{1F3F0}', latitude: 50.0755, longitude: 14.4378),
      CountryItem(name: 'Brno', description: 'Moravia\'s vibrant cultural hub', emoji: '\u{1F3AD}', latitude: 49.1951, longitude: 16.6068),
      CountryItem(name: 'Český Krumlov', description: 'Fairy-tale medieval town on the Vltava', emoji: '\u{1F3F0}', latitude: 48.8127, longitude: 14.3175),
      CountryItem(name: 'Karlovy Vary', description: 'Elegant spa town with hot springs', emoji: '\u{2668}', latitude: 50.2316, longitude: 12.8713),
    ],
    landmarks: [
      CountryItem(name: 'Charles Bridge', description: 'Gothic bridge lined with baroque statues', emoji: '\u{1F309}'),
      CountryItem(name: 'Prague Castle', description: 'Largest ancient castle complex in the world', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Old Town Square', description: 'Astronomical Clock and Gothic churches', emoji: '\u{1F554}'),
      CountryItem(name: 'Sedlec Ossuary', description: 'The chilling Bone Church of Kutná Hora', emoji: '\u{1F480}'),
    ],
    food: [
      CountryItem(name: 'Trdelník', description: 'Sweet chimney cake rolled in sugar and nuts', emoji: '\u{1F370}'),
      CountryItem(name: 'Svíčková', description: 'Marinated beef with creamy vegetable sauce', emoji: '\u{1F356}'),
      CountryItem(name: 'Czech Beer', description: 'Birthplace of Pilsner — the world\'s best beer', emoji: '\u{1F37A}'),
      CountryItem(name: 'Kolache', description: 'Traditional pastry filled with fruit or cheese', emoji: '\u{1F950}'),
    ],
    activities: [
      CountryItem(name: 'Beer Spa', description: 'Soak in a tub of warm Czech beer', emoji: '\u{1F37A}'),
      CountryItem(name: 'Vltava River Cruise', description: 'See Prague\'s skyline from the water', emoji: '\u{1F6F3}'),
      CountryItem(name: 'Castle Hopping', description: 'Visit Bohemian castles across the countryside', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Underground Tour', description: 'Explore Prague\'s hidden underground passages', emoji: '\u{1F526}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // AUSTRIA
  // ══════════════════════════════════════════════════
  'europe-austria': CountryDetail(
    cities: [
      CountryItem(name: 'Vienna', description: 'Imperial capital of music, art, and coffee houses', emoji: '\u{1F3BB}', latitude: 48.2082, longitude: 16.3738),
      CountryItem(name: 'Salzburg', description: 'Mozart\'s birthplace and Sound of Music city', emoji: '\u{1F3B5}', latitude: 47.8095, longitude: 13.0550),
      CountryItem(name: 'Innsbruck', description: 'Alpine city surrounded by dramatic peaks', emoji: '\u{1F3D4}', latitude: 47.2692, longitude: 11.4041),
      CountryItem(name: 'Hallstatt', description: 'Fairy-tale lakeside village in the Alps', emoji: '\u{1F3DE}', latitude: 47.5622, longitude: 13.6493),
    ],
    landmarks: [
      CountryItem(name: 'Schönbrunn Palace', description: 'Magnificent imperial summer residence', emoji: '\u{1F3F0}'),
      CountryItem(name: 'St. Stephen\'s Cathedral', description: 'Gothic masterpiece in the heart of Vienna', emoji: '\u{26EA}'),
      CountryItem(name: 'Hohensalzburg Fortress', description: 'Medieval fortress overlooking Salzburg', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Belvedere Palace', description: 'Baroque palace housing Klimt\'s The Kiss', emoji: '\u{1F5BC}'),
    ],
    food: [
      CountryItem(name: 'Wiener Schnitzel', description: 'Golden breaded veal cutlet, the national dish', emoji: '\u{1F356}'),
      CountryItem(name: 'Sachertorte', description: 'Famous Viennese chocolate cake with apricot', emoji: '\u{1F370}'),
      CountryItem(name: 'Apfelstrudel', description: 'Warm apple strudel with vanilla sauce', emoji: '\u{1F34E}'),
      CountryItem(name: 'Kaiserschmarrn', description: 'Fluffy shredded pancake with plum compote', emoji: '\u{1F95E}'),
    ],
    activities: [
      CountryItem(name: 'Vienna Opera', description: 'Attend a performance at the world-famous opera house', emoji: '\u{1F3AD}'),
      CountryItem(name: 'Coffee House Culture', description: 'Linger in a traditional Viennese coffee house', emoji: '\u{2615}'),
      CountryItem(name: 'Alpine Skiing', description: 'Ski the legendary slopes of the Austrian Alps', emoji: '\u{26F7}'),
      CountryItem(name: 'Sound of Music Tour', description: 'Visit filming locations in Salzburg', emoji: '\u{1F3B5}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // SWEDEN
  // ══════════════════════════════════════════════════
  'europe-sweden': CountryDetail(
    cities: [
      CountryItem(name: 'Stockholm', description: 'Beautiful capital spread across 14 islands', emoji: '\u{1F3DD}', latitude: 59.3293, longitude: 18.0686),
      CountryItem(name: 'Gothenburg', description: 'Coastal city with charming canals and seafood', emoji: '\u{26F5}', latitude: 57.7089, longitude: 11.9746),
      CountryItem(name: 'Malmö', description: 'Vibrant multicultural city near Denmark', emoji: '\u{1F309}', latitude: 55.6050, longitude: 13.0038),
      CountryItem(name: 'Kiruna', description: 'Gateway to Swedish Lapland and the Arctic', emoji: '\u{2744}', latitude: 67.8558, longitude: 20.2253),
    ],
    landmarks: [
      CountryItem(name: 'Vasa Museum', description: 'Home to the 17th-century warship Vasa', emoji: '\u{26F5}'),
      CountryItem(name: 'Gamla Stan', description: 'Stockholm\'s charming medieval old town', emoji: '\u{1F3F0}'),
      CountryItem(name: 'ICEHOTEL', description: 'World-famous hotel made entirely of ice', emoji: '\u{2744}'),
      CountryItem(name: 'Royal Palace', description: 'One of Europe\'s largest royal palaces', emoji: '\u{1F451}'),
    ],
    food: [
      CountryItem(name: 'Swedish Meatballs', description: 'Classic meatballs with lingonberry sauce', emoji: '\u{1F356}'),
      CountryItem(name: 'Smörgåsbord', description: 'Traditional buffet of cold and hot dishes', emoji: '\u{1F372}'),
      CountryItem(name: 'Kanelbullar', description: 'Beloved Swedish cinnamon buns', emoji: '\u{1F35E}'),
      CountryItem(name: 'Gravlax', description: 'Cured salmon with dill and mustard sauce', emoji: '\u{1F41F}'),
    ],
    activities: [
      CountryItem(name: 'Northern Lights', description: 'Chase the aurora borealis in Swedish Lapland', emoji: '\u{1F30C}'),
      CountryItem(name: 'Fika', description: 'Embrace the Swedish tradition of coffee and pastry', emoji: '\u{2615}'),
      CountryItem(name: 'Archipelago Hopping', description: 'Explore Stockholm\'s 30,000 islands', emoji: '\u{26F5}'),
      CountryItem(name: 'Midsummer', description: 'Celebrate the longest day with dancing and flowers', emoji: '\u{1F33B}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // NORWAY
  // ══════════════════════════════════════════════════
  'europe-norway': CountryDetail(
    cities: [
      CountryItem(name: 'Oslo', description: 'Modern capital with Viking heritage and fjord access', emoji: '\u{1F3D9}', latitude: 59.9139, longitude: 10.7522),
      CountryItem(name: 'Bergen', description: 'Gateway to the fjords with colorful Bryggen wharf', emoji: '\u{1F3E0}', latitude: 60.3913, longitude: 5.3221),
      CountryItem(name: 'Tromsø', description: 'Arctic city famous for northern lights', emoji: '\u{1F30C}', latitude: 69.6496, longitude: 18.9560),
      CountryItem(name: 'Stavanger', description: 'Oil capital and gateway to Pulpit Rock', emoji: '\u{1F3D4}', latitude: 58.9700, longitude: 5.7331),
    ],
    landmarks: [
      CountryItem(name: 'Geirangerfjord', description: 'UNESCO-listed fjord with dramatic waterfalls', emoji: '\u{1F3DE}'),
      CountryItem(name: 'Preikestolen', description: 'The iconic Pulpit Rock cliff above the fjord', emoji: '\u{1F3D4}'),
      CountryItem(name: 'Bryggen', description: 'Colorful Hanseatic wharf houses in Bergen', emoji: '\u{1F3E0}'),
      CountryItem(name: 'Trolltunga', description: 'The famous tongue-shaped rock formation', emoji: '\u{1FAA8}'),
    ],
    food: [
      CountryItem(name: 'Brunost', description: 'Unique Norwegian brown cheese', emoji: '\u{1F9C0}'),
      CountryItem(name: 'Fresh Salmon', description: 'World-renowned Norwegian salmon', emoji: '\u{1F41F}'),
      CountryItem(name: 'Kjøttkaker', description: 'Norwegian meatcakes with brown gravy', emoji: '\u{1F356}'),
      CountryItem(name: 'Krumkake', description: 'Delicate cone-shaped waffle cookie', emoji: '\u{1F9C7}'),
    ],
    activities: [
      CountryItem(name: 'Fjord Cruise', description: 'Sail through Norway\'s dramatic fjords', emoji: '\u{1F6F3}'),
      CountryItem(name: 'Northern Lights', description: 'Hunt for the aurora borealis from Tromsø', emoji: '\u{1F30C}'),
      CountryItem(name: 'Midnight Sun', description: 'Experience 24 hours of daylight above the Arctic', emoji: '\u{2600}'),
      CountryItem(name: 'Dog Sledding', description: 'Mush a husky team through arctic wilderness', emoji: '\u{1F415}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // DENMARK
  // ══════════════════════════════════════════════════
  'europe-denmark': CountryDetail(
    cities: [
      CountryItem(name: 'Copenhagen', description: 'Cool capital of design, cycling, and hygge', emoji: '\u{1F6B2}', latitude: 55.6761, longitude: 12.5683),
      CountryItem(name: 'Aarhus', description: 'Vibrant cultural city on the Jutland peninsula', emoji: '\u{1F3AD}', latitude: 56.1629, longitude: 10.2039),
      CountryItem(name: 'Odense', description: 'Birthplace of Hans Christian Andersen', emoji: '\u{1F4D6}', latitude: 55.4038, longitude: 10.4024),
      CountryItem(name: 'Skagen', description: 'Where two seas meet at Denmark\'s northern tip', emoji: '\u{1F3D6}', latitude: 57.7209, longitude: 10.5841),
    ],
    landmarks: [
      CountryItem(name: 'Tivoli Gardens', description: 'Enchanting amusement park in central Copenhagen', emoji: '\u{1F3A0}'),
      CountryItem(name: 'Little Mermaid', description: 'Iconic bronze statue on the harbor', emoji: '\u{1F9DC}'),
      CountryItem(name: 'Nyhavn', description: 'Colorful 17th-century waterfront district', emoji: '\u{1F3E0}'),
      CountryItem(name: 'Kronborg Castle', description: 'Shakespeare\'s Hamlet castle in Helsingør', emoji: '\u{1F3F0}'),
    ],
    food: [
      CountryItem(name: 'Smørrebrød', description: 'Open-faced rye bread sandwiches with toppings', emoji: '\u{1F35E}'),
      CountryItem(name: 'Danish Pastry', description: 'Flaky, buttery pastry known worldwide', emoji: '\u{1F950}'),
      CountryItem(name: 'Frikadeller', description: 'Traditional pan-fried Danish meatballs', emoji: '\u{1F356}'),
      CountryItem(name: 'Hot Dog', description: 'Iconic Danish street food from a pølsevogn', emoji: '\u{1F32D}'),
    ],
    activities: [
      CountryItem(name: 'Bike Copenhagen', description: 'Cycle the world\'s most bike-friendly city', emoji: '\u{1F6B2}'),
      CountryItem(name: 'Hygge Experience', description: 'Embrace cozy Danish living in a café', emoji: '\u{2615}'),
      CountryItem(name: 'LEGO House', description: 'Visit the Home of the Brick in Billund', emoji: '\u{1F9F1}'),
      CountryItem(name: 'Canal Tour', description: 'Cruise through Copenhagen\'s scenic canals', emoji: '\u{1F6F6}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // POLAND
  // ══════════════════════════════════════════════════
  'europe-poland': CountryDetail(
    cities: [
      CountryItem(name: 'Warsaw', description: 'Resilient capital rebuilt from wartime ruins', emoji: '\u{1F3D9}', latitude: 52.2297, longitude: 21.0122),
      CountryItem(name: 'Kraków', description: 'Medieval gem with Europe\'s largest market square', emoji: '\u{1F3F0}', latitude: 50.0647, longitude: 19.9450),
      CountryItem(name: 'Gdańsk', description: 'Baltic port city with colorful merchant houses', emoji: '\u{26F5}', latitude: 54.3520, longitude: 18.6466),
      CountryItem(name: 'Wrocław', description: 'City of bridges and hidden bronze dwarfs', emoji: '\u{1F309}', latitude: 51.1079, longitude: 17.0385),
    ],
    landmarks: [
      CountryItem(name: 'Wawel Castle', description: 'Royal castle and cathedral on the Vistula', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Auschwitz-Birkenau', description: 'Sobering memorial to Holocaust history', emoji: '\u{1F54A}'),
      CountryItem(name: 'Wieliczka Salt Mine', description: 'Underground cathedral carved from salt', emoji: '\u{26EA}'),
      CountryItem(name: 'Old Town Warsaw', description: 'Meticulously reconstructed historic center', emoji: '\u{1F3D9}'),
    ],
    food: [
      CountryItem(name: 'Pierogi', description: 'Beloved Polish dumplings with various fillings', emoji: '\u{1F95F}'),
      CountryItem(name: 'Żurek', description: 'Sour rye soup served in a bread bowl', emoji: '\u{1F35C}'),
      CountryItem(name: 'Bigos', description: 'Hunter\'s stew with sauerkraut and meats', emoji: '\u{1F372}'),
      CountryItem(name: 'Pączki', description: 'Rich filled doughnuts, a Polish tradition', emoji: '\u{1F369}'),
    ],
    activities: [
      CountryItem(name: 'Kraków Old Town', description: 'Wander the stunning medieval market square', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Vodka Tasting', description: 'Sample Polish vodka the traditional way', emoji: '\u{1F943}'),
      CountryItem(name: 'Tatra Mountains', description: 'Hike the dramatic peaks on the Slovak border', emoji: '\u{1F3D4}'),
      CountryItem(name: 'Dwarf Hunting', description: 'Find the hidden bronze dwarfs across Wrocław', emoji: '\u{1F50D}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // IRELAND
  // ══════════════════════════════════════════════════
  'europe-ireland': CountryDetail(
    cities: [
      CountryItem(name: 'Dublin', description: 'Lively capital of literature, pubs, and history', emoji: '\u{1F37A}', latitude: 53.3498, longitude: -6.2603),
      CountryItem(name: 'Galway', description: 'Bohemian city on the Wild Atlantic Way', emoji: '\u{1F3B6}', latitude: 53.2707, longitude: -9.0568),
      CountryItem(name: 'Cork', description: 'Foodie capital of Ireland', emoji: '\u{1F372}', latitude: 51.8985, longitude: -8.4756),
      CountryItem(name: 'Killarney', description: 'Gateway to the Ring of Kerry', emoji: '\u{1F3DE}', latitude: 52.0599, longitude: -9.5044),
    ],
    landmarks: [
      CountryItem(name: 'Cliffs of Moher', description: 'Towering sea cliffs on the Atlantic coast', emoji: '\u{1F3DE}'),
      CountryItem(name: 'Ring of Kerry', description: 'Scenic coastal drive through stunning landscapes', emoji: '\u{1F697}'),
      CountryItem(name: 'Giant\'s Causeway', description: 'Unique hexagonal basalt columns on the coast', emoji: '\u{1FAA8}'),
      CountryItem(name: 'Trinity College', description: 'Home of the ancient Book of Kells', emoji: '\u{1F4D6}'),
    ],
    food: [
      CountryItem(name: 'Irish Stew', description: 'Hearty lamb stew with root vegetables', emoji: '\u{1F372}'),
      CountryItem(name: 'Soda Bread', description: 'Traditional buttermilk bread, warm from the oven', emoji: '\u{1F35E}'),
      CountryItem(name: 'Fish and Chips', description: 'Fresh Atlantic fish with crispy chips', emoji: '\u{1F35F}'),
      CountryItem(name: 'Full Irish Breakfast', description: 'Eggs, bacon, sausage, black pudding, and toast', emoji: '\u{1F373}'),
    ],
    activities: [
      CountryItem(name: 'Pub Crawl', description: 'Experience legendary Irish pub culture in Dublin', emoji: '\u{1F37B}'),
      CountryItem(name: 'Wild Atlantic Way', description: 'Drive the world\'s longest coastal route', emoji: '\u{1F697}'),
      CountryItem(name: 'Guinness Storehouse', description: 'Tour the home of Ireland\'s famous stout', emoji: '\u{1F37A}'),
      CountryItem(name: 'Traditional Music', description: 'Enjoy live trad sessions in a cozy pub', emoji: '\u{1F3B6}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // CROATIA
  // ══════════════════════════════════════════════════
  'europe-croatia': CountryDetail(
    cities: [
      CountryItem(name: 'Zagreb', description: 'Charming capital with Austro-Hungarian architecture', emoji: '\u{1F3D9}', latitude: 45.8150, longitude: 15.9819),
      CountryItem(name: 'Dubrovnik', description: 'Pearl of the Adriatic with ancient city walls', emoji: '\u{1F3F0}', latitude: 42.6507, longitude: 18.0944),
      CountryItem(name: 'Split', description: 'Roman palace turned vibrant coastal city', emoji: '\u{1F3DB}', latitude: 43.5081, longitude: 16.4402),
      CountryItem(name: 'Hvar', description: 'Sun-soaked island of lavender and nightlife', emoji: '\u{1F3D6}', latitude: 43.1729, longitude: 16.4411),
    ],
    landmarks: [
      CountryItem(name: 'Dubrovnik Walls', description: 'Walk the medieval walls above the Adriatic', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Diocletian\'s Palace', description: 'Roman emperor\'s palace in the heart of Split', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Plitvice Lakes', description: 'Cascading turquoise lakes and waterfalls', emoji: '\u{1F4A7}'),
      CountryItem(name: 'Krka Waterfalls', description: 'Stunning waterfalls you can swim beneath', emoji: '\u{1F3CA}'),
    ],
    food: [
      CountryItem(name: 'Ćevapi', description: 'Grilled minced meat sausages with ajvar', emoji: '\u{1F356}'),
      CountryItem(name: 'Black Risotto', description: 'Squid ink risotto, a Dalmatian specialty', emoji: '\u{1F35A}'),
      CountryItem(name: 'Peka', description: 'Slow-cooked meat and vegetables under a bell', emoji: '\u{1F372}'),
      CountryItem(name: 'Fritule', description: 'Croatian doughnut bites dusted with sugar', emoji: '\u{1F369}'),
    ],
    activities: [
      CountryItem(name: 'Island Hopping', description: 'Sail between Croatia\'s 1,000+ islands', emoji: '\u{26F5}'),
      CountryItem(name: 'Game of Thrones Tour', description: 'Visit King\'s Landing filming locations in Dubrovnik', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Sea Kayaking', description: 'Paddle along the crystal-clear Adriatic coast', emoji: '\u{1F6F6}'),
      CountryItem(name: 'Truffle Hunting', description: 'Hunt for prized truffles in Istria', emoji: '\u{1F344}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // HUNGARY
  // ══════════════════════════════════════════════════
  'europe-hungary': CountryDetail(
    cities: [
      CountryItem(name: 'Budapest', description: 'Stunning capital split by the Danube river', emoji: '\u{1F309}', latitude: 47.4979, longitude: 19.0402),
      CountryItem(name: 'Eger', description: 'Baroque town famous for its thermal baths and wine', emoji: '\u{1F377}', latitude: 47.9025, longitude: 20.3772),
      CountryItem(name: 'Pécs', description: 'Cultural capital with Roman and Ottoman heritage', emoji: '\u{1F3DB}', latitude: 46.0727, longitude: 18.2323),
      CountryItem(name: 'Debrecen', description: 'Hungary\'s second city on the Great Plains', emoji: '\u{1F33E}', latitude: 47.5316, longitude: 21.6273),
    ],
    landmarks: [
      CountryItem(name: 'Hungarian Parliament', description: 'Stunning Gothic Revival building on the Danube', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Buda Castle', description: 'Historic royal palace overlooking the city', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Fisherman\'s Bastion', description: 'Fairy-tale terrace with panoramic views', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Chain Bridge', description: 'Iconic suspension bridge linking Buda and Pest', emoji: '\u{1F309}'),
    ],
    food: [
      CountryItem(name: 'Goulash', description: 'Hearty paprika-spiced beef stew', emoji: '\u{1F372}'),
      CountryItem(name: 'Lángos', description: 'Deep-fried dough with sour cream and cheese', emoji: '\u{1F35E}'),
      CountryItem(name: 'Chimney Cake', description: 'Sweet spiral pastry coated in sugar', emoji: '\u{1F370}'),
      CountryItem(name: 'Chicken Paprikash', description: 'Creamy paprika chicken with dumplings', emoji: '\u{1F357}'),
    ],
    activities: [
      CountryItem(name: 'Thermal Baths', description: 'Soak in Budapest\'s legendary Széchenyi Baths', emoji: '\u{2668}'),
      CountryItem(name: 'Ruin Bars', description: 'Party in Budapest\'s unique ruin pub scene', emoji: '\u{1F37B}'),
      CountryItem(name: 'Danube Cruise', description: 'See the illuminated Parliament from the river', emoji: '\u{1F6F3}'),
      CountryItem(name: 'Wine Tasting', description: 'Sample Tokaji and Bull\'s Blood wines', emoji: '\u{1F377}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // BELGIUM
  // ══════════════════════════════════════════════════
  'europe-belgium': CountryDetail(
    cities: [
      CountryItem(name: 'Brussels', description: 'EU capital with Grand Place and comic strip murals', emoji: '\u{1F30D}', latitude: 50.8503, longitude: 4.3517),
      CountryItem(name: 'Bruges', description: 'Medieval fairy-tale city of canals and chocolate', emoji: '\u{1F36B}', latitude: 51.2093, longitude: 3.2247),
      CountryItem(name: 'Ghent', description: 'Hidden gem with medieval towers and vibrant culture', emoji: '\u{1F3F0}', latitude: 51.0543, longitude: 3.7174),
      CountryItem(name: 'Antwerp', description: 'Diamond capital and fashion hub', emoji: '\u{1F48E}', latitude: 51.2194, longitude: 4.4025),
    ],
    landmarks: [
      CountryItem(name: 'Grand Place', description: 'Brussels\' breathtaking central square', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Atomium', description: 'Iconic iron crystal structure from the 1958 Expo', emoji: '\u{269B}'),
      CountryItem(name: 'Belfry of Bruges', description: 'Medieval bell tower overlooking the city', emoji: '\u{1F514}'),
      CountryItem(name: 'Manneken Pis', description: 'Brussels\' famous little bronze fountain statue', emoji: '\u{26F2}'),
    ],
    food: [
      CountryItem(name: 'Belgian Waffles', description: 'Light, crispy waffles with endless toppings', emoji: '\u{1F9C7}'),
      CountryItem(name: 'Belgian Chocolate', description: 'World-class pralines and truffles', emoji: '\u{1F36B}'),
      CountryItem(name: 'Moules-Frites', description: 'Mussels with crispy Belgian fries', emoji: '\u{1F35F}'),
      CountryItem(name: 'Belgian Beer', description: 'Over 1,500 varieties of craft beer', emoji: '\u{1F37A}'),
    ],
    activities: [
      CountryItem(name: 'Chocolate Tour', description: 'Visit artisan chocolatiers in Bruges', emoji: '\u{1F36B}'),
      CountryItem(name: 'Beer Tasting', description: 'Sample Trappist ales and lambics', emoji: '\u{1F37A}'),
      CountryItem(name: 'Canal Boat Ride', description: 'Glide through the canals of Bruges', emoji: '\u{1F6F6}'),
      CountryItem(name: 'Comic Strip Walk', description: 'Follow Brussels\' painted comic murals', emoji: '\u{1F3A8}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // TURKEY
  // ══════════════════════════════════════════════════
  'europe-turkey': CountryDetail(
    cities: [
      CountryItem(name: 'Istanbul', description: 'Where Europe meets Asia across the Bosphorus', emoji: '\u{1F54C}', latitude: 41.0082, longitude: 28.9784),
      CountryItem(name: 'Cappadocia', description: 'Surreal fairy chimneys and cave hotels', emoji: '\u{1F388}', latitude: 38.6431, longitude: 34.8289),
      CountryItem(name: 'Antalya', description: 'Turquoise Coast resort city with ancient ruins', emoji: '\u{1F3D6}', latitude: 36.8969, longitude: 30.7133),
      CountryItem(name: 'Izmir', description: 'Cosmopolitan Aegean city near ancient Ephesus', emoji: '\u{1F3DB}', latitude: 38.4237, longitude: 27.1428),
    ],
    landmarks: [
      CountryItem(name: 'Hagia Sophia', description: 'Monumental cathedral-turned-mosque of Istanbul', emoji: '\u{1F54C}'),
      CountryItem(name: 'Blue Mosque', description: 'Stunning mosque with six minarets and blue tiles', emoji: '\u{1F54C}'),
      CountryItem(name: 'Pamukkale', description: 'Dazzling white travertine thermal terraces', emoji: '\u{1F4A7}'),
      CountryItem(name: 'Ephesus', description: 'Remarkably preserved ancient Greek-Roman city', emoji: '\u{1F3DB}'),
    ],
    food: [
      CountryItem(name: 'Kebab', description: 'Iconic Turkish grilled meat in endless varieties', emoji: '\u{1F356}'),
      CountryItem(name: 'Baklava', description: 'Flaky pastry layers with pistachios and honey', emoji: '\u{1F36F}'),
      CountryItem(name: 'Turkish Breakfast', description: 'Lavish spread of cheese, olives, eggs, and pastry', emoji: '\u{1F373}'),
      CountryItem(name: 'Lahmacun', description: 'Thin crispy flatbread with spiced meat', emoji: '\u{1F355}'),
    ],
    activities: [
      CountryItem(name: 'Hot Air Balloon', description: 'Float above Cappadocia\'s fairy chimneys at sunrise', emoji: '\u{1F388}'),
      CountryItem(name: 'Grand Bazaar', description: 'Shop in one of the world\'s oldest covered markets', emoji: '\u{1F6CD}'),
      CountryItem(name: 'Turkish Bath', description: 'Relax in a traditional hammam experience', emoji: '\u{2668}'),
      CountryItem(name: 'Bosphorus Cruise', description: 'Sail between two continents on the Bosphorus', emoji: '\u{1F6F3}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // FINLAND
  // ══════════════════════════════════════════════════
  'europe-finland': CountryDetail(
    cities: [
      CountryItem(name: 'Helsinki', description: 'Design capital on the Baltic Sea', emoji: '\u{1F3D9}', latitude: 60.1699, longitude: 24.9384),
      CountryItem(name: 'Rovaniemi', description: 'Official hometown of Santa Claus in Lapland', emoji: '\u{1F385}', latitude: 66.5039, longitude: 25.7294),
      CountryItem(name: 'Turku', description: 'Finland\'s oldest city and former capital', emoji: '\u{1F3F0}', latitude: 60.4518, longitude: 22.2666),
      CountryItem(name: 'Tampere', description: 'Vibrant city between two lakes', emoji: '\u{1F3ED}', latitude: 61.4978, longitude: 23.7610),
    ],
    landmarks: [
      CountryItem(name: 'Suomenlinna', description: 'Sea fortress island off Helsinki', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Santa Claus Village', description: 'Meet Santa on the Arctic Circle', emoji: '\u{1F385}'),
      CountryItem(name: 'Helsinki Cathedral', description: 'Iconic white neoclassical cathedral', emoji: '\u{26EA}'),
      CountryItem(name: 'Olavinlinna Castle', description: 'Medieval castle on a lake island', emoji: '\u{1F3F0}'),
    ],
    food: [
      CountryItem(name: 'Karelian Pie', description: 'Traditional rye crust pie with rice filling', emoji: '\u{1F967}'),
      CountryItem(name: 'Salmon Soup', description: 'Creamy salmon and potato soup', emoji: '\u{1F35C}'),
      CountryItem(name: 'Reindeer Stew', description: 'Tender Lapland reindeer with mashed potatoes', emoji: '\u{1F98C}'),
      CountryItem(name: 'Cinnamon Roll', description: 'Finnish pulla — cardamom-spiced sweet bun', emoji: '\u{1F35E}'),
    ],
    activities: [
      CountryItem(name: 'Finnish Sauna', description: 'Experience the authentic Finnish sauna tradition', emoji: '\u{2668}'),
      CountryItem(name: 'Northern Lights', description: 'Chase the aurora from a glass igloo in Lapland', emoji: '\u{1F30C}'),
      CountryItem(name: 'Lake Swimming', description: 'Swim in one of Finland\'s 188,000 lakes', emoji: '\u{1F3CA}'),
      CountryItem(name: 'Husky Safari', description: 'Mush a husky sled through snowy forests', emoji: '\u{1F415}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // ROMANIA
  // ══════════════════════════════════════════════════
  'europe-romania': CountryDetail(
    cities: [
      CountryItem(name: 'Bucharest', description: 'Lively capital with grand boulevards', emoji: '\u{1F3D9}', latitude: 44.4268, longitude: 26.1025),
      CountryItem(name: 'Brașov', description: 'Medieval city at the foot of the Carpathians', emoji: '\u{1F3F0}', latitude: 45.6427, longitude: 25.5887),
      CountryItem(name: 'Sibiu', description: 'Charming Saxon town with cobbled streets', emoji: '\u{1F3E0}', latitude: 45.7983, longitude: 24.1256),
      CountryItem(name: 'Cluj-Napoca', description: 'Vibrant student city and cultural hub', emoji: '\u{1F3AD}', latitude: 46.7712, longitude: 23.6236),
    ],
    landmarks: [
      CountryItem(name: 'Bran Castle', description: 'The legendary castle linked to Dracula', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Palace of the Parliament', description: 'World\'s heaviest building in Bucharest', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Painted Monasteries', description: 'UNESCO-listed frescoed churches of Bucovina', emoji: '\u{26EA}'),
      CountryItem(name: 'Peleș Castle', description: 'Neo-Renaissance royal castle in the mountains', emoji: '\u{1F3F0}'),
    ],
    food: [
      CountryItem(name: 'Sarmale', description: 'Cabbage rolls stuffed with meat and rice', emoji: '\u{1F957}'),
      CountryItem(name: 'Mici', description: 'Grilled skinless sausages, a street food staple', emoji: '\u{1F356}'),
      CountryItem(name: 'Mămăligă', description: 'Traditional polenta served with cheese and cream', emoji: '\u{1F9C0}'),
      CountryItem(name: 'Papanași', description: 'Fried doughnuts with sour cream and jam', emoji: '\u{1F369}'),
    ],
    activities: [
      CountryItem(name: 'Transylvania Road Trip', description: 'Drive through dramatic Carpathian passes', emoji: '\u{1F697}'),
      CountryItem(name: 'Bear Watching', description: 'Spot brown bears in their natural habitat', emoji: '\u{1F43B}'),
      CountryItem(name: 'Dracula Tour', description: 'Visit Bran Castle and Vlad\'s legendary trail', emoji: '\u{1F9DB}'),
      CountryItem(name: 'Thermal Baths', description: 'Soak in natural hot springs across the country', emoji: '\u{2668}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // ICELAND
  // ══════════════════════════════════════════════════
  'europe-iceland': CountryDetail(
    cities: [
      CountryItem(name: 'Reykjavik', description: 'World\'s northernmost capital city', emoji: '\u{1F3D9}', latitude: 64.1466, longitude: -21.9426),
      CountryItem(name: 'Akureyri', description: 'Capital of the north near whale-watching waters', emoji: '\u{1F40B}', latitude: 65.6835, longitude: -18.0878),
      CountryItem(name: 'Vik', description: 'Tiny village with dramatic black sand beaches', emoji: '\u{1F3D6}', latitude: 63.4186, longitude: -19.0060),
      CountryItem(name: 'Húsavík', description: 'Whale capital of Iceland', emoji: '\u{1F40B}', latitude: 66.0449, longitude: -17.3380),
    ],
    landmarks: [
      CountryItem(name: 'Blue Lagoon', description: 'Famous geothermal spa in a lava field', emoji: '\u{2668}'),
      CountryItem(name: 'Gullfoss', description: 'Majestic two-tiered waterfall on the Golden Circle', emoji: '\u{1F4A7}'),
      CountryItem(name: 'Geysir', description: 'The original geyser that named them all', emoji: '\u{1F30B}'),
      CountryItem(name: 'Jökulsárlón', description: 'Glacier lagoon with floating icebergs', emoji: '\u{1F9CA}'),
    ],
    food: [
      CountryItem(name: 'Lamb Soup', description: 'Hearty traditional Icelandic lamb stew', emoji: '\u{1F372}'),
      CountryItem(name: 'Skyr', description: 'Thick, creamy Icelandic dairy product', emoji: '\u{1F95B}'),
      CountryItem(name: 'Hot Dog', description: 'Iconic Icelandic pylsur with crispy onions', emoji: '\u{1F32D}'),
      CountryItem(name: 'Fresh Fish', description: 'Arctic char and cod straight from the sea', emoji: '\u{1F41F}'),
    ],
    activities: [
      CountryItem(name: 'Golden Circle', description: 'Drive the famous route past geysers and falls', emoji: '\u{1F697}'),
      CountryItem(name: 'Northern Lights', description: 'Hunt the aurora borealis in winter skies', emoji: '\u{1F30C}'),
      CountryItem(name: 'Glacier Hike', description: 'Walk on a glacier with crampons and an ice axe', emoji: '\u{1F9CA}'),
      CountryItem(name: 'Whale Watching', description: 'Spot humpbacks and orcas from Húsavík', emoji: '\u{1F40B}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // SLOVENIA
  // ══════════════════════════════════════════════════
  'europe-slovenia': CountryDetail(
    cities: [
      CountryItem(name: 'Ljubljana', description: 'Green capital with a dragon-guarded bridge', emoji: '\u{1F409}', latitude: 46.0569, longitude: 14.5058),
      CountryItem(name: 'Bled', description: 'Fairy-tale lake with an island church', emoji: '\u{1F3DE}', latitude: 46.3684, longitude: 14.1146),
      CountryItem(name: 'Piran', description: 'Venetian-style town on the Adriatic coast', emoji: '\u{26F5}', latitude: 45.5283, longitude: 13.5681),
      CountryItem(name: 'Maribor', description: 'Wine country capital and cultural hub', emoji: '\u{1F377}', latitude: 46.5547, longitude: 15.6459),
    ],
    landmarks: [
      CountryItem(name: 'Lake Bled', description: 'Iconic emerald lake with a church island', emoji: '\u{1F3DE}'),
      CountryItem(name: 'Postojna Cave', description: 'Massive karst cave system with a train ride', emoji: '\u{1F687}'),
      CountryItem(name: 'Predjama Castle', description: 'Renaissance castle built into a cliff face', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Ljubljana Castle', description: 'Hilltop fortress with panoramic views', emoji: '\u{1F3F0}'),
    ],
    food: [
      CountryItem(name: 'Štruklji', description: 'Rolled dumplings with sweet or savory filling', emoji: '\u{1F95F}'),
      CountryItem(name: 'Bled Cream Cake', description: 'Iconic vanilla custard and cream pastry', emoji: '\u{1F370}'),
      CountryItem(name: 'Idrijski Žlikrofi', description: 'Stuffed pasta parcels from the Idrija region', emoji: '\u{1F95F}'),
      CountryItem(name: 'Potica', description: 'Traditional rolled nut bread', emoji: '\u{1F35E}'),
    ],
    activities: [
      CountryItem(name: 'Lake Bled Walk', description: 'Stroll around the lake and row to the island', emoji: '\u{1F6F6}'),
      CountryItem(name: 'Soča Valley', description: 'Kayak the stunning emerald Soča River', emoji: '\u{1F6F6}'),
      CountryItem(name: 'Cave Tour', description: 'Ride the underground train through Postojna', emoji: '\u{1F687}'),
      CountryItem(name: 'Julian Alps Hiking', description: 'Hike through Slovenia\'s dramatic alpine scenery', emoji: '\u{1F3D4}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // SLOVAKIA
  // ══════════════════════════════════════════════════
  'europe-slovakia': CountryDetail(
    cities: [
      CountryItem(name: 'Bratislava', description: 'Compact capital on the Danube with a castle hilltop', emoji: '\u{1F3F0}', latitude: 48.1486, longitude: 17.1077),
      CountryItem(name: 'Košice', description: 'Vibrant eastern city with Gothic heritage', emoji: '\u{26EA}', latitude: 48.7164, longitude: 21.2611),
      CountryItem(name: 'High Tatras', description: 'Alpine peaks and mountain resorts', emoji: '\u{1F3D4}', latitude: 49.1616, longitude: 20.1317),
      CountryItem(name: 'Banská Štiavnica', description: 'UNESCO mining town with stunning views', emoji: '\u{1F3DE}', latitude: 48.4589, longitude: 18.8962),
    ],
    landmarks: [
      CountryItem(name: 'Bratislava Castle', description: 'Hilltop castle overlooking the Danube', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Spiš Castle', description: 'One of Europe\'s largest castle ruins', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Demänovská Cave', description: 'Stunning stalactite cave system', emoji: '\u{1FAA8}'),
      CountryItem(name: 'Vlkolínec', description: 'Preserved folk architecture village', emoji: '\u{1F3E1}'),
    ],
    food: [
      CountryItem(name: 'Bryndzové Halušky', description: 'Potato dumplings with sheep cheese and bacon', emoji: '\u{1F95F}'),
      CountryItem(name: 'Kapustnica', description: 'Hearty sauerkraut soup with sausage', emoji: '\u{1F35C}'),
      CountryItem(name: 'Trdelník', description: 'Sweet chimney cake from a street vendor', emoji: '\u{1F370}'),
      CountryItem(name: 'Pirohy', description: 'Slovak dumplings with various fillings', emoji: '\u{1F95F}'),
    ],
    activities: [
      CountryItem(name: 'High Tatras Hike', description: 'Trek the smallest alpine range in Europe', emoji: '\u{1F3D4}'),
      CountryItem(name: 'Castle Hopping', description: 'Visit Slovakia\'s 100+ castles and ruins', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Thermal Springs', description: 'Soak in natural hot springs across the country', emoji: '\u{2668}'),
      CountryItem(name: 'Wine Route', description: 'Tour the vineyards of the Small Carpathians', emoji: '\u{1F377}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // SERBIA
  // ══════════════════════════════════════════════════
  'europe-serbia': CountryDetail(
    cities: [
      CountryItem(name: 'Belgrade', description: 'Where the Sava meets the Danube — legendary nightlife', emoji: '\u{1F3B6}', latitude: 44.7866, longitude: 20.4489),
      CountryItem(name: 'Novi Sad', description: 'Cultural capital and home of EXIT Festival', emoji: '\u{1F3B5}', latitude: 45.2671, longitude: 19.8335),
      CountryItem(name: 'Niš', description: 'Ancient city and birthplace of Constantine', emoji: '\u{1F3DB}', latitude: 43.3209, longitude: 21.8954),
      CountryItem(name: 'Subotica', description: 'Art Nouveau gem near the Hungarian border', emoji: '\u{1F3A8}', latitude: 46.1005, longitude: 19.6658),
    ],
    landmarks: [
      CountryItem(name: 'Kalemegdan Fortress', description: 'Ancient fortress at the rivers\' confluence', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Petrovaradin Fortress', description: 'Gibraltar of the Danube in Novi Sad', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Drvengrad', description: 'Kusturica\'s whimsical wooden village', emoji: '\u{1F3E1}'),
      CountryItem(name: 'Studenica Monastery', description: 'UNESCO-listed medieval Serbian monastery', emoji: '\u{26EA}'),
    ],
    food: [
      CountryItem(name: 'Ćevapi', description: 'Grilled minced meat rolls with kajmak and onion', emoji: '\u{1F356}'),
      CountryItem(name: 'Pljeskavica', description: 'Giant spiced Serbian burger patty', emoji: '\u{1F354}'),
      CountryItem(name: 'Ajvar', description: 'Roasted red pepper and eggplant relish', emoji: '\u{1FAD9}'),
      CountryItem(name: 'Rakija', description: 'Potent fruit brandy — the national spirit', emoji: '\u{1F943}'),
    ],
    activities: [
      CountryItem(name: 'Belgrade Nightlife', description: 'Party on the famous river barges (splavovi)', emoji: '\u{1F3B6}'),
      CountryItem(name: 'EXIT Festival', description: 'Attend Europe\'s premier music festival in Novi Sad', emoji: '\u{1F3B5}'),
      CountryItem(name: 'Tara Canyon', description: 'Raft through Europe\'s deepest river canyon', emoji: '\u{1F6F6}'),
      CountryItem(name: 'Rakija Tasting', description: 'Sample homemade fruit brandies in villages', emoji: '\u{1F943}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // BULGARIA
  // ══════════════════════════════════════════════════
  'europe-bulgaria': CountryDetail(
    cities: [
      CountryItem(name: 'Sofia', description: 'Ancient capital with Roman and Ottoman layers', emoji: '\u{1F3DB}', latitude: 42.6977, longitude: 23.3219),
      CountryItem(name: 'Plovdiv', description: 'One of the oldest continuously inhabited cities', emoji: '\u{1F3A8}', latitude: 42.1354, longitude: 24.7453),
      CountryItem(name: 'Veliko Tarnovo', description: 'Medieval capital perched above a gorge', emoji: '\u{1F3F0}', latitude: 43.0757, longitude: 25.6172),
      CountryItem(name: 'Varna', description: 'Black Sea resort city and cultural hub', emoji: '\u{1F3D6}', latitude: 43.2141, longitude: 27.9147),
    ],
    landmarks: [
      CountryItem(name: 'Alexander Nevsky Cathedral', description: 'Stunning gold-domed cathedral in Sofia', emoji: '\u{26EA}'),
      CountryItem(name: 'Rila Monastery', description: 'UNESCO-listed monastery in the mountains', emoji: '\u{26EA}'),
      CountryItem(name: 'Tsarevets Fortress', description: 'Medieval fortress in Veliko Tarnovo', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Plovdiv Old Town', description: 'Colorful Revival-era houses on ancient streets', emoji: '\u{1F3E0}'),
    ],
    food: [
      CountryItem(name: 'Shopska Salad', description: 'Fresh tomato, cucumber, and sirene cheese salad', emoji: '\u{1F957}'),
      CountryItem(name: 'Banitsa', description: 'Flaky filo pastry filled with cheese and eggs', emoji: '\u{1F950}'),
      CountryItem(name: 'Kebapche', description: 'Grilled spiced minced meat sausages', emoji: '\u{1F356}'),
      CountryItem(name: 'Yogurt', description: 'The original Bulgarian yogurt culture', emoji: '\u{1F95B}'),
    ],
    activities: [
      CountryItem(name: 'Rila Monastery Visit', description: 'Explore Bulgaria\'s most famous monastery', emoji: '\u{26EA}'),
      CountryItem(name: 'Black Sea Beaches', description: 'Relax on golden sand beaches along the coast', emoji: '\u{1F3D6}'),
      CountryItem(name: 'Rose Valley', description: 'Visit during the rose harvest festival', emoji: '\u{1F339}'),
      CountryItem(name: 'Seven Rila Lakes', description: 'Hike to glacial lakes in the Rila Mountains', emoji: '\u{1F3D4}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // CYPRUS
  // ══════════════════════════════════════════════════
  'europe-cyprus': CountryDetail(
    cities: [
      CountryItem(name: 'Nicosia', description: 'World\'s last divided capital city', emoji: '\u{1F3D9}', latitude: 35.1856, longitude: 33.3823),
      CountryItem(name: 'Limassol', description: 'Coastal city with ancient ruins and modern marina', emoji: '\u{26F5}', latitude: 34.7071, longitude: 33.0226),
      CountryItem(name: 'Paphos', description: 'Mythical birthplace of Aphrodite', emoji: '\u{1F3DB}', latitude: 34.7754, longitude: 32.4218),
      CountryItem(name: 'Ayia Napa', description: 'Party capital with crystal-clear beaches', emoji: '\u{1F3D6}', latitude: 34.9826, longitude: 34.0078),
    ],
    landmarks: [
      CountryItem(name: 'Paphos Archaeological Park', description: 'Roman mosaics and ancient ruins', emoji: '\u{1F3DB}'),
      CountryItem(name: 'Aphrodite\'s Rock', description: 'Legendary birthplace of the goddess of love', emoji: '\u{1FAA8}'),
      CountryItem(name: 'Kyrenia Castle', description: 'Crusader castle on the northern coast', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Troodos Mountains', description: 'Painted churches and mountain trails', emoji: '\u{1F3D4}'),
    ],
    food: [
      CountryItem(name: 'Halloumi', description: 'Grilled Cypriot cheese — famous worldwide', emoji: '\u{1F9C0}'),
      CountryItem(name: 'Meze', description: 'Endless small plates of Cypriot specialties', emoji: '\u{1F372}'),
      CountryItem(name: 'Souvlaki', description: 'Charcoal-grilled meat in fresh pita', emoji: '\u{1F356}'),
      CountryItem(name: 'Loukoumades', description: 'Honey-soaked doughnut bites with cinnamon', emoji: '\u{1F369}'),
    ],
    activities: [
      CountryItem(name: 'Beach Hopping', description: 'Swim in turquoise Mediterranean coves', emoji: '\u{1F3D6}'),
      CountryItem(name: 'Troodos Hiking', description: 'Hike through cedar forests and waterfalls', emoji: '\u{1F3D4}'),
      CountryItem(name: 'Wine Tasting', description: 'Sample indigenous grape varieties in villages', emoji: '\u{1F377}'),
      CountryItem(name: 'Diving', description: 'Explore the Zenobia shipwreck and sea caves', emoji: '\u{1F93F}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // MALTA
  // ══════════════════════════════════════════════════
  'europe-malta': CountryDetail(
    cities: [
      CountryItem(name: 'Valletta', description: 'Tiny fortified capital packed with history', emoji: '\u{1F3F0}', latitude: 35.8989, longitude: 14.5146),
      CountryItem(name: 'Mdina', description: 'Silent City — medieval walled town', emoji: '\u{1F3F0}', latitude: 35.8853, longitude: 14.4029),
      CountryItem(name: 'Sliema', description: 'Modern waterfront promenade and shopping', emoji: '\u{1F6CD}', latitude: 35.9122, longitude: 14.5026),
      CountryItem(name: 'Gozo', description: 'Quieter sister island with rural charm', emoji: '\u{1F3DD}', latitude: 36.0444, longitude: 14.2518),
    ],
    landmarks: [
      CountryItem(name: 'St. John\'s Co-Cathedral', description: 'Ornate baroque cathedral by the Knights', emoji: '\u{26EA}'),
      CountryItem(name: 'Ħaġar Qim Temples', description: 'Prehistoric megalithic temples older than Stonehenge', emoji: '\u{1FAA8}'),
      CountryItem(name: 'Blue Grotto', description: 'Sea caverns with brilliant blue waters', emoji: '\u{1F4A7}'),
      CountryItem(name: 'Upper Barrakka Gardens', description: 'Panoramic views and the Saluting Battery', emoji: '\u{1F3DE}'),
    ],
    food: [
      CountryItem(name: 'Pastizzi', description: 'Flaky pastry filled with ricotta or peas', emoji: '\u{1F950}'),
      CountryItem(name: 'Rabbit Stew', description: 'Malta\'s national dish — slow-cooked fennel rabbit', emoji: '\u{1F407}'),
      CountryItem(name: 'Ftira', description: 'Traditional Maltese sourdough flatbread', emoji: '\u{1F35E}'),
      CountryItem(name: 'Ġbejna', description: 'Small rounds of Gozitan sheep cheese', emoji: '\u{1F9C0}'),
    ],
    activities: [
      CountryItem(name: 'Harbour Cruise', description: 'Sail the Grand Harbour past fortifications', emoji: '\u{1F6F3}'),
      CountryItem(name: 'Diving', description: 'Explore shipwrecks and underwater caves', emoji: '\u{1F93F}'),
      CountryItem(name: 'Mdina Walk', description: 'Wander the atmospheric Silent City at dusk', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Gozo Day Trip', description: 'Ferry to Gozo for temples, beaches, and citadel', emoji: '\u{26F4}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // LUXEMBOURG
  // ══════════════════════════════════════════════════
  'europe-luxembourg': CountryDetail(
    cities: [
      CountryItem(name: 'Luxembourg City', description: 'Dramatic gorge capital of the Grand Duchy', emoji: '\u{1F3F0}', latitude: 49.6116, longitude: 6.1319),
      CountryItem(name: 'Vianden', description: 'Fairy-tale castle town in the Ardennes', emoji: '\u{1F3F0}', latitude: 49.9347, longitude: 6.2039),
      CountryItem(name: 'Echternach', description: 'Oldest town with a famous abbey', emoji: '\u{26EA}', latitude: 49.8115, longitude: 6.4215),
      CountryItem(name: 'Mullerthal', description: 'Luxembourg\'s Little Switzerland with rocky trails', emoji: '\u{1F3DE}', latitude: 49.7958, longitude: 6.3614),
    ],
    landmarks: [
      CountryItem(name: 'Casemates du Bock', description: 'Vast underground tunnels beneath the city', emoji: '\u{1F526}'),
      CountryItem(name: 'Vianden Castle', description: 'Stunning medieval castle above the Our River', emoji: '\u{1F3F0}'),
      CountryItem(name: 'Grand Ducal Palace', description: 'Official residence of the Grand Duke', emoji: '\u{1F451}'),
      CountryItem(name: 'Adolphe Bridge', description: 'Iconic stone arch bridge across the gorge', emoji: '\u{1F309}'),
    ],
    food: [
      CountryItem(name: 'Judd mat Gaardebounen', description: 'Smoked pork collar with broad beans', emoji: '\u{1F356}'),
      CountryItem(name: 'Gromperekichelcher', description: 'Crispy potato fritters with herbs', emoji: '\u{1F954}'),
      CountryItem(name: 'Quetschentaart', description: 'Traditional plum tart on buttery pastry', emoji: '\u{1F967}'),
      CountryItem(name: 'Riesling Wine', description: 'Excellent Moselle valley white wines', emoji: '\u{1F377}'),
    ],
    activities: [
      CountryItem(name: 'Casemates Tour', description: 'Explore the 17 km of underground tunnels', emoji: '\u{1F526}'),
      CountryItem(name: 'Mullerthal Trail', description: 'Hike through mossy gorges and rock formations', emoji: '\u{1F3DE}'),
      CountryItem(name: 'Moselle Wine Route', description: 'Taste Riesling along the Moselle River', emoji: '\u{1F377}'),
      CountryItem(name: 'Castle Tour', description: 'Visit fairy-tale castles across the Ardennes', emoji: '\u{1F3F0}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // USA (Americas destinations share this)
  // ══════════════════════════════════════════════════
  'americas-nyc': CountryDetail(
    cities: [
      CountryItem(name: 'Manhattan', description: 'The heart of New York — skyscrapers and Broadway', emoji: '\u{1F306}'),
      CountryItem(name: 'Brooklyn', description: 'Hip borough with art, food, and the famous bridge', emoji: '\u{1F309}'),
      CountryItem(name: 'Times Square', description: 'The dazzling crossroads of the world', emoji: '\u{2728}'),
      CountryItem(name: 'Central Park', description: '843 acres of green in the middle of the city', emoji: '\u{1F333}'),
    ],
    landmarks: [
      CountryItem(name: 'Statue of Liberty', description: 'Iconic symbol of freedom on Liberty Island', emoji: '\u{1F5FD}'),
      CountryItem(name: 'Empire State Building', description: 'Art Deco skyscraper with panoramic views', emoji: '\u{1F3D9}'),
      CountryItem(name: 'Brooklyn Bridge', description: 'Historic suspension bridge over the East River', emoji: '\u{1F309}'),
      CountryItem(name: '9/11 Memorial', description: 'Moving tribute at the World Trade Center site', emoji: '\u{1F54A}'),
    ],
    food: [
      CountryItem(name: 'New York Pizza', description: 'Thin crust, foldable slices from corner shops', emoji: '\u{1F355}'),
      CountryItem(name: 'Bagel & Lox', description: 'Classic NYC bagel with cream cheese and smoked salmon', emoji: '\u{1F96F}'),
      CountryItem(name: 'Cheesecake', description: 'Creamy New York-style cheesecake', emoji: '\u{1F370}'),
      CountryItem(name: 'Hot Dog', description: 'Iconic street cart hot dog with mustard', emoji: '\u{1F32D}'),
    ],
    activities: [
      CountryItem(name: 'Broadway Show', description: 'See a world-class musical on Broadway', emoji: '\u{1F3AD}'),
      CountryItem(name: 'Ferry to Liberty', description: 'Take the ferry to the Statue of Liberty', emoji: '\u{26F4}'),
      CountryItem(name: 'High Line Walk', description: 'Stroll the elevated park on old rail tracks', emoji: '\u{1F6B6}'),
      CountryItem(name: 'Museum Mile', description: 'Visit the Met, Guggenheim, and more', emoji: '\u{1F5BC}'),
    ],
  ),

  // ══════════════════════════════════════════════════
  // UNITED STATES (combined card for all Americas)
  // ══════════════════════════════════════════════════
  'americas-usa': CountryDetail(
    cities: [
      CountryItem(name: 'New York City', description: 'The city that never sleeps — skyscrapers, Broadway & pizza', emoji: '\u{1F5FD}'),
      CountryItem(name: 'Los Angeles', description: 'Hollywood, beaches, and endless sunshine', emoji: '\u{1F3AC}'),
      CountryItem(name: 'San Francisco', description: 'Golden Gate, cable cars, and tech hub', emoji: '\u{1F309}'),
      CountryItem(name: 'Miami', description: 'Art Deco, Latin culture, and tropical beaches', emoji: '\u{1F334}'),
      CountryItem(name: 'Honolulu', description: 'Tropical paradise on the island of Oahu', emoji: '\u{1F3DD}'),
    ],
    landmarks: [
      CountryItem(name: 'Statue of Liberty', description: 'Iconic symbol of freedom on Liberty Island', emoji: '\u{1F5FD}'),
      CountryItem(name: 'Golden Gate Bridge', description: 'San Francisco\'s iconic red suspension bridge', emoji: '\u{1F309}'),
      CountryItem(name: 'Grand Canyon', description: 'Vast, layered canyon carved by the Colorado River', emoji: '\u{1F3DC}'),
      CountryItem(name: 'Hollywood Sign', description: 'The world-famous hillside letters', emoji: '\u{1F3AC}'),
    ],
    food: [
      CountryItem(name: 'New York Pizza', description: 'Thin crust, foldable slices from corner shops', emoji: '\u{1F355}'),
      CountryItem(name: 'In-N-Out Burger', description: 'California\'s beloved burger chain', emoji: '\u{1F354}'),
      CountryItem(name: 'Key Lime Pie', description: 'Tangy custard pie from the Florida Keys', emoji: '\u{1F967}'),
      CountryItem(name: 'Poke Bowl', description: 'Fresh Hawaiian raw fish bowl', emoji: '\u{1F363}'),
    ],
    activities: [
      CountryItem(name: 'Broadway Show', description: 'See a world-class musical on Broadway', emoji: '\u{1F3AD}'),
      CountryItem(name: 'PCH Road Trip', description: 'Drive the Pacific Coast Highway', emoji: '\u{1F697}'),
      CountryItem(name: 'Grand Canyon Hike', description: 'Trek the rim or descend into the canyon', emoji: '\u{1F3DE}'),
      CountryItem(name: 'Surfing in Hawaii', description: 'Ride the legendary waves of the North Shore', emoji: '\u{1F3C4}'),
    ],
  ),

  'americas-california': CountryDetail(
    cities: [
      CountryItem(name: 'Los Angeles', description: 'Hollywood, beaches, and endless sunshine', emoji: '\u{1F3AC}'),
      CountryItem(name: 'San Francisco', description: 'Golden Gate, cable cars, and tech hub', emoji: '\u{1F309}'),
      CountryItem(name: 'San Diego', description: 'Perfect weather and stunning coastline', emoji: '\u{1F3D6}'),
      CountryItem(name: 'Santa Barbara', description: 'The American Riviera on the Pacific', emoji: '\u{1F334}'),
    ],
    landmarks: [
      CountryItem(name: 'Golden Gate Bridge', description: 'San Francisco\'s iconic red suspension bridge', emoji: '\u{1F309}'),
      CountryItem(name: 'Hollywood Sign', description: 'The world-famous hillside letters', emoji: '\u{1F3AC}'),
      CountryItem(name: 'Alcatraz Island', description: 'Former federal prison in SF Bay', emoji: '\u{1F3DA}'),
      CountryItem(name: 'Yosemite Valley', description: 'Granite cliffs and waterfalls', emoji: '\u{1F3D4}'),
    ],
    food: [
      CountryItem(name: 'Fish Tacos', description: 'Fresh Baja-style fish tacos from San Diego', emoji: '\u{1F32E}'),
      CountryItem(name: 'In-N-Out Burger', description: 'California\'s beloved burger chain', emoji: '\u{1F354}'),
      CountryItem(name: 'Avocado Toast', description: 'The quintessential California brunch', emoji: '\u{1F951}'),
      CountryItem(name: 'Sourdough Bread', description: 'San Francisco\'s tangy signature bread', emoji: '\u{1F35E}'),
    ],
    activities: [
      CountryItem(name: 'PCH Road Trip', description: 'Drive the Pacific Coast Highway', emoji: '\u{1F697}'),
      CountryItem(name: 'Surfing', description: 'Catch waves in Malibu or Huntington Beach', emoji: '\u{1F3C4}'),
      CountryItem(name: 'Wine Country', description: 'Tour Napa Valley vineyards', emoji: '\u{1F377}'),
      CountryItem(name: 'Disneyland', description: 'The happiest place on Earth in Anaheim', emoji: '\u{1F3F0}'),
    ],
  ),
};
