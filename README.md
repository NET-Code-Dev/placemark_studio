# Placemark Studio

A modern Flutter desktop application for converting KML (Keyhole Markup Language) files to CSV format with advanced preview and customization options.

## Features

### 🚀 Core Functionality
- **KML to CSV Conversion**: Convert KML files to CSV format with high accuracy
- **Real-time Preview**: See a preview of your converted data before saving
- **Smart Duplicate Handling**: Automatically detect and handle duplicate headers
- **Extended Data Support**: Extract both basic placemark data and extended attributes
- **Table Data Extraction**: Parse HTML tables within KML descriptions

### 📊 Data Processing
- **Multiple Geometry Types**: Support for Points, LineStrings, and Polygons
- **Coordinate Extraction**: Longitude, latitude, and elevation data
- **Bounding Box Calculation**: Automatic spatial extent calculation
- **Field Detection**: Intelligent detection of available data fields

### 🎨 User Experience
- **Modern Material Design 3 UI**: Clean, intuitive interface
- **Responsive Layout**: Optimized for desktop workflows
- **Error Handling**: Comprehensive error messages and recovery options
- **File Validation**: Built-in validation for file size and format
- **Progress Indicators**: Visual feedback during processing

## Screenshots

*(Add screenshots of your application here)*

## Requirements

- **Flutter**: 3.0 or higher
- **Dart**: 2.17 or higher
- **Platform**: Windows, macOS, or Linux desktop

## Installation

### Build from Source

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd placemark-studio
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d macos    # For macOS
   flutter run -d linux    # For Linux
   ```

4. **Build for release**
   ```bash
   flutter build windows --release  # For Windows
   flutter build macos --release    # For macOS
   flutter build linux --release    # For Linux
   ```

## Usage

### Basic Conversion

1. **Select KML File**
   - Click "Browse Files" to select your KML file
   - Supported file size: Up to 50MB
   - File validation ensures format compatibility

2. **Preview Data**
   - View the first 5 rows of converted data
   - Check field headers and data types
   - Verify coordinate extraction

3. **Handle Duplicates** (if any)
   - Review detected duplicate headers
   - Choose which duplicates to keep or remove
   - Headers will be automatically numbered if kept

4. **Convert and Save**
   - Click "Convert File" to process
   - Choose output location (defaults to input file directory)
   - Receive confirmation with file path

### Advanced Features

#### File Information Panel
View detailed information about your KML file:
- File name and size
- Number of features and layers
- Coordinate system details
- Geometry type distribution
- Available data fields

#### Bounding Box Preview
- Visual representation of data extent
- Coordinate boundaries (North, South, East, West)
- Center point calculation
- Spatial dimensions

#### Export Options
- **Format Selection**: Currently supports CSV (more formats planned)
- **Output Path**: Custom save location
- **Header Options**: Include/exclude headers
- **Field Selection**: Choose specific fields to export

## File Format Support

### Input Formats
- **KML (.kml)**: Keyhole Markup Language files
  - Standard KML geometries (Point, LineString, Polygon)
  - Extended Data elements
  - HTML tables in descriptions
  - Style references

### Output Formats
- **CSV (.csv)**: Comma Separated Values
  - Customizable delimiters
  - Proper escaping of special characters
  - Header row options

### Planned Formats
- GeoJSON (.geojson)
- Shapefile (.shp)
- Excel (.xlsx)
- GPX (.gpx)

## Architecture

The application follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── app/                    # Application configuration
│   └── themes/            # Theme and styling
├── core/                  # Core utilities and constants
│   ├── constants/         # Application constants
│   ├── di/               # Dependency injection
│   ├── enums/            # Enumerations
│   ├── errors/           # Error handling
│   └── utils/            # Utility functions
├── data/                  # Data layer
│   ├── models/           # Data models
│   └── services/         # Data services
├── presentation/          # UI layer
│   ├── viewmodels/       # Business logic
│   └── views/            # UI components
└── shared/               # Shared widgets and utilities
```

### Key Components

#### Services
- **FilePickerService**: File selection and validation
- **KmlParserService**: KML parsing and data extraction
- **CsvExportService**: CSV generation and export
- **BoundingBoxService**: Spatial calculations

#### ViewModels
- **HomeViewModel**: Main application logic
- **ExtractViewModel**: Data extraction operations
- **CreateViewModel**: KML creation functionality

#### Models
- **KmlData**: Complete KML file representation
- **Placemark**: Individual feature data
- **Geometry**: Spatial geometry information
- **Coordinate**: Geographic coordinates

## Development

### Development Setup

1. Clone the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request or merge request

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable names
- Add documentation for public APIs
- Maintain test coverage

## Testing

Run the test suite:

```bash
flutter test
```

Run tests with coverage:

```bash
flutter test --coverage
```

## Dependencies

### Core Dependencies
- `flutter`: Framework
- `provider`: State management
- `xml`: XML parsing
- `file_picker`: File selection
- `path`: Path manipulation
- `equatable`: Value equality

### Development Dependencies
- `flutter_test`: Testing framework
- `build_runner`: Code generation
- `flutter_lints`: Linting rules

## Limitations

- Maximum file size: 50MB
- Currently supports only KML input format
- Desktop platforms only (mobile support planned)
- CSV export only (additional formats in development)

## Roadmap

### Version 1.1
- [ ] Additional export formats (GeoJSON, Shapefile)
- [ ] Batch processing multiple files
- [ ] Advanced filtering options
- [ ] Custom coordinate system transformations

### Version 1.2
- [ ] Mobile platform support
- [ ] Cloud storage integration
- [ ] Real-time collaboration features
- [ ] Advanced styling options

### Version 2.0
- [ ] KML creation and editing
- [ ] Map visualization
- [ ] Spatial analysis tools
- [ ] Plugin architecture

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions or issues, please contact the development team or refer to the internal documentation.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- XML parsing by [xml package](https://pub.dev/packages/xml)
- File picking by [file_picker package](https://pub.dev/packages/file_picker)
- Icons from [Material Design Icons](https://material.io/icons/)

---

**Placemark Studio** - Simplifying geospatial data conversion