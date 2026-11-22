import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DestinationArtworkStyle {
  const DestinationArtworkStyle({
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final IconData icon;
  final Color startColor;
  final Color endColor;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [startColor, endColor],
  );
}

DestinationArtworkStyle destinationStyleFor(String categoryCode) {
  return switch (categoryCode) {
    'natural_attraction' => const DestinationArtworkStyle(
      icon: CupertinoIcons.tree,
      startColor: Color(0xFF153425),
      endColor: Color(0xFF4E7C5E),
    ),
    'heritage_cultural' => const DestinationArtworkStyle(
      icon: CupertinoIcons.building_2_fill,
      startColor: Color(0xFF3B2A20),
      endColor: Color(0xFFA4694D),
    ),
    'food_culinary' => const DestinationArtworkStyle(
      icon: Icons.restaurant,
      startColor: Color(0xFF8C3B23),
      endColor: AppColors.terracotta,
    ),
    'agro_eco_tourism' => const DestinationArtworkStyle(
      icon: CupertinoIcons.sun_max,
      startColor: Color(0xFF314A2F),
      endColor: Color(0xFF8AA36F),
    ),
    'artisan_craft_experience' => const DestinationArtworkStyle(
      icon: CupertinoIcons.sparkles,
      startColor: Color(0xFF4A382A),
      endColor: Color(0xFFB48A66),
    ),
    'recreation_adventure' => const DestinationArtworkStyle(
      icon: CupertinoIcons.car,
      startColor: Color(0xFF1E3B48),
      endColor: Color(0xFF5D8DA0),
    ),
    _ => const DestinationArtworkStyle(
      icon: CupertinoIcons.compass,
      startColor: AppColors.deepForest,
      endColor: Color(0xFF335A3F),
    ),
  };
}

const _photos = (
  saudBeach:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Saud_Beach_-_panoramio.jpg/960px-Saud_Beach_-_panoramio.jpg',
  blueLagoon:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Approaching_storm._Hannah%27s_Beach_Resort_Philippines._%2815931900507%29.jpg/960px-Approaching_storm._Hannah%27s_Beach_Resort_Philippines._%2815931900507%29.jpg',
  patapat:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5f/Motorist_on_Patapat_Viaduct%2C_Pagudpud%2C_Ilocos_Norte_2021.jpg/960px-Motorist_on_Patapat_Viaduct%2C_Pagudpud%2C_Ilocos_Norte_2021.jpg',
  kabigan:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/Kabigan_Waterfalls_in_Pagudpud%2C_Ilocos_Norte.jpg/960px-Kabigan_Waterfalls_in_Pagudpud%2C_Ilocos_Norte.jpg',
  bantayAbot:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c9/Bantay_Abot_Cave_Pagudpud%2C_Ilocos_Norte_2021.jpg/960px-Bantay_Abot_Cave_Pagudpud%2C_Ilocos_Norte_2021.jpg',
  bangui:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Ilocos_Norte_Bangui_Windmills_LVS.jpg/960px-Ilocos_Norte_Bangui_Windmills_LVS.jpg',
  kapurpurawan:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/29/Kapurpurawan_Rock_Formation_Medium_shot_2021.jpg/960px-Kapurpurawan_Rock_Formation_Medium_shot_2021.jpg',
  bojeador:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/30/Cape_Bojeador_Lighthouse_Landscaped_Gardens.jpg/960px-Cape_Bojeador_Lighthouse_Landscaped_Gardens.jpg',
  sandDunes:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a5/La_Paz_Sand_Dunes_Scenery.jpg/960px-La_Paz_Sand_Dunes_Scenery.jpg',
  sinkingBell:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0e/Sinking_Bell_Tower%2C_Laoag%2C_Ilocos_Norte%2C_Apr_2025.jpg/960px-Sinking_Bell_Tower%2C_Laoag%2C_Ilocos_Norte%2C_Apr_2025.jpg',
  laoagCathedral:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/Laoag_Cathedral%2C_Ilocos_Norte%2C_Apr_2025.jpg/960px-Laoag_Cathedral%2C_Ilocos_Norte%2C_Apr_2025.jpg',
  capitolMuseum:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0e/Ilocos_Norte_Provincial_Capitol_05.jpg/960px-Ilocos_Norte_Provincial_Capitol_05.jpg',
  auroraPark:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/73/Fountain_at_Aurora_Park%2C_Laoag_City.jpg/960px-Fountain_at_Aurora_Park%2C_Laoag_City.jpg',
  bacarra:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/86/Bacarra_Church_Facade%2C_Bacarra%2C_Ilocos_Norte_2015.jpg/960px-Bacarra_Church_Facade%2C_Bacarra%2C_Ilocos_Norte_2015.jpg',
  sarrat:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/01/Sarrat_Church.jpg/960px-Sarrat_Church.jpg',
  paoayChurch:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/Paoay_Church_and_Bell_Tower.jpg/960px-Paoay_Church_and_Bell_Tower.jpg',
  malacanang:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/The_Malaca%C3%B1ang_of_the_North.jpg/960px-The_Malaca%C3%B1ang_of_the_North.jpg',
  paoayLake:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/31/Paoay_Lake%2C_Ilocos_Norte%2C_Apr_2025.jpg/960px-Paoay_Lake%2C_Ilocos_Norte%2C_Apr_2025.jpg',
  juanLuna:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/10/Luna_Shrine.jpg/960px-Luna_Shrine.jpg',
  badocChurch:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9e/Church_of_Badoc%2C_Ilocos_Norte.jpg/960px-Church_of_Badoc%2C_Ilocos_Norte.jpg',
  piddigChurch:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/34/Piddig_Church_in_2019.jpg/960px-Piddig_Church_in_2019.jpg',
  dingrasChurch:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b1/St._Joseph_Parish_Church_of_Dingras_1.JPG/960px-St._Joseph_Parish_Church_of_Dingras_1.JPG',
  ancestralHouse:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ae/Calle_Crisologo%2C_Vigan%2C_Ilocos_Norte.jpg/960px-Calle_Crisologo%2C_Vigan%2C_Ilocos_Norte.jpg',
  pottery:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4e/Pottery_%28Burnay%2C_Damdamili%29_Vigan_Ilocos_Sur.jpg/960px-Pottery_%28Burnay%2C_Damdamili%29_Vigan_Ilocos_Sur.jpg',
  inabel:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/73/Looms_2026-10-04_Ilocos_Norte.jpg/960px-Looms_2026-10-04_Ilocos_Norte.jpg',
  saltMaking:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/93/Marakkanam_Salt_Pans.JPG/960px-Marakkanam_Salt_Pans.JPG',
  empanada:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a7/Empanada_de_Vigan.jpg/960px-Empanada_de_Vigan.jpg',
  bagnet:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/Lechon_Kawali_-_BRUHA_2024-05-23.jpg/960px-Lechon_Kawali_-_BRUHA_2024-05-23.jpg',
  pinakbet:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cf/Pinakbet_ni_Lakay_Jesse.jpg/960px-Pinakbet_ni_Lakay_Jesse.jpg',
  mikiNoodles:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Lomi_with_egg_2.jpg/960px-Lomi_with_egg_2.jpg',
  bakery:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c1/Garlic_bread_baguettes_2.jpg/960px-Garlic_bread_baguettes_2.jpg',
  mountainRidge:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Cordillera_Panorama_from_the_Kabayan%E2%80%93Lusod_Ridge.jpg/960px-Cordillera_Panorama_from_the_Kabayan%E2%80%93Lusod_Ridge.jpg',
  damView:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/47/Magat_dam_crop.JPG/960px-Magat_dam_crop.JPG',
  forestStream:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/70/Starr-160919-5250-Cocos_nucifera-after_flooding_Forest_Iao_Tropical_Gardens_sidewalk_to_bridge-Iao_Stream-Maui_%2830420171784%29.jpg/960px-Starr-160919-5250-Cocos_nucifera-after_flooding_Forest_Iao_Tropical_Gardens_sidewalk_to_bridge-Iao_Stream-Maui_%2830420171784%29.jpg',
  dragonfruit:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/72/Pitaya%2CBambangjf6879_04.JPG/960px-Pitaya%2CBambangjf6879_04.JPG',
  coffeeFarm:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/94/Coffee_Coconuts_Pepper_Estate_Coorg_Feb24_A7C_09365.jpg/960px-Coffee_Coconuts_Pepper_Estate_Coorg_Feb24_A7C_09365.jpg',
  riceFarm:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/83/Rice_fields_in_Sacobia_-_panoramio.jpg/960px-Rice_fields_in_Sacobia_-_panoramio.jpg',
  garlic:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/61/Garlic_Bulbs_%28Unsplash%29.jpg/960px-Garlic_Bulbs_%28Unsplash%29.jpg',
  tribalVillage:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Traditional_stilt_houses_in_Bangaan_of_the_Ifugao_people.jpg/960px-Traditional_stilt_houses_in_Bangaan_of_the_Ifugao_people.jpg',
  coastalCove:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cf/Anawangin_Cove_at_Sunrise.jpg/960px-Anawangin_Cove_at_Sunrise.jpg',
  pagudpudWindBeach:
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/00/Pagudpud_Wind_Farm.jpg/960px-Pagudpud_Wind_Farm.jpg',
);

String destinationPhotoUrlFor({
  String? slug,
  String? name,
  required String categoryCode,
  String? imageUrl,
}) {
  if (imageUrl != null && imageUrl.isNotEmpty) return imageUrl;

  final key = '${slug ?? ''} ${name ?? ''}'.toLowerCase();
  final keywordMap = <(List<String>, String)>[
    (['patapat'], _photos.patapat),
    (['bantay-abot', 'bantay abot'], _photos.bantayAbot),
    (['blue-lagoon', 'blue lagoon', 'maira-ira'], _photos.blueLagoon),
    (['saud'], _photos.saudBeach),
    (['sentinela'], _photos.pagudpudWindBeach),
    (['windmill', 'bangui'], _photos.bangui),
    (['kapurpurawan', 'pangil', 'coral rock'], _photos.kapurpurawan),
    (['bojeador', 'lighthouse'], _photos.bojeador),
    (['kabigan', 'tanap avis', 'araruang', 'anuplig', 'falls'], _photos.kabigan),
    (['sand-dunes', 'sand dunes', 'culili', 'la paz'], _photos.sandDunes),
    (['sinking-bell', 'sinking bell', 'cathedral'], _photos.sinkingBell),
    (['paoay-church', 'paoay church', 'san agustin'], _photos.paoayChurch),
    (['paoay-lake', 'paoay lake'], _photos.paoayLake),
    (['malacanang', 'malacañang', 'ferdinand e. marcos'], _photos.malacanang),
    (['bacarra'], _photos.bacarra),
    (['santa monica', 'sarrat'], _photos.sarrat),
    (['juan-luna', 'juan luna'], _photos.juanLuna),
    (['badoc', 'milagrosa'], _photos.badocChurch),
    (['piddig', 'st. anthony', 'aglipay'], _photos.piddigChurch),
    (['dingras', 'ruins', 'bantay kampana'], _photos.dingrasChurch),
    (['aurora park', 'tobacco monopoly', 'ricarte'], _photos.auroraPark),
    (['museo ilocos', 'museum'], _photos.capitolMuseum),
    (['ancestral', 'edralin', 'valdes', 'crispina'], _photos.ancestralHouse),
    (['damili', 'pottery'], _photos.pottery),
    (['inabel', 'binakol', 'loomweaving', 'gamayo', 'weaving'], _photos.inabel),
    (['salt-making', 'salinas'], _photos.saltMaking),
    (['empanada'], _photos.empanada),
    (['dawang', 'bagnet', 'san nicolas heritage plaza'], _photos.bagnet),
    (['la preciosa', 'herencia', 'pinakbet'], _photos.pinakbet),
    (['miki'], _photos.mikiNoodles),
    (['biscocho', 'bakery'], _photos.bakery),
    (['dragonfruit'], _photos.dragonfruit),
    (['coffee'], _photos.coffeeFarm),
    (['garlic'], _photos.garlic),
    (['madongan', 'rice', 'banna', 'eco-tourism'], _photos.riceFarm),
    (['vintar dam', 'siwawer', 'daquioag', 'agro-forestry'], _photos.damView),
    (['isneg', 'tingguian', 'tribal', 'nueva-era', 'nueva era'], _photos.tribalVillage),
    (['lovers peak', 'palemlem', 'solsona', 'carasi', 'viewdeck'], _photos.mountainRidge),
    (['gaang'], _photos.coastalCove),
    (['agua grande', 'karinking', 'alingking', 'river', 'bugnay', 'picnic', 'spring'], _photos.forestStream),
  ];

  for (final (patterns, url) in keywordMap) {
    if (patterns.any(key.contains)) return url;
  }

  return switch (categoryCode) {
    'natural_attraction' => _photos.saudBeach,
    'heritage_cultural' => _photos.paoayChurch,
    'food_culinary' => _photos.empanada,
    'agro_eco_tourism' => _photos.bangui,
    'artisan_craft_experience' => _photos.inabel,
    'recreation_adventure' => _photos.sandDunes,
    _ => _photos.kapurpurawan,
  };
}

class DestinationArtwork extends StatelessWidget {
  const DestinationArtwork({
    super.key,
    required this.categoryCode,
    this.slug,
    this.name,
    this.imageUrl,
    this.borderRadius = 18,
    this.iconSize = 42,
  });

  final String categoryCode;
  final String? slug;
  final String? name;
  final String? imageUrl;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = destinationStyleFor(categoryCode);
    final photoUrl = destinationPhotoUrlFor(
      slug: slug,
      name: name,
      categoryCode: categoryCode,
      imageUrl: imageUrl,
    );
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    );

    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: style.gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -18,
              top: -22,
              child: Icon(
                style.icon,
                size: iconSize * 2.4,
                color: AppColors.ivorySand.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              left: -12,
              bottom: -20,
              child: Container(
                width: iconSize * 1.9,
                height: iconSize * 1.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warmSand.withValues(alpha: 0.08),
                ),
              ),
            ),
            Center(
              child: Container(
                width: iconSize * 1.35,
                height: iconSize * 1.35,
                decoration: ShapeDecoration(
                  color: AppColors.ivorySand.withValues(alpha: 0.14),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(iconSize * 0.42),
                    ),
                    side: BorderSide(
                      color: AppColors.ivorySand.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Icon(
                  style.icon,
                  size: iconSize,
                  color: AppColors.ivorySand,
                ),
              ),
            ),
            CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              httpHeaders: const {
                'User-Agent': 'NorteBoundApp/1.0 (https://nortebound.local)',
              },
              placeholder: (_, _) => const SizedBox.shrink(),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
