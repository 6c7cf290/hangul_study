import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VowelSelectionScreen(),
    ));
  });
}

// ==========================================
// [Model] 데이터 모델
// ==========================================

class AppSettings {
  double strokeWidth;
  Color strokeColor;
  bool showGuideText;

  AppSettings({
    this.strokeWidth = 15.0, // [수정] 기본값 10.0 -> 15.0 변경
    this.strokeColor = Colors.black,
    this.showGuideText = true,
  });
}

// ==========================================
// [Utils] 유틸리티 클래스
// ==========================================

class HangulGenerator {
  static List<String> generateList(String vowel) {
    // 초성 인덱스 (ㄱ ~ ㅎ)
    final List<int> choIndices = [0, 2, 3, 5, 6, 7, 9, 11, 12, 14, 15, 16, 17, 18];
    // 모음별 중성 인덱스 매핑
    final Map<String, int> jungMap = {
      'ㅏ': 0, 'ㅑ': 2, 'ㅓ': 4, 'ㅕ': 6, 'ㅗ': 8,
      'ㅛ': 12, 'ㅜ': 13, 'ㅠ': 17, 'ㅡ': 18, 'ㅣ': 20
    };

    int jungIndex = jungMap[vowel] ?? 0;
    List<String> result = [];

    for (int cho in choIndices) {
      // 한글 유니코드 공식: 0xAC00 + (초성 * 588) + (중성 * 28) + 종성(0)
      int charCode = 0xAC00 + (cho * 588) + (jungIndex * 28);
      result.add(String.fromCharCode(charCode));
    }
    return result;
  }
}

// ==========================================
// [Widgets] 재사용 가능한 위젯들
// ==========================================

/// 한글을 보여주거나 따라 쓸 수 있는 박스 위젯
class HangulBox extends StatelessWidget {
  final String char;
  final double size;
  final bool isTraceable; // 따라쓰기 모드 여부
  final AppSettings? appSettings;
  final List<Offset?>? points;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;

