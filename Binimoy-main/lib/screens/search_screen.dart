import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'saree_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All';
  RangeValues _priceRange = const RangeValues(0, 50000);
  String _sortBy = 'price_asc';
  bool _isLoading = false;
  List<QueryDocumentSnapshot>? _searchResults;

  final List<String> _sareeTypes = [
    'All',
    'Jamdani',
    'Banarasi',
    'Silk',
    'Dola Silk',
    'Georgette',
    'Chiffon',
    'Leheriya',
    'Kanjeevaram',
    'Net',
    'Tussar Silk'
  ];

  void _applyFilters() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('sarees');

      // Apply search text
      if (_searchController.text.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: _searchController.text)
                    .where('name', isLessThan: _searchController.text + 'z');
      }

      // Apply type filter
      if (_selectedType != 'All') {
        query = query.where('type', isEqualTo: _selectedType);
      }

      // Apply price range
      query = query.where('price', isGreaterThanOrEqualTo: _priceRange.start)
                  .where('price', isLessThanOrEqualTo: _priceRange.end);

      // Apply sorting
      switch (_sortBy) {
        case 'price_asc':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_desc':
          query = query.orderBy('price', descending: true);
          break;
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
      }

      final snapshots = await query.get();
      setState(() => _searchResults = snapshots.docs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search sarees...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _applyFilters(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    hint: const Text('Select Type'),
                    items: _sareeTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Price: Low to High'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Price: High to Low'),
                      ),
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Newest First'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _sortBy = value!);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults == null
                    ? const Center(child: Text('Search for sarees'))
                    : _searchResults!.isEmpty
                        ? const Center(child: Text('No results found'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _searchResults!.length,
                            itemBuilder: (context, index) {
                              final saree = {
                                ..._searchResults![index].data() as Map<String, dynamic>,
                                'id': _searchResults![index].id,
                              };

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SareeDetailScreen(saree: saree),
                                  ),
                                ),
                                child: Card(
                                  elevation: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          saree['imageUrl'] ?? '',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              saree['name'] ?? 'Unknown',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '৳${saree['price']}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Sarees'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Price Range'),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 50000,
                divisions: 50,
                labels: RangeLabels(
                  '৳${_priceRange.start.round()}',
                  '৳${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _priceRange = values);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}