import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'core/di/service_locator.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: 'Placemark Studio',
      size: Size(800, 600),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize dependency injection
  await ServiceLocator.init();

  runApp(const PlacemarkStudioApp());
}


/*
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

void main() {
  runApp(const KMLConverterApp());
}

class KMLConverterApp extends StatelessWidget {
  const KMLConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KML to CSV Converter',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const KMLConverterHome(),
    );
  }
}

class KMLConverterHome extends StatefulWidget {
  const KMLConverterHome({super.key});

  @override
  State<KMLConverterHome> createState() => _KMLConverterHomeState();
}

class _KMLConverterHomeState extends State<KMLConverterHome> {
  File? selectedFile;
  bool isProcessing = false;
  String? errorMessage;
  String? successMessage;
  List<List<String>>? previewData;
  List<List<String>>? fullData;

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml'],
      );

      if (result != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
          errorMessage = null;
          successMessage = null;
          previewData = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> convertToCSV() async {
    if (selectedFile == null) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      // Read KML file
      String kmlContent = await selectedFile!.readAsString();

      // Parse KML and convert to CSV
      List<List<String>> csvData = await parseKMLToCSV(kmlContent);

      // Save CSV file
      String csvPath = selectedFile!.path.replaceAll('.kml', '.csv');
      await saveCsvFile(csvData, csvPath);

      setState(() {
        fullData = csvData;
        previewData = csvData.take(6).toList(); // Header + 5 rows
        successMessage = 'File converted successfully!\nSaved to: $csvPath';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error converting file: $e';
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<List<List<String>>> parseKMLToCSV(String kmlContent) async {
    final document = XmlDocument.parse(kmlContent);
    final placemarks = document.findAllElements('Placemark');

    if (placemarks.isEmpty) {
      throw Exception('No Placemarks found in KML file');
    }

    // Collect all possible headers
    Set<String> allHeaders = {
      'name',
      'description',
      'geometry_type',
      'longitude',
      'latitude',
      'elevation',
    };

    List<Map<String, dynamic>> features = [];

    for (var placemark in placemarks) {
      Map<String, dynamic> feature = {};

      // Extract basic properties
      feature['name'] =
          placemark.findElements('name').isNotEmpty
              ? placemark.findElements('name').first.innerText
              : '';
      feature['description'] =
          placemark.findElements('description').isNotEmpty
              ? placemark.findElements('description').first.innerText
              : '';

      // Extract geometry
      Map<String, dynamic> geometry = extractGeometry(placemark);
      feature.addAll(geometry);

      // Extract extended data
      var extendedData = placemark.findElements('ExtendedData');
      if (extendedData.isNotEmpty) {
        var dataElements = extendedData.first.findElements('Data');
        for (var data in dataElements) {
          String? name = data.getAttribute('name');
          String? value =
              data.findElements('value').isNotEmpty
                  ? data.findElements('value').first.innerText
                  : '';
          if (name != null) {
            feature[name] = value ?? '';
            allHeaders.add(name);
          }
        }
      }

      features.add(feature);
    }

    // Convert to CSV format
    List<String> headers = allHeaders.toList();
    List<List<String>> csvData = [headers];

    for (var feature in features) {
      List<String> row = [];
      for (String header in headers) {
        row.add(feature[header]?.toString() ?? '');
      }
      csvData.add(row);
    }

    return csvData;
  }

  Map<String, dynamic> extractGeometry(XmlElement placemark) {
    Map<String, dynamic> result = {
      'geometry_type': '',
      'longitude': '',
      'latitude': '',
      'elevation': '',
    };

    // Point
    var point = placemark.findElements('Point');
    if (point.isNotEmpty) {
      var coordinates = point.first.findElements('coordinates');
      if (coordinates.isNotEmpty) {
        List<double> coords =
            parseCoordinates(coordinates.first.innerText).first;
        result['geometry_type'] = 'Point';
        result['longitude'] = coords[0].toString();
        result['latitude'] = coords[1].toString();
        result['elevation'] = coords.length > 2 ? coords[2].toString() : '0';
      }
    }

    // LineString
    var lineString = placemark.findElements('LineString');
    if (lineString.isNotEmpty) {
      var coordinates = lineString.first.findElements('coordinates');
      if (coordinates.isNotEmpty) {
        List<List<double>> coords = parseCoordinates(
          coordinates.first.innerText,
        );
        if (coords.isNotEmpty) {
          result['geometry_type'] = 'LineString';
          result['longitude'] = coords.first[0].toString();
          result['latitude'] = coords.first[1].toString();
          result['elevation'] =
              coords.first.length > 2 ? coords.first[2].toString() : '0';
        }
      }
    }

    // Polygon
    var polygon = placemark.findElements('Polygon');
    if (polygon.isNotEmpty) {
      var outerRing = polygon.first.findElements('outerBoundaryIs');
      if (outerRing.isNotEmpty) {
        var linearRing = outerRing.first.findElements('LinearRing');
        if (linearRing.isNotEmpty) {
          var coordinates = linearRing.first.findElements('coordinates');
          if (coordinates.isNotEmpty) {
            List<List<double>> coords = parseCoordinates(
              coordinates.first.innerText,
            );
            if (coords.isNotEmpty) {
              result['geometry_type'] = 'Polygon';
              result['longitude'] = coords.first[0].toString();
              result['latitude'] = coords.first[1].toString();
              result['elevation'] =
                  coords.first.length > 2 ? coords.first[2].toString() : '0';
            }
          }
        }
      }
    }

    return result;
  }

  List<List<double>> parseCoordinates(String coordText) {
    return coordText
        .trim()
        .split(RegExp(r'\s+'))
        .where((coord) => coord.isNotEmpty)
        .map((coord) {
          List<String> parts = coord.split(',');
          return [
            double.parse(parts[0]), // longitude
            double.parse(parts[1]), // latitude
            parts.length > 2 ? double.parse(parts[2]) : 0.0, // elevation
          ];
        })
        .toList();
  }

  Future<void> saveCsvFile(List<List<String>> csvData, String filePath) async {
    String csvContent = csvData
        .map((row) {
          return row
              .map((cell) {
                // Escape quotes and wrap in quotes if contains comma, quote, or newline
                if (cell.contains(',') ||
                    cell.contains('"') ||
                    cell.contains('\n')) {
                  return '"${cell.replaceAll('"', '""')}"';
                }
                return cell;
              })
              .join(',');
        })
        .join('\n');

    File csvFile = File(filePath);
    await csvFile.writeAsString(csvContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KML to CSV Converter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File selection section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.file_upload, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Select KML File',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a KML file to convert to CSV format',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse Files'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected file info
            if (selectedFile != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(path.basename(selectedFile!.path)),
                  subtitle: FutureBuilder<FileStat>(
                    future: selectedFile!.stat(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        double sizeKB = snapshot.data!.size / 1024;
                        return Text('Size: ${sizeKB.toStringAsFixed(2)} KB');
                      }
                      return const Text('Loading...');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Convert button
            ElevatedButton(
              onPressed:
                  selectedFile != null && !isProcessing ? convertToCSV : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child:
                  isProcessing
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Converting...'),
                        ],
                      )
                      : const Text(
                        'Convert to CSV',
                        style: TextStyle(fontSize: 16),
                      ),
            ),

            const SizedBox(height: 16),

            // Error message
            if (errorMessage != null) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Success message
            if (successMessage != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Preview section
            if (previewData != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview (first 5 rows):',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns:
                                    previewData!.first
                                        .map(
                                          (header) => DataColumn(
                                            label: Text(
                                              header,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                rows:
                                    previewData!
                                        .skip(1)
                                        .map(
                                          (row) => DataRow(
                                            cells:
                                                row
                                                    .map(
                                                      (cell) =>
                                                          DataCell(Text(cell)),
                                                    )
                                                    .toList(),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
*/