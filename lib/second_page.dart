import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class SecondPage extends StatefulWidget {
  final String mode;
  final int? monthIndex;

  const SecondPage({
    super.key,
    required this.mode,
    this.monthIndex,
  });

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final CardSwiperController _controller = CardSwiperController();

  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  String _title = "Fotos";

  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  static const List<String> monthNames = [
    "Januar", "Februar", "März", "April", "Mai", "Juni",
    "Juli", "August", "September", "Oktober", "November", "Dezember"
  ];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);

    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!(ps.isAuth || ps.hasAccess)) {
      await PhotoManager.openSetting();
      setState(() => _isLoading = false);
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: true,
    );

    if (paths.isEmpty) {
      setState(() {
        _assets = [];
        _isLoading = false;
      });
      return;
    }

    final album = paths.first;

    List<AssetEntity> loadedAssets = [];

    // 🔥 TODAY
    if (widget.mode == 'today') {
      _title = "Today";

      final allAssets = await album.getAssetListPaged(page: 0, size: 300);
      final now = DateTime.now();

      loadedAssets = allAssets.where((asset) {
        final d = asset.createDateTime;
        return d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;
      }).toList();
    }

    // 🔥 RANDOM
    else if (widget.mode == 'random') {
      _title = "Random";

      loadedAssets = await album.getAssetListPaged(page: 0, size: 200);
      loadedAssets.shuffle();
    }

    // 🔥 MONTH + YEAR FILTER
    else if (widget.mode == 'month' && widget.monthIndex != null) {
      final int index = widget.monthIndex!;
      _title = monthNames[index - 1];

      List<AssetEntity> allAssets = [];

int page = 0;
const int pageSize = 200;

while (true) {
  final List<AssetEntity> pageAssets =
      await album.getAssetListPaged(page: page, size: pageSize);

  if (pageAssets.isEmpty) break;

  allAssets.addAll(pageAssets);

  // 🔥 STOP sobald wir weit genug in die Vergangenheit sind
  if (pageAssets.last.createDateTime.year < _selectedYear) {
    break;
  }

  page++;
}

      // verfügbare Jahre bestimmen
      _availableYears = allAssets
          .map((e) => e.createDateTime.year)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      if (_availableYears.isNotEmpty &&
          !_availableYears.contains(_selectedYear)) {
        _selectedYear = _availableYears.first;
      }

      loadedAssets = allAssets.where((asset) {
        final date = asset.createDateTime;
        return date.month == index && date.year == _selectedYear;
      }).toList();
    }

    debugPrint("ASSETS: ${loadedAssets.length}");

    setState(() {
      _assets = loadedAssets;
      _isLoading = false;
    });
  }

  Widget _buildPhotoCard(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(800, 1200)),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(snapshot.data!, fit: BoxFit.cover),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.left) {
      debugPrint("🗑️ Bild gelöscht");
    } else if (direction == CardSwiperDirection.right) {
      debugPrint("❤️ Bild behalten");
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_title),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_assets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: Text("Keine Bilder gefunden")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 YEAR DROPDOWN
              if (widget.mode == 'month')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: _selectedYear,
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items: _availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedYear = value;
                            });
                            _loadPhotos();
                          }
                        },
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: _assets.length,
                    cardBuilder: (context, index, _, __) =>
                        _buildPhotoCard(_assets[index]),
                    onSwipe: _onSwipe,
                    allowedSwipeDirection: AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    isLoop: false,
                    numberOfCardsDisplayed: 2,
                    padding: EdgeInsets.zero,
                    backCardOffset: const Offset(0, 40),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      Icons.delete_rounded,
                      Colors.red,
                      () => _controller.swipe(CardSwiperDirection.left),
                    ),
                    const SizedBox(width: 60),
                    _buildActionButton(
                      Icons.favorite_rounded,
                      Colors.green,
                      () => _controller.swipe(CardSwiperDirection.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}