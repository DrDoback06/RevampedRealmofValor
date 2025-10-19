import 'package:flutter/material.dart';
import '../../../data/models/card_model.dart';

/// Draggable hand of cards at bottom of battle screen
class BattleHand extends StatelessWidget {
  final List<GameCard> cards;
  final Function(GameCard, Offset) onCardDragStart;
  final Function(GameCard) onCardDragEnd;
  final Function(GameCard) onCardTap;

  const BattleHand({
    super.key,
    required this.cards,
    required this.onCardDragStart,
    required this.onCardDragEnd,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No cards in hand',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.0),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          // Fan out cards with slight rotation
          final angle = (index - cards.length / 2) * 0.05;
          final offset = (index - cards.length / 2).abs() * 2.0;

          return Transform.rotate(
            angle: angle,
            child: Transform.translate(
              offset: Offset(0, offset),
              child: _DraggableCard(
                card: card,
                onDragStart: () => onCardDragStart(card, Offset(index * 100.0, 0)),
                onDragEnd: () => onCardDragEnd(card),
                onTap: () => onCardTap(card),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DraggableCard extends StatefulWidget {
  final GameCard card;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;

  const _DraggableCard({
    required this.card,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onTap,
  });

  @override
  State<_DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<_DraggableCard> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Draggable<GameCard>(
      data: widget.card,
      onDragStarted: () {
        setState(() => _isDragging = true);
        widget.onDragStart();
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
        widget.onDragEnd();
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: _CardWidget(card: widget.card, opacity: 0.8),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _CardWidget(card: widget.card),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _CardWidget(card: widget.card),
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final GameCard card;
  final double opacity;

  const _CardWidget({
    required this.card,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getBorderColor().withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Card header with mana cost
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.element.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (card.manaCost > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${card.manaCost}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Card name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Card icon/image placeholder
            Expanded(
              child: Center(
                child: Text(
                  card.elementIcon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            
            // Card stats
            if (card.stats != null)
              Container(
                padding: const EdgeInsets.all(4),
                child: Wrap(
                  spacing: 4,
                  children: card.stats!.entries.take(3).map((entry) {
                    return Chip(
                      label: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (card.rarity) {
      case CardRarity.common:
        return [Colors.grey[700]!, Colors.grey[900]!];
      case CardRarity.uncommon:
        return [Colors.green[700]!, Colors.green[900]!];
      case CardRarity.rare:
        return [Colors.blue[700]!, Colors.blue[900]!];
      case CardRarity.epic:
        return [Colors.purple[700]!, Colors.purple[900]!];
      case CardRarity.legendary:
        return [Colors.orange[700]!, Colors.orange[900]!];
      case CardRarity.mythic:
        return [Colors.amber[700]!, Colors.amber[900]!];
    }
  }

  Color _getBorderColor() {
    switch (card.rarity) {
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
        return Colors.amber;
    }
  }
}
