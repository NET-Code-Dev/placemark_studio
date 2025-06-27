import '../constants/app_constants.dart';
import '../../data/models/kml_folder.dart';

class FolderFileNamingHelper {
  static const int maxFileNameLength = 100;
  static const int maxPathDepthForFullName = 3;
  static const int maxFolderNameLength = 30;

  /// Generate a safe, descriptive filename for a folder
  static String generateFileName(
    KmlFolder folder,
    String fileExtension, {
    String parentPath = '',
    Map<String, int>? folderCounts,
    bool useSimpleNaming = false, // New parameter
  }) {
    String baseName;

    if (useSimpleNaming) {
      // Simple naming: just use the folder name
      baseName = _sanitizeFolderName(folder.name);

      // Add disambiguation if needed
      final counts = folderCounts ?? buildFolderCountMap(folder);
      final normalizedName = _normalizeFolderName(folder.name);
      if ((counts[normalizedName] ?? 0) > 1) {
        // Add a simple counter or depth indicator for duplicates
        baseName = '${baseName}_D${folder.depth}';
      }
    } else {
      // Smart hierarchical naming (existing logic)
      final counts = folderCounts ?? buildFolderCountMap(folder);
      final strategy = _selectNamingStrategy(folder, parentPath);
      baseName = _generateBaseName(folder, parentPath, strategy, counts);
      baseName = _addContextualInfo(baseName, folder);
    }

    // Ensure filename length is reasonable
    baseName = _ensureReasonableLength(baseName);

    return '$baseName$fileExtension';
  }

  /// Build a map of folder name frequencies for disambiguation
  static Map<String, int> buildFolderCountMap(KmlFolder rootFolder) {
    final counts = <String, int>{};

    void countFolders(KmlFolder folder) {
      final normalizedName = _normalizeFolderName(folder.name);
      counts[normalizedName] = (counts[normalizedName] ?? 0) + 1;

      for (final subFolder in folder.subFolders) {
        countFolders(subFolder);
      }
    }

    countFolders(rootFolder);
    return counts;
  }

  /// Select the best naming strategy based on folder structure
  static FileNamingStrategy _selectNamingStrategy(
    KmlFolder folder,
    String parentPath,
  ) {
    final pathDepth = parentPath.split('/').where((s) => s.isNotEmpty).length;
    final totalPathLength = parentPath.length + folder.name.length;

    if (pathDepth <= maxPathDepthForFullName && totalPathLength <= 50) {
      return FileNamingStrategy.fullPath;
    } else if (pathDepth <= 6) {
      return FileNamingStrategy.abbreviated;
    } else {
      return FileNamingStrategy.indexed;
    }
  }

  /// Generate base name using the selected strategy
  static String _generateBaseName(
    KmlFolder folder,
    String parentPath,
    FileNamingStrategy strategy,
    Map<String, int> folderCounts,
  ) {
    switch (strategy) {
      case FileNamingStrategy.fullPath:
        return _generateFullPathName(folder, parentPath);

      case FileNamingStrategy.abbreviated:
        return _generateAbbreviatedName(folder, parentPath, folderCounts);

      case FileNamingStrategy.indexed:
        return _generateIndexedName(folder, folderCounts);
    }
  }

  /// Full path strategy: folder1_subfolder2_targetfolder
  static String _generateFullPathName(KmlFolder folder, String parentPath) {
    final sanitizedFolderName = _sanitizeFolderName(folder.name);

    if (parentPath.isEmpty || folder.depth == 0) {
      return sanitizedFolderName;
    }

    final pathParts = parentPath.split('/').where((s) => s.isNotEmpty).toList();
    final sanitizedParts = pathParts.map(_sanitizeFolderName).toList();
    sanitizedParts.add(sanitizedFolderName);

    return sanitizedParts.join('_');
  }

  /// Abbreviated strategy: first_middle_last for long paths
  static String _generateAbbreviatedName(
    KmlFolder folder,
    String parentPath,
    Map<String, int> folderCounts,
  ) {
    final sanitizedFolderName = _sanitizeFolderName(folder.name);

    if (parentPath.isEmpty || folder.depth == 0) {
      return sanitizedFolderName;
    }

    final pathParts = parentPath.split('/').where((s) => s.isNotEmpty).toList();

    if (pathParts.length <= 2) {
      // Short path, use full path
      return _generateFullPathName(folder, parentPath);
    }

    // Long path, abbreviate
    final first = _sanitizeFolderName(pathParts.first);
    final last = _sanitizeFolderName(pathParts.last);
    final middleCount = pathParts.length - 2;

    String abbreviated;
    if (middleCount == 1) {
      abbreviated = '${first}_${_sanitizeFolderName(pathParts[1])}_${last}';
    } else {
      abbreviated = '${first}_${middleCount}lvl_${last}';
    }

    return '${abbreviated}_${sanitizedFolderName}';
  }

  /// Indexed strategy: depth-based indexing for very deep structures
  static String _generateIndexedName(
    KmlFolder folder,
    Map<String, int> folderCounts,
  ) {
    final sanitizedFolderName = _sanitizeFolderName(folder.name);
    final normalizedName = _normalizeFolderName(folder.name);

    // Check if name is unique
    if ((folderCounts[normalizedName] ?? 0) <= 1) {
      return 'D${folder.depth}_$sanitizedFolderName';
    }

    // Name is not unique, add position indicator
    return 'D${folder.depth}_${sanitizedFolderName}_${folder.hashCode.abs() % 1000}';
  }

