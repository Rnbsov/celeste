import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plant_model.dart';
import '../services/plant_service.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

enum PlantTypeSelectorStep {
  typeSelection, // Grid of plant types
  typeDetails, // Details view with confirm button
  plantForm, // Rest of the form
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _substrateController = TextEditingController();

  DateTime _sowingDate = DateTime.now();
  DateTime _expectedHarvestDate = DateTime.now().add(const Duration(days: 60));
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _substrateController.dispose();
    super.dispose();
  }

  // Current selection step
  PlantTypeSelectorStep _currentStep = PlantTypeSelectorStep.typeSelection;

  String _selectedPlantType = 'Vegetable'; // Default

  // Your plant types data remains the same

  // Get the currently selected plant type map
  Map<String, dynamic> get _selectedPlantTypeInfo {
    return _plantTypes.firstWhere(
      (type) => type['name'] == _selectedPlantType,
      orElse: () => _plantTypes[0],
    );
  }

  // Add plant type selection

  // Define detailed plant types
  final List<Map<String, dynamic>> _plantTypes = [
    {
      'name': 'Vegetable',
      'icon': Icons.eco,
      'color': Colors.green,
      'description':
          'Edible plants grown for their leaves, stems, roots, or fruits.',
      'properties': {
        'Water needs': 'Medium',
        'Light': 'Full sun (6+ hours)',
        'Growth period': '2-4 months',
        'Beginner friendly': 'Yes',
      },
      'examples': ['Tomatoes', 'Carrots', 'Lettuce', 'Peppers', 'Beans'],
    },
    {
      'name': 'Fruit',
      'icon': Icons.spa,
      'color': Colors.orange,
      'description': 'Plants that produce sweet or tangy edible fruits.',
      'properties': {
        'Water needs': 'Medium to High',
        'Light': 'Full sun (6+ hours)',
        'Growth period': '3-12 months',
        'Beginner friendly': 'Moderate',
      },
      'examples': ['Strawberries', 'Blueberries', 'Melons', 'Citrus'],
    },
    {
      'name': 'Herb',
      'icon': Icons.grass,
      'color': Colors.teal,
      'description':
          'Aromatic plants used for flavoring, medicine, or fragrance.',
      'properties': {
        'Water needs': 'Low to Medium',
        'Light': 'Partial to full sun',
        'Growth period': '1-2 months',
        'Beginner friendly': 'Very',
      },
      'examples': ['Basil', 'Mint', 'Cilantro', 'Rosemary', 'Thyme'],
    },
    {
      'name': 'Flower',
      'icon': Icons.local_florist,
      'color': Colors.purple,
      'description': 'Ornamental plants grown for their colorful blooms.',
      'properties': {
        'Water needs': 'Varies by species',
        'Light': 'Full to partial sun',
        'Growth period': '1-6 months',
        'Beginner friendly': 'Moderate',
      },
      'examples': ['Roses', 'Sunflowers', 'Tulips', 'Marigolds', 'Zinnias'],
    },
    {
      'name': 'Succulent',
      'icon': Icons.filter_vintage,
      'color': Colors.lime,
      'description':
          'Plants with thick, fleshy tissues adapted to water storage.',
      'properties': {
        'Water needs': 'Very Low',
        'Light': 'Bright indirect light',
        'Growth period': 'Slow growing',
        'Beginner friendly': 'Very',
      },
      'examples': ['Aloe Vera', 'Echeveria', 'Jade Plant', 'Haworthia'],
    },
    {
      'name': 'Tree',
      'icon': Icons.park,
      'color': Colors.brown,
      'description': 'Woody perennial plants with an elongated stem/trunk.',
      'properties': {
        'Water needs': 'Medium',
        'Light': 'Full sun',
        'Growth period': 'Years',
        'Beginner friendly': 'No',
      },
      'examples': ['Apple', 'Lemon', 'Bonsai', 'Avocado', 'Fig'],
    },
    {
      'name': 'Indoor',
      'icon': Icons.home,
      'color': Colors.blueGrey,
      'description':
          'Plants well-suited for indoor environments with less light.',
      'properties': {
        'Water needs': 'Low to Medium',
        'Light': 'Indirect light',
        'Growth period': 'Varies',
        'Beginner friendly': 'Yes',
      },
      'examples': ['Peace Lily', 'Snake Plant', 'Pothos', 'Spider Plant'],
    },
  ];

  // UI for plant type selector
  Widget _buildPlantTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plant Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Horizontal scrolling type selector
        Container(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _plantTypes.length,
            itemBuilder: (context, index) {
              final type = _plantTypes[index];
              final isSelected = type['name'] == _selectedPlantType;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlantType = type['name'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 90,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? type['color'].withOpacity(0.2)
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? type['color']
                                : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'],
                          size: 36,
                          color: isSelected ? type['color'] : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? type['color']
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Plant type details
        _buildPlantTypeDetails(),
      ],
    );
  }

  // Plant type details section
  Widget _buildPlantTypeDetails() {
    final info = _selectedPlantTypeInfo;
    final properties = info['properties'] as Map<String, dynamic>;
    final examples = info['examples'] as List<dynamic>;

    return Card(
      margin: EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: info['color'].withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and icon
            Row(
              children: [
                Icon(info['icon'], color: info['color'], size: 24),
                SizedBox(width: 8),
                Text(
                  info['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Divider(height: 24),

            // Description
            Text(
              info['description'],
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 16),

            // Properties
            Text(
              'Properties',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            ...properties.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Examples
            Text(
              'Examples',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  examples
                      .map(
                        (example) => Chip(
                          label: Text(example),
                          backgroundColor: info['color'].withOpacity(0.1),
                          labelStyle: TextStyle(color: info['color']),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isSowingDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isSowingDate ? _sowingDate : _expectedHarvestDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isSowingDate) {
          _sowingDate = picked;
          if (_expectedHarvestDate.isBefore(_sowingDate)) {
            _expectedHarvestDate = _sowingDate.add(const Duration(days: 60));
          }
        } else {
          _expectedHarvestDate = picked;
        }
      });
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = PlantService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final newPlant = {
        'name': _nameController.text.trim(),
        'sowing_date': _sowingDate.toIso8601String().split('T')[0],
        'substrate':
            _substrateController.text.trim().isEmpty
                ? ""
                : _substrateController.text.trim(),
        'expected_harvest_date':
            _expectedHarvestDate.toIso8601String().split('T')[0],
        'user_id': userId,
        'plant_type': _selectedPlantType, // Add the plant type
      };

      await PlantService.createPlant(newPlant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Existing error handling
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving plant: ${e.toString()}';
          print(_errorMessage);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == PlantTypeSelectorStep.plantForm
              ? 'Add New Plant'
              : 'Select Plant Type',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Show back button for type details step
        leading:
            _currentStep == PlantTypeSelectorStep.typeDetails
                ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _currentStep = PlantTypeSelectorStep.typeSelection;
                    });
                  },
                )
                : null,
      ),
      body: SafeArea(
        child:
            _currentStep == PlantTypeSelectorStep.plantForm
                ? _buildPlantForm()
                : _buildPlantTypeSelectionFlow(),
      ),
    );
  }

  Widget _buildPlantTypeSelectionFlow() {
    switch (_currentStep) {
      case PlantTypeSelectorStep.typeSelection:
        return _buildPlantTypeGrid();
      case PlantTypeSelectorStep.typeDetails:
        return _buildPlantTypeDetailView();
      default:
        return Container(); // Should never happen
    }
  }

  Widget _buildPlantTypeGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of plant are you growing?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Select a category that best matches your plant',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          SizedBox(height: 24),

          // Grid of plant type cards
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _plantTypes.length,
              itemBuilder: (context, index) {
                final type = _plantTypes[index];
                return _buildPlantTypeCard(type);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTypeDetailView() {
    final info = _selectedPlantTypeInfo;
    final properties = info['properties'] as Map<String, dynamic>;
    final examples = info['examples'] as List<dynamic>;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: info['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info['icon'], size: 32, color: info['color']),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['name'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plant Type',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // Description card
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ${info['name']} Plants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      info['description'],
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Properties card
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth Properties',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...properties.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: info['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${entry.key}: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(entry.value, style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Examples card
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Examples',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          examples
                              .map(
                                (example) => Chip(
                                  label: Text(example),
                                  backgroundColor: info['color'].withOpacity(
                                    0.1,
                                  ),
                                  labelStyle: TextStyle(color: info['color']),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = PlantTypeSelectorStep.plantForm;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: info['color'],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue with ${info['name']}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantForm() {
    final info = _selectedPlantTypeInfo;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selected plant type banner
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: info['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: info['color'].withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(info['icon'], color: info['color']),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: info['color'],
                          ),
                        ),
                        Text(
                          'Plant Type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentStep = PlantTypeSelectorStep.typeSelection;
                        });
                      },
                      child: Text('Change'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Keep your existing form fields
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a plant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Substrate field
              TextFormField(
                controller: _substrateController,
                decoration: InputDecoration(
                  labelText: 'Substrate (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.landscape),
                ),
              ),
              const SizedBox(height: 16),

              // Sowing date field
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Sowing Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('MMMM d, y').format(_sowingDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Expected harvest date field
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expected Harvest Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.event),
                  ),
                  child: Text(
                    DateFormat('MMMM d, y').format(_expectedHarvestDate),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _savePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: info['color'],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Save Plant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantTypeCard(Map<String, dynamic> type) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedPlantType = type['name'];
            _currentStep = PlantTypeSelectorStep.typeDetails;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type['icon'], size: 48, color: type['color']),
              SizedBox(height: 8),
              Text(
                type['name'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                (type['examples'] as List).take(2).join(", "),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
