import 'package:flutter/material.dart';

class Item {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String buttonText;
  final String link;
  final Color? color;
  final String? additionalInfo;

  Item({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.buttonText,
    required this.link,
    this.color,
    this.additionalInfo,
  });
}

List<Item> items = [
  Item(
    title: 'Quran Reading',
    subtitle: 'Explore the Holy Scripture',
    description:
        'Access the complete Quran with translations, tafsir, and reading tools to enhance your spiritual journey.',
    icon: Icons.menu_book_rounded,
    buttonText: 'Begin Reading',
    link: '/read',
    color: Colors.indigo.shade700,
    additionalInfo: 'Multiple translations available',
  ),
  Item(
    title: 'Audio Recitation',
    subtitle: 'Listen to Beautiful Recitations',
    description:
        'Experience the Quran through the voices of renowned reciters with adjustable playback options and bookmarking.',
    icon: Icons.headset_rounded,
    buttonText: 'Start Listening',
    link: '/audio',
    color: Colors.teal.shade700,
    additionalInfo: '30+ renowned reciters',
  ),
  Item(
    title: 'Share Insights',
    subtitle: 'Spread Divine Knowledge',
    description:
        'Share verses, translations, and reflections with family and friends through multiple platforms.',
    icon: Icons.share_rounded,
    buttonText: 'Share Now',
    link: '/share',
    color: Colors.amber.shade800,
    additionalInfo: 'Easy social media integration',
  ),
  Item(
    title: 'Uthmani Quran',
    subtitle: 'Read the Quran in Uthmani Script',
    description:
        'Experience the Quran in its original script with Arabic text and transliteration.',
    icon: Icons.notifications_active_rounded,
    buttonText: 'Start Reading',
    link: '/quran_editions',
    color: Colors.deepPurple.shade700,
    additionalInfo: 'Customizable notification schedule',
  ),
];

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.center,
        children: items.map((item) => EnhancedCard(item: item)).toList(),
      ),
    );
  }
}

class EnhancedCard extends StatelessWidget {
  final Item item;

  const EnhancedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive width calculation
    final cardWidth =
        screenWidth < 600
            ? screenWidth *
                0.9 // Mobile: 90% of screen width
            : screenWidth < 900
            ? screenWidth * 0.45 -
                24 // Tablet: ~45% of screen width (2 cards per row)
            : screenWidth * 0.3 -
                24; // Desktop: ~30% of screen width (3 cards per row)

    return Container(
      width: cardWidth,
      constraints: const BoxConstraints(
        minHeight: 320,
        maxWidth: 400, // Maximum width for very large screens
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (item.color ?? Colors.indigo).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(context, item.link);
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (item.color ?? Colors.indigo).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        size: 32,
                        color: item.color ?? Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (item.additionalInfo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (item.color ?? Colors.indigo).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: item.color ?? Colors.indigo,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.additionalInfo!,
                          style: TextStyle(
                            fontSize: 13,
                            color: item.color ?? Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, item.link);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.color ?? Colors.indigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      item.buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