  /// Add contextual information like placemark count and depth
  static String _addContextualInfo(String baseName, KmlFolder folder) {
    final contextParts = <String>[];

    // Add depth for very deep structures
    if (folder.depth > 5) {
      contextParts.add('L${folder.depth}');
    }

    // Add placemark count if significant
    if (folder.placemarks.isNotEmpty) {
      if (folder.placemarks.length == 1) {
        contextParts.add('1item');
      } else if (folder.placemarks.length < 100) {
        contextParts.add('${folder.placemarks.length}items');
      } else {
        contextParts.add('${(folder.placemarks.length / 100).round()}h');
      }
    }

    if (contextParts.isNotEmpty) {
      return '${baseName}_${contextParts.join('_')}';
    }

    return baseName;
  }

  /// Ensure filename length is reasonable for file systems
  static String _ensureReasonableLength(String fileName) {
    if (fileName.length <= maxFileNameLength) {
      return fileName;
    }

    // Safe truncation
    final maxLength = maxFileNameLength - 3; // Reserve space for '...'
    if (maxLength <= 0) return 'file'; // Fallback for very short limits

    return '${fileName.substring(0, maxLength)}...';
  }

  /// Sanitize folder name for file system compatibility while preserving readability
  static String _sanitizeFolderName(String name) {
    if (name.isEmpty) return 'unnamed';

    String sanitized = name
        // Only replace the truly invalid file system characters
        // Valid characters include: letters, numbers, spaces, hyphens, underscores, parentheses, brackets, periods
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        // Replace multiple spaces with single space, then convert to underscore
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        // Only replace spaces with underscores, preserve everything else including ()[].-
        .replaceAll(' ', '_')
        // Remove any double underscores that might have been created
        .replaceAll(RegExp(r'_+'), '_')
        // Clean up leading/trailing underscores
        .replaceAll(RegExp(r'^_|_$'), '');

    // Handle empty result after sanitization
    if (sanitized.isEmpty) return 'unnamed';

    // Safe substring operation - preserve original case and characters
    if (sanitized.length > maxFolderNameLength) {
      // Try to truncate at a natural boundary (underscore) if possible
      String truncated = sanitized.substring(0, maxFolderNameLength);
      int lastUnderscore = truncated.lastIndexOf('_');
      if (lastUnderscore > maxFolderNameLength * 0.7) {
        // If we can truncate at an underscore and still keep most of the name
        return truncated.substring(0, lastUnderscore);
      }
      return truncated;
    }

    return sanitized;
  }

  /// Normalize folder name for counting (case-insensitive, simplified) - used only for duplicate detection
  static String _normalizeFolderName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Generate a hierarchical path for a folder by traversing up the tree
  static String generateHierarchicalPath(
    KmlFolder targetFolder,
    KmlFolder rootFolder,
  ) {
    // Since KmlFolder doesn't have parent references, we need to search the tree
    final path = _findFolderPath(targetFolder, rootFolder, []);
    return path.join('/');
  }

  /// Recursively find the path to a target folder
  static List<String> _findFolderPath(
    KmlFolder targetFolder,
    KmlFolder currentFolder,
    List<String> currentPath,
  ) {
    // Add current folder to path (except for root)
    final pathSoFar =
        currentFolder.depth == 0
            ? currentPath
            : [...currentPath, currentFolder.name];

    // Check if we found the target folder
    if (_foldersAreEqual(currentFolder, targetFolder)) {
      return pathSoFar;
    }

    // Search in subfolders
    for (final subFolder in currentFolder.subFolders) {
      final result = _findFolderPath(targetFolder, subFolder, pathSoFar);
      if (result.isNotEmpty) {
        return result;
      }
    }

    // Not found in this branch
    return [];
  }

  /// Compare two folders for equality (since KmlFolder might not have proper equality)
  static bool _foldersAreEqual(KmlFolder folder1, KmlFolder folder2) {
    return folder1.name == folder2.name &&
        folder1.depth == folder2.depth &&
        folder1.placemarks.length == folder2.placemarks.length &&
        folder1.subFolders.length == folder2.subFolders.length;
  }

  /// Alternative method: generate path based on folder properties and context
  static String generatePathFromContext(KmlFolder folder, String parentPath) {
    if (parentPath.isEmpty || folder.depth == 0) {
      return folder.name;
    }
    return '$parentPath/${folder.name}';
  }
}

enum FileNamingStrategy {
  fullPath, // Use full folder path (for shallow structures)
  abbreviated, // Use abbreviated path (for medium depth)
  indexed, // Use depth-based indexing (for very deep structures)
}

// Example usage patterns:
// Shallow (≤3 levels): "FG_Non-Op_HP_(PODS).csv"
// Medium (4-6 levels): "Documents_2lvl_FG_Non-Op_HP_(PODS).csv" 
// Deep (7+ levels): "D7_FG_Non-Op_HP_(PODS)_5items.csv"