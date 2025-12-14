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

// [추가] 앱 설정 데이터를 관리하는 클래스
class AppSettings {
  double strokeWidth;
  Color strokeColor;
  bool showGuideText;

  AppSettings({
    this.strokeWidth = 10.0,
    this.strokeColor = Colors.black,
    this.showGuideText = true,
  });
}

// 1. 모음 선택 화면 (Stateful로 변경하여 설정 상태 관리)
class VowelSelectionScreen extends StatefulWidget {
  const VowelSelectionScreen({super.key});

  @override
  State<VowelSelectionScreen> createState() => _VowelSelectionScreenState();
}

class _VowelSelectionScreenState extends State<VowelSelectionScreen> {
  // 기본 설정값 초기화
  AppSettings _appSettings = AppSettings();

  final List<String> vowels = const [
    'ㅏ', 'ㅑ', 'ㅓ', 'ㅕ', 'ㅗ',
    'ㅛ', 'ㅜ', 'ㅠ', 'ㅡ', 'ㅣ'
  ];

  // 설정 다이얼로그 표시 함수
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // 다이얼로그 내부 상태 변경을 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("설정"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 펜 두께 설정
                    const Text("1. 펜 두께", style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _appSettings.strokeWidth,
                      min: 5.0,
                      max: 25.0, // [수정] 최대 두께를 50 -> 25로 축소
                      divisions: 4, // [수정] 5, 10, 15, 20, 25 (5단계)
                      label: _appSettings.strokeWidth.round().toString(),
                      onChanged: (value) {
                        setState(() { // 메인 화면 상태 업데이트 (필요시)
                          _appSettings.strokeWidth = value;
                        });
                        setStateDialog(() {}); // 다이얼로그 내부 UI 업데이트
                      },
                    ),
                    const SizedBox(height: 10),

                    // 2. 펜 색깔 설정
                    const Text("2. 펜 색깔", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildColorOption(Colors.black, setStateDialog),
                        _buildColorOption(Colors.red, setStateDialog),
                        _buildColorOption(Colors.blue, setStateDialog),
                        _buildColorOption(Colors.green, setStateDialog),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. 가이드 글자 보임/숨김 설정
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("3. 따라쓰기 글자 보이기", style: TextStyle(fontWeight: FontWeight.bold)),
                        Switch(
                          value: _appSettings.showGuideText,
                          onChanged: (value) {
                            setState(() {
                              _appSettings.showGuideText = value;
                            });
                            setStateDialog(() {});
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
          },
        );
      },
    );
  }

  // 색상 선택 원형 버튼 빌더
  Widget _buildColorOption(Color color, StateSetter setStateDialog) {
    bool isSelected = _appSettings.strokeColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _appSettings.strokeColor = color;
        });
        setStateDialog(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('모음 선택', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // [추가] 설정 버튼
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // [삭제] "연습할 모음을 선택해주세요" 텍스트 제거로 공간 확보
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double horizontalPadding = 60.0;
                    final double verticalPadding = 20.0;
                    final double totalVerticalSpacing = 10;
                    final double availableHeight = constraints.maxHeight - totalVerticalSpacing - (verticalPadding * 2);
                    final double itemHeight = availableHeight > 0 ? availableHeight / 2 : 50;
                    final double totalHorizontalSpacing = 10 * 4;
                    final double itemWidth = (constraints.maxWidth - totalHorizontalSpacing - (horizontalPadding * 2)) / 5;
                    final double aspectRatio = itemHeight > 0 ? itemWidth / itemHeight : 1.0;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
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
                                  appSettings: _appSettings, // [변경] 설정값 전달
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
                            padding: EdgeInsets.zero,
                            child: SizedBox(
                              width: itemWidth * 0.7,
                              height: itemHeight * 0.7,
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
            ],
          ),
        ),
      ),
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

// 2. 따라 쓰기 화면
class HangulTracingScreen extends StatefulWidget {
  final String selectedVowel;
  final AppSettings appSettings; // [추가] 설정값 받기

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
    characters = generateHangulList(widget.selectedVowel);
  }

  List<String> generateHangulList(String vowel) {
    final List<int> choIndices = [0, 2, 3, 5, 6, 7, 9, 11, 12, 14, 15, 16, 17, 18];
    final Map<String, int> jungMap = {
      'ㅏ': 0, 'ㅑ': 2, 'ㅓ': 4, 'ㅕ': 6, 'ㅗ': 8,
      'ㅛ': 12, 'ㅜ': 13, 'ㅠ': 17, 'ㅡ': 18, 'ㅣ': 20
    };
    int jungIndex = jungMap[vowel] ?? 0;

    List<String> result = [];
    for (int cho in choIndices) {
      int charCode = 0xAC00 + (cho * 588) + (jungIndex * 28);
      result.add(String.fromCharCode(charCode));
    }
    return result;
  }

  void clearBoard() {
    setState(() {
      points.clear();
    });
  }

  void nextChar() {
    if (currentIndex < characters.length - 1) {
      setState(() {
        currentIndex++;
        points.clear();
      });
    }
  }

  void prevChar() {
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
            onPressed: clearBoard,
            tooltip: '다시 쓰기',
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double gap = 20.0;
                      final double availableWidthPerBox = (constraints.maxWidth - gap) / 2;
                      final double size = availableWidthPerBox < constraints.maxHeight
                          ? availableWidthPerBox
                          : constraints.maxHeight;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 왼쪽: 본보기 글자 (검은색)
                          SizedBox(
                            width: size,
                            height: size,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      characters[currentIndex],
                                      style: const TextStyle(
                                        fontSize: 1000,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'NotoSansKR',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: gap),

                          // 오른쪽: 따라 쓰기 글자
                          SizedBox(
                            width: size,
                            height: size,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  // 배경 가이드 글자 (설정에 따라 보임/숨김)
                                  Positioned.fill(
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Text(
                                            characters[currentIndex],
                                            style: TextStyle(
                                              fontSize: 1000,
                                              fontWeight: FontWeight.bold,
                                              // [변경] 설정된 showGuideText 값에 따라 투명도 조절
                                              color: widget.appSettings.showGuideText
                                                  ? Colors.grey.shade300
                                                  : Colors.transparent,
                                              fontFamily: 'NotoSansKR',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onPanStart: (details) {
                                        setState(() => points.add(details.localPosition));
                                      },
                                      onPanUpdate: (details) {
                                        setState(() => points.add(details.localPosition));
                                      },
                                      onPanEnd: (details) {
                                        setState(() => points.add(null));
                                      },
                                      child: CustomPaint(
                                        // [변경] 설정 객체 전달
                                        painter: TracingPainter(points, widget.appSettings),
                                        size: Size.infinite,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                ),
              ),
            ),

            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Column(
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
                      onPressed: currentIndex > 0 ? prevChar : null,
                      backgroundColor: currentIndex > 0 ? Colors.blue : Colors.grey[200],
                      elevation: 0,
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      "${currentIndex + 1} / ${characters.length}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    FloatingActionButton(
                      heroTag: 'next',
                      onPressed: currentIndex < characters.length - 1 ? nextChar : null,
                      backgroundColor: currentIndex < characters.length - 1 ? Colors.blue : Colors.grey[200],
                      elevation: 0,
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final AppSettings appSettings; // [추가] 설정값 필드

  TracingPainter(this.points, this.appSettings);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = appSettings.strokeColor // [변경] 설정된 색상 사용
      ..strokeCap = StrokeCap.round
      ..strokeWidth = appSettings.strokeWidth; // [변경] 설정된 두께 사용

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TracingPainter oldDelegate) => true;
}