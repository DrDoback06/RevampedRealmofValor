import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/card_model.dart';
import '../inventory/providers.dart';

class CardCollectionScreen extends ConsumerStatefulWidget {
  const CardCollectionScreen({super.key});

  @override
  ConsumerState<CardCollectionScreen> createState() => _CardCollectionScreenState();
}

class _CardCollectionScreenState extends ConsumerState<CardCollectionScreen> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Name';
  String _searchQuery = '';
  CardRarity? _selectedRarity;
  CardElement? _selectedElement;
  CardType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search cards...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Active Filters
          if (_selectedRarity != null || _selectedElement != null || _selectedType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  if (_selectedRarity != null)
                    Chip(
                      label: Text(_selectedRarity!.name),
                      onDeleted: () => setState(() => _selectedRarity = null),
                    ),
                  if (_selectedElement != null)
                    Chip(
                      label: Text('${_selectedElement!.name} ${_getElementIcon(_selectedElement!)}'),
                      onDeleted: () => setState(() => _selectedElement = null),
                    ),
                  if (_selectedType != null)
                    Chip(
                      label: Text(_selectedType!.name),
                      onDeleted: () => setState(() => _selectedType = null),
                    ),
                ],
              ),
            ),

          // Cards Grid
          Expanded(
            child: cardsAsync.when(
              data: (cards) {
                final filteredCards = _filterCards(cards);
                final sortedCards = _sortCards(filteredCards);

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: sortedCards.length,
                  itemBuilder: (context, index) {
                    final card = sortedCards[index];
                    return _buildCardWidget(card);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<GameCard> _filterCards(List<GameCard> cards) {
    return cards.where((card) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!card.name.toLowerCase().contains(query) &&
            !card.description.toLowerCase().contains(query) &&
            !card.tags!.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Rarity filter
      if (_selectedRarity != null && card.rarity != _selectedRarity) {
        return false;
      }

      // Element filter
      if (_selectedElement != null && card.element != _selectedElement) {
        return false;
      }

      // Type filter
      if (_selectedType != null && card.type != _selectedType) {
        return false;
      }

      return true;
    }).toList();
  }

  List<GameCard> _sortCards(List<GameCard> cards) {
    switch (_selectedSort) {
      case 'Name':
        cards.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Rarity':
        cards.sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
        break;
      case 'Level':
        cards.sort((a, b) => a.level.compareTo(b.level));
        break;
      case 'Type':
        cards.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case 'Element':
        cards.sort((a, b) => a.element.name.compareTo(b.element.name));
        break;
    }
    return cards;
  }

  Widget _buildCardWidget(GameCard card) {
    return GestureDetector(
      onTap: () => _showCardDetails(card),
      child: Card(
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getRarityColor(card.rarity).withOpacity(0.1),
                _getRarityColor(card.rarity).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _getRarityColor(card.rarity).withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getElementIcon(card.element),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        card.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (card.manaCost > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${card.manaCost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.description,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (card.stats != null) ...[
                        ...card.stats!.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: const TextStyle(fontSize: 9),
                          ),
                        )),
                      ],
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lv.${card.level}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            card.type.name,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Card Footer
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: _getRarityColor(card.rarity).withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.rarity.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _getRarityColor(card.rarity),
                      ),
                    ),
                    if (card.isCollectible)
                      const Icon(Icons.collections, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.legendary:
        return Colors.orange;
      case CardRarity.mythic:
        return Colors.yellow.shade700;
    }
  }

  void _showCardDetails(GameCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_getElementIcon(card.element)),
            const SizedBox(width: 8),
            Expanded(child: Text(card.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (card.stats != null) ...[
                const Text(
                  'Stats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...card.stats!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${entry.key}: ${entry.value}'),
                )),
                const SizedBox(height: 16),
              ],
              if (card.abilities != null && card.abilities!.isNotEmpty) ...[
                const Text(
                  'Abilities:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...card.abilities!.map((ability) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $ability'),
                )),
                const SizedBox(height: 16),
              ],
              if (card.flavorText != null) ...[
                Text(
                  card.flavorText!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text('Type: ${card.type.name}'),
                  const Spacer(),
                  Text('Level: ${card.level}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Rarity: ${card.rarity.name}'),
                  const Spacer(),
                  if (card.manaCost > 0) Text('Mana: ${card.manaCost}'),
                ],
              ),
              if (card.artist != null) ...[
                const SizedBox(height: 8),
                Text('Artist: ${card.artist}'),
              ],
              if (card.set != null) ...[
                const SizedBox(height: 8),
                Text('Set: ${card.set}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Cards'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rarity Filter
            DropdownButtonFormField<CardRarity?>(
              value: _selectedRarity,
              decoration: const InputDecoration(labelText: 'Rarity'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Rarities')),
                ...CardRarity.values.map((rarity) => DropdownMenuItem(
                  value: rarity,
                  child: Text(rarity.name),
                )),
              ],
              onChanged: (value) => setState(() => _selectedRarity = value),
            ),
            const SizedBox(height: 16),
            // Element Filter
            DropdownButtonFormField<CardElement?>(
              value: _selectedElement,
              decoration: const InputDecoration(labelText: 'Element'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Elements')),
                ...CardElement.values.map((element) => DropdownMenuItem(
                  value: element,
                  child: Text('${element.name} ${_getElementIcon(element)}'),
                )),
              ],
              onChanged: (value) => setState(() => _selectedElement = value),
            ),
            const SizedBox(height: 16),
            // Type Filter
            DropdownButtonFormField<CardType?>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...CardType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                )),
              ],
              onChanged: (value) => setState(() => _selectedType = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Cards'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Name',
            'Rarity',
            'Level',
            'Type',
            'Element',
          ].map((sortOption) => RadioListTile<String>(
            title: Text(sortOption),
            value: sortOption,
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() => _selectedSort = value!);
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  String _getElementIcon(CardElement element) {
    switch (element) {
      case CardElement.none:
        return '';
      case CardElement.fire:
        return '🔥';
      case CardElement.water:
        return '💧';
      case CardElement.earth:
        return '🌍';
      case CardElement.air:
        return '💨';
      case CardElement.light:
        return '☀️';
      case CardElement.dark:
        return '🌙';
      case CardElement.lightning:
        return '⚡';
      case CardElement.ice:
        return '❄️';
      case CardElement.nature:
        return '🌿';
      case CardElement.arcane:
        return '✨';
    }
  }
}
