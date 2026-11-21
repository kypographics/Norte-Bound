import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/features/discovery/domain/destination_detail.dart';
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

  group('DestinationDetail', () {
    test('parses full backend detail contract including verification, pricing, and schedule', () {
      final detail = DestinationDetail.fromJson({
        'id': 14,
        'slug': 'paoay-church',
        'name': 'Paoay Church',
        'lgu': {
          'code': 'paoay',
          'name': 'Paoay',
          'cluster': 'southern_heritage_coast',
          'type': 'municipality',
        },
        'category': {
          'code': 'heritage_cultural',
          'name': 'Heritage & Cultural',
          'description': 'Churches and historic landmarks.',
        },
        'description': 'A UNESCO-listed Earthquake Baroque church.',
        'historicalBackground': 'Built in 1710 using coral stones and bricks.',
        'address': 'Paoay, Ilocos Norte',
        'coordinates': {'latitude': 18.1216, 'longitude': 120.5223},
        'entityType': 'attraction',
        'popularityTier': 'iconic_hub',
        'highwayAccessible': true,
        'roadCondition': 'paved_highway',
        'verification': {
          'status': 'verified',
          'sourceName': 'Ilocos Norte Tourism Office',
          'sourceType': 'lgu_tourism_office',
          'lastVerifiedDate': '2026-10-01',
        },
        'pricing': {
          'entranceFeeAdult': 50,
          'entranceFeeConcession': 30,
          'mandatoryActivityFee': 100,
          'estimatedMealMin': 150,
          'estimatedMealMax': 350,
          'parkingFee': 25,
          'isFree': false,
          'currency': 'PHP',
        },
        'operatingHours': [
          {
            'dayOfWeek': 0,
            'dayName': 'Sunday',
            'openingTime': '06:00',
            'closingTime': '18:00',
            'is24Hours': false,
            'temporarilyClosed': false,
          },
          {
            'dayOfWeek': 1,
            'dayName': 'Monday',
            'openingTime': '08:00',
            'closingTime': '17:00',
            'is24Hours': false,
            'temporarilyClosed': false,
          },
        ],
        'tags': [
          {'slug': 'unesco-heritage', 'name': 'UNESCO Heritage'},
        ],
      });

      expect(detail.isIconic, isTrue);
      expect(detail.popularityLabel, 'Iconic Hub');
      expect(detail.verification.isVerified, isTrue);
      expect(detail.verification.sourceName, 'Ilocos Norte Tourism Office');
      expect(detail.verification.sourceTypeLabel, 'Lgu Tourism Office');
      expect(detail.verification.lastVerifiedDate, '2026-10-01');
      expect(detail.pricing.adultEntryLabel, '₱50');
      expect(detail.pricing.concessionEntryLabel, '₱30');
      expect(detail.pricing.mandatoryActivityLabel, '₱100');
      expect(detail.pricing.parkingLabel, '₱25');
      expect(detail.pricing.mealRangeLabel, '₱150–350');
      expect(detail.historicalBackground, contains('1710'));
      expect(detail.operatingHours, hasLength(2));

      // Monday (2026-11-16 is a Monday) at 10:30 -> Open Now
      final openStatus = detail.operationalStatusAt(DateTime(2026, 11, 16, 10, 30));
      expect(openStatus.isOpen, isTrue);
      expect(openStatus.label, 'Open Now');
      expect(openStatus.detailText, 'Closes at 17:00');

      // Monday at 19:00 -> Closed
      final closedStatus = detail.operationalStatusAt(DateTime(2026, 11, 16, 19, 0));
      expect(closedStatus.isOpen, isFalse);
      expect(closedStatus.label, 'Closed');
      expect(closedStatus.detailText, 'Closed for today');
    });

    test('computes 24-hour and temporarily closed operational statuses', () {
      final detail = DestinationDetail.fromJson({
        'id': 20,
        'slug': 'bangui-windmills',
        'name': 'Bangui Windmills',
        'lgu': {'code': 'bangui', 'name': 'Bangui', 'cluster': 'northern_coast'},
        'category': {'code': 'agro_eco_tourism', 'name': 'Agro & Eco-Tourism'},
        'popularityTier': 'hidden_gem',
        'verification': {'status': 'verified'},
        'pricing': {'isFree': true},
        'operatingHours': [
          {
            'dayOfWeek': 0,
            'dayName': 'Sunday',
            'is24Hours': true,
            'temporarilyClosed': false,
          },
          {
            'dayOfWeek': 1,
            'dayName': 'Monday',
            'openingTime': '08:00',
            'closingTime': '17:00',
            'is24Hours': false,
            'temporarilyClosed': true,
          },
        ],
      });

      final sundayStatus = detail.operationalStatusAt(DateTime(2026, 11, 15, 22, 0));
      expect(sundayStatus.isOpen, isTrue);
      expect(sundayStatus.detailText, 'Open 24 hours');

      final mondayStatus = detail.operationalStatusAt(DateTime(2026, 11, 16, 10, 0));
      expect(mondayStatus.isOpen, isFalse);
      expect(mondayStatus.isTemporarilyClosed, isTrue);
      expect(mondayStatus.detailText, 'Temporarily closed today');
    });
  });
}
