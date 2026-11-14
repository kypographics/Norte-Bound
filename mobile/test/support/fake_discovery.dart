import 'package:norte_bound/features/discovery/domain/destination_summary.dart';
import 'package:norte_bound/features/discovery/domain/lgu.dart';
import 'package:norte_bound/features/discovery/domain/taxonomy.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';

const fakeAdams = Lgu(
  lguCode: 'adams',
  name: 'Adams',
  lguType: 'municipality',
  tourismCluster: TourismClusterInfo.northernCoast,
  centerLatitude: 18.4622,
  centerLongitude: 120.9022,
  terrainType: 'mountainous_winding',
  isMajorHub: false,
  baselineDispersalBonus: 0.95,
);

const fakePagudpud = Lgu(
  lguCode: 'pagudpud',
  name: 'Pagudpud',
  lguType: 'municipality',
  tourismCluster: TourismClusterInfo.northernCoast,
  centerLatitude: 18.5614,
  centerLongitude: 120.7875,
  terrainType: 'flat_coastal',
  isMajorHub: true,
  baselineDispersalBonus: 1.2,
);

const fakeLaoag = Lgu(
  lguCode: 'laoag-city',
  name: 'Laoag City',
  lguType: 'component_city',
  tourismCluster: TourismClusterInfo.centralUrbanHeritage,
  centerLatitude: 18.1978,
  centerLongitude: 120.5936,
  terrainType: 'flat_coastal',
  isMajorHub: true,
  baselineDispersalBonus: 1.4,
);

const fakePaoay = Lgu(
  lguCode: 'paoay',
  name: 'Paoay',
  lguType: 'municipality',
  tourismCluster: TourismClusterInfo.southernHeritageCoast,
  centerLatitude: 18.1236,
  centerLongitude: 120.5242,
  terrainType: 'flat_coastal',
  isMajorHub: false,
  baselineDispersalBonus: 0.8,
);

const fakeBanna = Lgu(
  lguCode: 'banna',
  name: 'Banna (Espiritu)',
  lguType: 'municipality',
  tourismCluster: TourismClusterInfo.easternAgriHighland,
  centerLatitude: 17.9872,
  centerLongitude: 120.6556,
  terrainType: 'rolling_inland',
  isMajorHub: false,
  baselineDispersalBonus: 0.7,
);

const fakeLguDirectory = LguDirectory(
  clusters: [
    LguCluster(
      cluster: TourismClusterInfo.northernCoast,
      label: 'Northern Coast',
      lgus: [fakeAdams, fakePagudpud],
    ),
    LguCluster(
      cluster: TourismClusterInfo.centralUrbanHeritage,
      label: 'Central Heritage',
      lgus: [fakeLaoag],
    ),
    LguCluster(
      cluster: TourismClusterInfo.southernHeritageCoast,
      label: 'Southern Coast',
      lgus: [fakePaoay],
    ),
    LguCluster(
      cluster: TourismClusterInfo.easternAgriHighland,
      label: 'Eastern Highland',
      lgus: [fakeBanna],
    ),
  ],
);

const fakeTaxonomy = DestinationTaxonomy(
  categories: [
    CategoryItem(
      categoryCode: 'natural_attraction',
      name: 'Natural Attraction',
      description: 'Beaches, waterfalls, and mountain viewpoints.',
    ),
    CategoryItem(
      categoryCode: 'heritage_cultural',
      name: 'Heritage & Cultural',
      description: 'Churches, museums, and historic landmarks.',
    ),
    CategoryItem(
      categoryCode: 'food_culinary',
      name: 'Food & Culinary',
      description: 'Ilocano restaurants, cafes, and market food.',
    ),
    CategoryItem(
      categoryCode: 'agro_eco_tourism',
      name: 'Agro & Eco-Tourism',
      description: 'Farms, wind parks, and highland eco-parks.',
    ),
    CategoryItem(
      categoryCode: 'artisan_craft_experience',
      name: 'Artisan & Craft Experience',
      description: 'Pottery, weaving, and salt-making workshops.',
    ),
    CategoryItem(
      categoryCode: 'recreation_adventure',
      name: 'Recreation & Adventure',
      description: 'Dunes, surfing, trails, and kayaking.',
    ),
  ],
  interestTags: [
    InterestTag(
      tagSlug: 'historical',
      displayName: 'Historical Sites',
      categoryCode: 'heritage_cultural',
      aiSynonyms: ['history', 'colonial'],
    ),
  ],
);

