import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  // Function to launch URLs
  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open game. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening game. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> games = [
      {
        'name': 'Memory Match',
        'icon': Icons.extension,
        'description': 'Exercise your memory',
        'color': Colors.blue,
        'url': 'https://www.memozor.com/memory-games/for-seniors',
      },
      {
        'name': 'Word Puzzle',
        'icon': Icons.text_fields,
        'description': 'Fun word games',
        'color': Colors.green,
        'url': 'https://wordgames.com/',
      },
      {
        'name': 'Number Quiz',
        'icon': Icons.calculate,
        'description': 'Math brain teasers',
        'color': Colors.orange,
        'url': 'https://www.mathplayground.com/math_games.html',
      },
      {
        'name': 'Sudoku',
        'icon': Icons.grid_4x4,
        'description': 'Classic puzzle game',
        'color': Colors.purple,
        'url': 'https://sudoku.com/',
      },
      {
        'name': 'Trivia',
        'icon': Icons.quiz,
        'description': 'General knowledge',
        'color': Colors.red,
        'url': 'https://www.sporcle.com/',
      },
      {
        'name': 'Crossword',
        'icon': Icons.border_clear,
        'description': 'Word cross puzzle',
        'color': Colors.teal,
        'url': 'https://www.washingtonpost.com/crossword-puzzles/daily/',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B5BA6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Games',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Game',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return GestureDetector(
                      onTap: () {
                        _launchURL(game['url'], context);
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: game['color'].withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  game['icon'],
                                  size: 40,
                                  color: game['color'],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                game['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    game['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}