import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// DB 라이브러리
import 'package:hive_flutter/hive_flutter.dart';
import 'package:score_board/page/config.dart';

import 'core.dart';
import 'data.dart';

import 'page/scoreboard.dart';
import 'page/team_list.dart';
import 'page/rule_list.dart';

void main() async {
  // DB 초기화
  await Hive.initFlutter();

  Hive.registerAdapter(RuleAdapter());
  Hive.registerAdapter(ScoreAdapter());
  Hive.registerAdapter(ScoreRecordAdapter());
  Hive.registerAdapter(RecordsAdapter());
  Hive.registerAdapter(TeamAdapter());
  Hive.registerAdapter(DataManagerAdapter());
  Hive.registerAdapter(SettingsAdapter());

  await Hive.openBox(AppData.dbBoxKey);

  Database.init();

  // 앱 실행
  runApp(const ScalingManager(child: MainApp()));
}

// 기본 앱 구조
class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 마우스 클릭으로 터치스크린 스크롤 테스트 가능하게 설정
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.unknown
      }),
      // 테마 설정
      theme: ThemeData(
        useMaterial3: true, // 부드러운 느낌의 디자인 사용
        colorSchemeSeed: Colors.blue, // 테마의 색을 설정
      ),

      routes: {
        RuleInfoPage.routeName: (context) => const RuleInfoPage(),
        TeamInfoPage.routeName: (context) => const TeamInfoPage(),
      },

      // State가 바뀔 때마다 테마를 바꿀 필요는 없으므로 앱 화면 구성을 StatefulWidget으로 분리함
      home: const MainContainer(),
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({Key? key}) : super(key: key);

  @override
  State<MainContainer> createState() => _MainContainerState();
}

// 앱의 화면 구성
class _MainContainerState extends State<MainContainer> {
  // 현재 선택한 NavigationRail의 버튼과 페이지 인덱스
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // 상단 바
        appBar: AppBar(
          // 스크롤 시 색이 변하지 않도록 함
          scrolledUnderElevation: 0,
          leading: new Icon(Icons.smart_toy),
          title: const Text(AppData.appName),
          actions: [
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ConfigPage()));
                })
          ],
        ),

        // 상단 바 아래 화면 구성
        // Row는 NavigationRail을 화면의 왼쪽으로 배치하기 위해서 사용
        body: Row(
          children: [
            // 페이지를 고를 수 있는 세로로 된 버튼 모음
            // 여러 버튼중 하나를 고르면 선택된 버튼에 대응하는 페이지가 보여짐
            NavigationRail(
              // 선택된 버튼을 인덱스가 _selectedIndex인 버튼으로 설정
              // 인덱스가 _selectedIndex인 버튼은 배경색이 생기면서 강조됨
              selectedIndex: _selectedIndex,

              // 버튼을 누르면 _selectedIndex를 누른 버튼의 인덱스로 설정함
              // setState로 화면이 갱신되면 윗줄의 코드로 인해 선택된 버튼이 방금 누른 버튼으로 변경됨
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },

              // 이름을 아예 안 나타나게 하거나, 선택 여부와 상관없이 항상 나타나게 할 수 있음
              labelType: NavigationRailLabelType.all,

              // 페이지 선택 버튼 리스트
              // NavigationRailDestination 하나가 버튼 하나를 생성함
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.scoreboard), label: Text("점수판")),
                NavigationRailDestination(
                    icon: Icon(Icons.rule), label: Text("경기 규칙")),
                NavigationRailDestination(
                    icon: Icon(Icons.list), label: Text("팀 목록")),
                NavigationRailDestination(
                    icon: Icon(Icons.copyright), label: Text("저작권")),
              ],
            ),

            // NavigationRail을 제외한 화면의 나머지 오른쪽 영역
            // Expanded가 남은 화면 전체를 차지하는 역할을 함
            // child를 MainContent로 하여 현재 선택된 버튼에 대응하는 페이지를 보여줌
            Expanded(
                child: MainContent(
                  page: _selectedIndex,
                ))
          ],
        ));
  }
}

// 선택된 버튼에 해당되는 페이지를 보여주는 위젯
class MainContent extends StatelessWidget {
  // 선택된 버튼 인덱스 == 대응하는 페이지 번호
  final int page;

  const MainContent({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // switch를 통하여 페이지 번호에 따라 대응하는 페이지를 전달
    switch (page) {
      // 점수판 페이지
      case 0:
        {
          return const ScoreBoard();
        }
      // 경기 규칙 페이지
      case 1:
        {
          return const RuleList();
        }
      case 2:
        {
          return const TeamList();
        }
      // 저작권 페이지
      case 3:
        {
          // 페이지에 나타나는 저작권 문구
          String copyrightString =
              copyrightStringBuilder("Flutter", Licences.flutterBsd3Clause);
          copyrightString += "\n\n";
          copyrightString += copyrightStringBuilder(
              "Hive / Hive Flutter", Licences.apache2,
              author: "Simon Leier", year: 2019);
          copyrightString += "\n\n";
          copyrightString += copyrightStringBuilder(
              "charts_flutter", Licences.apache2,
              author: "Google Inc.", year: 2021);
          copyrightString += "\n\n";
          copyrightString +=
              copyrightStringBuilder("expandable", Licences.expandableMit);

          // 저작권 문구를 스크롤 가능하게 함
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0.0, 20.0, 0.0),
              child: Text(copyrightString),
            ),
          );
        }
      // 페이지 번호가 잘못된 경우 빈 페이지를 보여줌
      default:
        {
          return const SizedBox.shrink();
        }
    }
  }

  // 저작권 안내 문구 제작 함수
  // 받은 매개변수를 바탕으로 저작권 안내 String을 만들어 반환함
  String copyrightStringBuilder(String name, String license,
      {String author = "", int year = -1}) {
    // 사용된 프로그램 이름 추가
    String ret = "⦁ $name\n\n";

    // author나 year 둘 중 하나라도 입력받지 못한 경우 Copyright ~ 문구를 삽입하지 않음
    if (!(author == "" || year == -1)) {
      ret += "Copyright $year $author\n\n";
    }

    // 라이선스 문구 추가
    ret += license;

    return ret;
  }
}