const fakeHiddenGem = DestinationSummary(
  id: 1,
  slug: 'kaangrian-falls',
  name: 'Kaangrian Falls',
  lguCode: 'adams',
  lguName: 'Adams',
  tourismCluster: TourismClusterInfo.northernCoast,
  categoryCode: 'natural_attraction',
  categoryName: 'Natural Attraction',
  description: 'A forest waterfall reached by a quiet mountain trail.',
  address: 'Adams, Ilocos Norte',
  latitude: 18.4611,
  longitude: 120.9132,
  entityType: 'attraction',
  popularityTier: 'hidden_gem',
  highwayAccessible: false,
  verificationStatus: 'verified',
  pricing: DestinationPricing(isFree: true),
  tags: [DestinationTagRef(slug: 'beach', name: 'Beach & Coastline')],
);

const fakeIconic = DestinationSummary(
  id: 2,
  slug: 'paoay-church',
  name: 'Paoay Church',
  lguCode: 'paoay',
  lguName: 'Paoay',
  tourismCluster: TourismClusterInfo.southernHeritageCoast,
  categoryCode: 'heritage_cultural',
  categoryName: 'Heritage & Cultural',
  description: 'A UNESCO-listed Baroque church and national treasure.',
  address: 'Paoay, Ilocos Norte',
  latitude: 18.1216,
  longitude: 120.5223,
  entityType: 'attraction',
  popularityTier: 'iconic_hub',
  highwayAccessible: true,
  verificationStatus: 'verified',
  pricing: DestinationPricing(isFree: false, entranceFeeAdult: 30),
  tags: [DestinationTagRef(slug: 'unesco-heritage', name: 'UNESCO Heritage')],
);

const fakeCulinary = DestinationSummary(
  id: 3,
  slug: 'batac-empanada',
  name: 'Batac Riverside Empanada',
  lguCode: 'batac-city',
  lguName: 'Batac City',
  tourismCluster: TourismClusterInfo.southernHeritageCoast,
  categoryCode: 'food_culinary',
  categoryName: 'Food & Culinary',
  description: 'A riverside stop for crisp Ilocos empanada.',
  address: 'Batac City, Ilocos Norte',
  latitude: 18.0554,
  longitude: 120.5649,
  entityType: 'food_establishment',
  popularityTier: 'moderate',
  highwayAccessible: true,
  verificationStatus: 'verified',
  pricing: DestinationPricing(isFree: false, estimatedMealMin: 80),
  tags: [DestinationTagRef(slug: 'empanada', name: 'Ilocos Empanada')],
);

const fakeExploreFeed = ExploreFeed(
  iconicHighlights: [fakeIconic],
  hiddenGems: [fakeHiddenGem],
  culinaryStops: [fakeCulinary],
  lguDirectory: fakeLguDirectory,
);

const emptyExploreFeed = ExploreFeed(
  iconicHighlights: [],
  hiddenGems: [],
  culinaryStops: [],
  lguDirectory: fakeLguDirectory,
);

const fakeDestinationPage = DestinationPage(
  items: [fakeHiddenGem, fakeIconic, fakeCulinary],
  total: 3,
  page: 1,
  limit: 20,
  totalPages: 1,
);

const emptyDestinationPage = DestinationPage(
  items: [],
  total: 0,
  page: 1,
  limit: 20,
  totalPages: 0,
);

class FakeFilteredDestinationsNotifier extends FilteredDestinationsNotifier {
  FakeFilteredDestinationsNotifier(this.page);

  final DestinationPage page;

  @override
  Future<DestinationPage> build() async => page;
}