  const HangulBox({
    super.key,
    required this.char,
    required this.size,
    this.isTraceable = false,
    this.appSettings,
    this.points,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    // 텍스트 색상 결정: 따라쓰기 모드면 설정값(회색 or 투명), 아니면 검정
    Color textColor;
    if (isTraceable) {
      textColor = (appSettings?.showGuideText ?? true)
          ? Colors.grey.shade300
          : Colors.transparent;
    } else {
      textColor = Colors.black;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 글자 표시 (배경)
            FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  char,
                  style: TextStyle(
                    fontSize: 1000, // FittedBox가 조절하므로 큰 값 설정
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'NotoSansKR',
                  ),
                ),
              ),
            ),
            // 2. 그리기 영역 (따라쓰기 모드일 때만)
            if (isTraceable && appSettings != null && points != null)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: onPanStart,
                  onPanUpdate: onPanUpdate,
                  onPanEnd: onPanEnd,
                  child: RepaintBoundary( // 성능 최적화: 그리기 영역만 다시 그림
                    child: CustomPaint(
                      painter: TracingPainter(points!, appSettings!),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 설정 팝업 다이얼로그
class SettingsDialog extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onSettingsChanged;

  const SettingsDialog({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("설정"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 펜 두께
            const Text("1. 펜 두께", style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: widget.settings.strokeWidth,
              min: 5.0,
              max: 25.0,
              divisions: 4,
              label: widget.settings.strokeWidth.round().toString(),
              onChanged: (value) {
                setState(() => widget.settings.strokeWidth = value);
                widget.onSettingsChanged();
              },
            ),
            const SizedBox(height: 10),

            // 2. 펜 색깔
            const Text("2. 펜 색깔", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(Colors.black),
                _buildColorOption(Colors.red),
                _buildColorOption(Colors.blue),
                _buildColorOption(Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // 3. 가이드 글자 토글
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("3. 따라쓰기 글자 보이기",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: widget.settings.showGuideText,
                  onChanged: (value) {
                    setState(() => widget.settings.showGuideText = value);
                    widget.onSettingsChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("확인"),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    bool isSelected = widget.settings.strokeColor == color;
    return GestureDetector(
      onTap: () {
        setState(() => widget.settings.strokeColor = color);
        widget.onSettingsChanged();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.grey, width: 3) : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                spreadRadius: 1,
              )
          ],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}

/// 우측 컨트롤 패널 (이전/다음 버튼 등)
class ControlPanel extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const ControlPanel({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: const [
            ViewTitle(text: "순서대로"),
            ViewTitle(text: "따라 그려보세요"),
          ],
        ),
        FloatingActionButton(
          heroTag: 'prev',
          onPressed: onPrev,
          backgroundColor: onPrev != null ? Colors.blue : Colors.grey[200],
          elevation: 0,
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        Text(
          "${currentIndex + 1} / $totalCount",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        FloatingActionButton(
          heroTag: 'next',
          onPressed: onNext,
          backgroundColor: onNext != null ? Colors.blue : Colors.grey[200],
          elevation: 0,
          child: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ],
    );
  }
}

class ViewTitle extends StatelessWidget {
  final String text;
  const ViewTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}

// ==========================================
// [Screens] 화면
// ==========================================

class VowelSelectionScreen extends StatefulWidget {
  const VowelSelectionScreen({super.key});

  @override
  State<VowelSelectionScreen> createState() => _VowelSelectionScreenState();
}

class _VowelSelectionScreenState extends State<VowelSelectionScreen> {
  final AppSettings _appSettings = AppSettings();
  final List<String> vowels = const [
    'ㅏ', 'ㅑ', 'ㅓ', 'ㅕ', 'ㅗ',
    'ㅛ', 'ㅜ', 'ㅠ', 'ㅡ', 'ㅣ'
  ];

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        settings: _appSettings,
        onSettingsChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('모음 선택',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 그리드 레이아웃 계산 최적화
              const int crossAxisCount = 5;
              const int rows = 2;
              const double spacing = 10.0;
              const double horizontalPadding = 60.0;
              const double verticalPadding = 20.0;

              final double totalHSpacing = spacing * (crossAxisCount - 1);
              final double availableWidth = constraints.maxWidth - totalHSpacing - (horizontalPadding * 2);
              final double itemWidth = availableWidth / crossAxisCount;

              final double totalVSpacing = spacing * (rows - 1);
              final double availableHeight = constraints.maxHeight - totalVSpacing - (verticalPadding * 2);
              final double itemHeight = availableHeight > 0 ? availableHeight / rows : 50;

              final double aspectRatio = itemHeight > 0 ? itemWidth / itemHeight : 1.0;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: vowels.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HangulTracingScreen(
                            selectedVowel: vowels[index],
                            appSettings: _appSettings,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade100, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        heightFactor: 0.7,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            vowels[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class HangulTracingScreen extends StatefulWidget {
  final String selectedVowel;
  final AppSettings appSettings;

  const HangulTracingScreen({
    super.key,
    required this.selectedVowel,
    required this.appSettings,
  });

  @override
  State<HangulTracingScreen> createState() => _HangulTracingScreenState();
}

class _HangulTracingScreenState extends State<HangulTracingScreen> {
  late List<String> characters;
  int currentIndex = 0;
  List<Offset?> points = [];

  @override
  void initState() {
    super.initState();
    characters = HangulGenerator.generateList(widget.selectedVowel);
  }

  void _clearBoard() {
    setState(() => points.clear());
  }

  void _nextChar() {
    if (currentIndex < characters.length - 1) {
      setState(() {
        currentIndex++;
        points.clear();
      });
    }
  }

  void _prevChar() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        points.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            '${widget.selectedVowel} 모음 연습',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _clearBoard,
            tooltip: '다시 쓰기',
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // [왼쪽 영역] 본보기 글자 + 따라쓰기 박스
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double gap = 20.0;
                      final double availableWidthPerBox = (constraints.maxWidth - gap) / 2;
                      // 박스 크기 결정 (정사각형 유지)
                      final double size = availableWidthPerBox < constraints.maxHeight
                          ? availableWidthPerBox
                          : constraints.maxHeight;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. 본보기 글자 (검은색, 그리기 불가)
                          HangulBox(
                            char: characters[currentIndex],
                            size: size,
                            isTraceable: false,
                          ),

                          SizedBox(width: gap),

                          // 2. 따라쓰기 글자 (설정색, 그리기 가능)
                          HangulBox(
                            char: characters[currentIndex],
                            size: size,
                            isTraceable: true,
                            appSettings: widget.appSettings,
                            points: points,
                            onPanStart: (d) => setState(() => points.add(d.localPosition)),
                            onPanUpdate: (d) => setState(() => points.add(d.localPosition)),
                            onPanEnd: (d) => setState(() => points.add(null)),
                          ),
                        ],
                      );
                    }
                ),
              ),
            ),

            // [오른쪽 영역] 컨트롤 패널
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: ControlPanel(
                  currentIndex: currentIndex,
                  totalCount: characters.length,
                  onPrev: currentIndex > 0 ? _prevChar : null,
                  onNext: currentIndex < characters.length - 1 ? _nextChar : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// [Painters] 커스텀 페인터
// ==========================================

class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final AppSettings appSettings;

  TracingPainter(this.points, this.appSettings);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint 객체 생성 최적화
    final Paint paint = Paint()
      ..color = appSettings.strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = appSettings.strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TracingPainter oldDelegate) => true; // 실시간 드로잉이므로 true
}