import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/features/discovery/domain/destination_summary.dart';
import 'package:norte_bound/features/discovery/domain/lgu.dart';
import 'package:norte_bound/features/discovery/domain/taxonomy.dart';

void main() {
  group('LguDirectory', () {
    test('parses grouped LGU clusters from the backend contract', () {
      final directory = LguDirectory.fromJson([
        {
          'cluster': 'northern_coast',
          'label': 'Northern Coast',
          'total': 2,
          'lgus': [
            {
              'code': 'adams',
              'name': 'Adams',
              'type': 'municipality',
              'coordinates': {'latitude': 18.4622, 'longitude': 120.9022},
              'terrainType': 'mountainous_winding',
              'roadTortuosityMultiplier': 1.58,
              'isMajorHub': false,
              'baselineDispersalBonus': 0.95,
            },
            {
              'code': 'laoag-city',
              'name': 'Laoag City',
              'type': 'component_city',
              'coordinates': {'latitude': 18.1978, 'longitude': 120.5936},
              'terrainType': 'flat_coastal',
              'roadTortuosityMultiplier': 1.1,
              'isMajorHub': true,
              'baselineDispersalBonus': 1.4,
            },
          ],
        },
      ]);

      expect(directory.totalLgus, 2);
      expect(directory.clusters.single.label, 'Northern Coast');
      expect(directory.lguByCode('adams')?.name, 'Adams');
      expect(directory.lguByCode('adams')?.centerLatitude, 18.4622);
      expect(directory.lguByCode('adams')?.typeLabel, 'Municipality');
      expect(directory.lguByCode('laoag-city')?.isCity, isTrue);
      expect(directory.lguByCode('laoag-city')?.isMajorHub, isTrue);
      expect(directory.lguByCode('missing'), isNull);
    });

    test('orders known circuits before unknown clusters', () {
      final directory = LguDirectory.fromJson([
        {'cluster': 'eastern_agri_highland', 'lgus': <Map<String, dynamic>>[]},
        {'cluster': 'custom_cluster', 'lgus': <Map<String, dynamic>>[]},
        {'cluster': 'northern_coast', 'lgus': <Map<String, dynamic>>[]},
      ]);

      expect(directory.orderedClusters.map((cluster) => cluster.cluster), [
        'northern_coast',
        'eastern_agri_highland',
        'custom_cluster',
      ]);
    });
  });

  group('DestinationTaxonomy', () {
    test('parses backend category and interest tag fields', () {
      final taxonomy = DestinationTaxonomy.fromJson({
        'categories': [
          {
            'code': 'food_culinary',
            'name': 'Food & Culinary',
            'description': 'Restaurants, cafes, and market food.',
          },
        ],
        'interestTags': [
          {
            'slug': 'empanada',
            'name': 'Ilocos Empanada',
            'categoryCode': 'food_culinary',
            'synonyms': ['batac empanada', 'orange empanada'],
          },
        ],
      });

      expect(taxonomy.categories.single.categoryCode, 'food_culinary');
      expect(taxonomy.categoryName('food_culinary'), 'Food & Culinary');
      expect(taxonomy.interestTags.single.tagSlug, 'empanada');
      expect(taxonomy.interestTags.single.aiSynonyms, hasLength(2));
    });
  });

  group('DestinationPage', () {
    test('parses nested summary records and pagination', () {
      final page = DestinationPage.fromJson({
        'success': true,
        'data': [
          {
            'id': 14,
            'slug': 'paoay-church',
            'name': 'Paoay Church',
            'lgu': {
              'code': 'paoay',
              'name': 'Paoay',
              'cluster': 'southern_heritage_coast',
            },
            'category': {
              'code': 'heritage_cultural',
              'name': 'Heritage & Cultural',
            },
            'description': 'A UNESCO-listed Baroque church.',
            'address': 'Paoay, Ilocos Norte',
            'coordinates': {'latitude': 18.1216, 'longitude': 120.5223},
            'entityType': 'attraction',
            'popularityTier': 'iconic_hub',
            'highwayAccessible': true,
            'verification': {'status': 'verified'},
            'pricing': {
              'entranceFeeAdult': 30,
              'estimatedMealMin': null,
              'estimatedMealMax': null,
              'isFree': false,
            },
            'tags': [
              {'slug': 'unesco-heritage', 'name': 'UNESCO Heritage'},
            ],
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': 41,
          'totalPages': 3,
          'hasNextPage': true,
        },
      });

      final destination = page.items.single;

      expect(destination.name, 'Paoay Church');
      expect(destination.lguName, 'Paoay');
      expect(destination.tourismCluster, 'southern_heritage_coast');
      expect(destination.clusterLabel, 'Southern Coast');
      expect(destination.categoryCode, 'heritage_cultural');
      expect(destination.latitude, 18.1216);
      expect(destination.isIconic, isTrue);
      expect(destination.verificationStatus, 'verified');
      expect(destination.priceLabel, '₱30/pax');
      expect(destination.tags.single.name, 'UNESCO Heritage');
      expect(page.total, 41);
      expect(page.totalPages, 3);
      expect(page.hasNextPage, isTrue);
    });

    test('supports flat fallback fields', () {
      final page = DestinationPage.fromJson({
        'data': [
          {
            'id': 2,
            'slug': 'free-stop',
            'name': 'Free Stop',
            'lguCode': 'adams',
            'lguName': 'Adams',
            'tourismCluster': 'northern_coast',
            'categoryCode': 'natural_attraction',
            'categoryName': 'Natural Attraction',
            'isFree': true,
            'verificationStatus': 'verified',
          },
        ],
        'pagination': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
      });

      final destination = page.items.single;

      expect(destination.lguCode, 'adams');
      expect(destination.categoryName, 'Natural Attraction');
      expect(destination.priceLabel, '₱0 Free');
    });

    test('uses verified rates when pricing is incomplete', () {
      const pricing = DestinationPricing(isFree: false);

      expect(pricing.priceLabel, 'Verified rates');
    });

    test('throws when the destination data is missing', () {
      expect(
        () => DestinationPage.fromJson({'pagination': <String, dynamic>{}}),
        throwsFormatException,
      );
    });
  });
}
