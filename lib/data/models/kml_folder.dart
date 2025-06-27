import 'package:equatable/equatable.dart';
import 'placemark.dart';

class KmlFolder extends Equatable {
  final String name;
  final String description;
  final List<KmlFolder> subFolders;
  final List<Placemark> placemarks;
  final String? styleUrl;
  final Map<String, dynamic> extendedData;
  final int depth; // Track nesting level

  const KmlFolder({
    required this.name,
    required this.description,
    this.subFolders = const [],
    this.placemarks = const [],
    this.styleUrl,
    this.extendedData = const {},
    this.depth = 0,
  });

  factory KmlFolder.empty() {
    return const KmlFolder(
      name: 'Root',
      description: '',
      placemarks: [],
      subFolders: [],
      extendedData: {},
      depth: 0,
    );
  }

  /// Get all placemarks recursively from this folder and all subfolders
  List<Placemark> getAllPlacemarks() {
    final allPlacemarks = <Placemark>[];
    allPlacemarks.addAll(placemarks);

    for (final folder in subFolders) {
      allPlacemarks.addAll(folder.getAllPlacemarks());
    }

    return allPlacemarks;
  }

  /// Get the full path of this folder (e.g., "Root/Level1/Level2")
  String getPath([String parentPath = '']) {
    return parentPath.isEmpty ? name : '$parentPath/$name';
  }

  /// Get all folder paths recursively
  List<String> getAllFolderPaths([String parentPath = '']) {
    final paths = <String>[];
    final currentPath = getPath(parentPath);
    paths.add(currentPath);

    for (final folder in subFolders) {
      paths.addAll(folder.getAllFolderPaths(currentPath));
    }

    return paths;
  }

  /// Get the maximum depth of nested folders
  int getMaxDepth() {
    if (subFolders.isEmpty) return depth;

    return subFolders
        .map((f) => f.getMaxDepth())
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get total count of all subfolders recursively
  int getTotalFolderCount() {
    int count = 1; // Count this folder
    for (final folder in subFolders) {
      count += folder.getTotalFolderCount();
    }
    return count;
  }

  /// Get total count of all placemarks recursively
  int getTotalPlacemarkCount() {
    int count = placemarks.length;
    for (final folder in subFolders) {
      count += folder.getTotalPlacemarkCount();
    }
    return count;
  }

  /// Find a folder by path
  KmlFolder? findFolderByPath(String path) {
    if (getPath() == path) return this;

    for (final folder in subFolders) {
      final found = folder.findFolderByPath(path);
      if (found != null) return found;
    }

    return null;
  }

  /// Get folders at a specific depth level
  List<KmlFolder> getFoldersAtDepth(int targetDepth) {
    if (depth == targetDepth) return [this];

    final folders = <KmlFolder>[];
    for (final folder in subFolders) {
      folders.addAll(folder.getFoldersAtDepth(targetDepth));
    }

    return folders;
  }

  /// Check if this folder has any placemarks (direct or in subfolders)
  bool get hasPlacemarks => getTotalPlacemarkCount() > 0;

  /// Check if this folder is empty (no placemarks and no subfolders)
  bool get isEmpty => placemarks.isEmpty && subFolders.isEmpty;

  /// Get a summary of this folder's contents
  Map<String, dynamic> getSummary() {
    return {
      'name': name,
      'depth': depth,
      'directPlacemarks': placemarks.length,
      'totalPlacemarks': getTotalPlacemarkCount(),
      'subFolders': subFolders.length,
      'totalFolders': getTotalFolderCount() - 1, // Exclude self
      'maxDepth': getMaxDepth(),
      'path': getPath(),
    };
  }

  KmlFolder copyWith({
    String? name,
    String? description,
    List<KmlFolder>? subFolders,
    List<Placemark>? placemarks,
    String? styleUrl,
    Map<String, dynamic>? extendedData,
    int? depth,
  }) {
    return KmlFolder(
      name: name ?? this.name,
      description: description ?? this.description,
      subFolders: subFolders ?? this.subFolders,
      placemarks: placemarks ?? this.placemarks,
      styleUrl: styleUrl ?? this.styleUrl,
      extendedData: extendedData ?? this.extendedData,
      depth: depth ?? this.depth,
    );
  }

  @override
  List<Object?> get props => [
    name,
    description,
    subFolders,
    placemarks,
    styleUrl,
    extendedData,
    depth,
  ];
}
