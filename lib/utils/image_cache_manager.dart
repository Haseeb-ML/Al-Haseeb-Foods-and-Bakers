import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageCacheManager {
  static const key = 'customImageCacheKey';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Cache files for 30 days
      maxNrOfCacheObjects: 500,             // Cache up to 500 images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
