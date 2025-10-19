import 'package:flutter/material.dart';
import '../../../data/models/card_model.dart';

/// Stack item representing a card effect on the stack
class StackItem {
  final String id;
  final GameCard card;
  final String target; // 'opponent', 'self', 'field'
  final List<String> effects;
  final DateTime timestamp;

  const StackItem({
    required this.id,
    required this.card,
    required this.target,
    required this.effects,
    required this.timestamp,
  });
}

/// LIFO stack visualization panel
class StackPanel extends StatelessWidget {
  final List<StackItem> stack;
  final VoidCallback? onStackResolve;
  final bool isResolving;

  const StackPanel({
    super.key,
    required this.stack,
    this.onStackResolve,
    this.isResolving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stack',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${stack.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Stack items
          Expanded(
            child: stack.isEmpty
                ? const Center(
                    child: Text(
                      'Empty',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: true, // LIFO display (bottom to top)
                    itemCount: stack.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final item = stack[index];
                      final isTop = index == stack.length - 1;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isTop 
                              ? Colors.purple.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: isTop 
                              ? Border.all(color: Colors.purple, width: 2)
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Text(
                            item.card.elementIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            item.card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target: ${item.target}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              if (item.effects.isNotEmpty)
                                Text(
                                  item.effects.join(', '),
                                  style: const TextStyle(
                                    color: Colors.purple[200],
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: isTop
                              ? const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.purple,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          
          // Resolve button
          if (stack.isNotEmpty && onStackResolve != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton.icon(
                onPressed: isResolving ? null : onStackResolve,
                icon: isResolving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(isResolving ? 'Resolving...' : 'Resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
