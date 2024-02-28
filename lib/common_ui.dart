import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'core.dart';

/*

점수판에 사용되는 카드의 기반
앱의 테마 색에 반응하여 색이 변함

*/

// 어둡고 연한 색이 칠해진 카드
class FilledCard extends StatelessWidget {
  // 카드 안에 들어갈 내용
  final Widget child;
  final EdgeInsetsGeometry margin;
  final  Color? color;

  const FilledCard(
      {Key? key, required this.child, this.margin = const EdgeInsets.all(0), this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // 카드 외부에 좌우 여백을 줌
      // margin: const EdgeInsets.symmetric(horizontal: 8),
      margin: margin,

      // 색상 결정
      color: color ?? Theme.of(context).colorScheme.surfaceVariant,

      // 그림자 제거
      elevation: 0,

      child: Container(
        // 카드와 내용 사이 여백 추가
        padding: const EdgeInsets.all(10),

        child: child,
      ),
    );
  }
}

// 밝고 외곽선이 있는 카드
class OutlinedCard extends StatelessWidget {
  // 카드 안에 들어갈 내용
  final Widget child;
  final EdgeInsetsGeometry margin;

  const OutlinedCard(
      {Key? key, required this.child, this.margin = const EdgeInsets.all(0)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // 카드 외부에 좌우 여백을 줌
      //margin: const EdgeInsets.symmetric(horizontal: 8),
      margin: margin,

      // 그림자 제거
      elevation: 0,

      // 외곽선 추가
      shape: RoundedRectangleBorder(
          // 모든 면에 외곽선을 넣음
          side: BorderSide(color: Theme.of(context).colorScheme.outline),

          // 외관선을 둥글게 함
          borderRadius: const BorderRadius.all(Radius.circular(12))),

      child: Container(
        // 카드와 내용 사이 여백 추가
        padding: const EdgeInsets.all(10),

        child: child,
      ),
    );
  }
}

class BackgroundCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final  Color? color;

  const BackgroundCard(
      {Key? key, required this.child, this.margin = const EdgeInsets.all(0), this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        // 그림자를 없앰
        shadowColor: Colors.transparent,
        margin: margin,
        color: color,

        // 카드의 내용과 테두리 사이에 약간의 거리를 줌
        child: Container(
          padding: const EdgeInsets.all(10),
          child: child,
        ));
  }
}

// 팝업창을 만들어 반환하는 함수
Future<dynamic> Dialogs(BuildContext context, List<Widget> actions) {
  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: actions,
        );
      });
}

void showYesOrNoDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  required Function onYes,
  required Function onNo,
}) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // 창 제목
          title: title,

          // 제목 아래 설명
          content: content,

          // 버튼
          actions: [
            // 예 버튼
            TextButton(
                onPressed: () {
                  // 어떤 버튼이든 눌렀으면 팝업을 닫음
                  Navigator.of(context).pop();

                  onYes();
                },
                child: const Text("예")),

            // 아니오 버튼
            TextButton(
                onPressed: () {
                  // 어떤 버튼이든 눌렀으면 팝업을 닫음
                  Navigator.of(context).pop();

                  onNo();
                },
                child: const Text("아니오")),
          ],
        );
      });
}

const unableToDeleteAlert = SnackBar(content: Text("경기 진행중에는 삭제할 수 없습니다."));

class RecordCard extends StatelessWidget {
  final String title;
  final ScoreRecord record;
  final String id;
  final _controller = ExpandableController();

  RecordCard({required this.title, required this.record, required this.id});

  @override
  Widget build(BuildContext context) {
    final List<num> graphData = [];

    // Expandable이 변할때 setState()를 실행하지 않아서 그래프가 보이지 않아도 데이터를 생성함
    for (var i in record.getRecords()) {
      graphData.add(i.value);
    }
    graphData.add(ScoreRecordAnalyzer.calcAverage(record));

    // 각 점수판을 둘러싸는 사각형 배경
    return GestureDetector(
      onTap: () {
        _controller.toggle();
      },
      child: BackgroundCard(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ExpandableNotifier(
          controller: _controller,
          child: Column(
            // 위젯을 왼쪽으로 정렬함
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),

              // 펼쳤을 때 그래프가 나오는 위젯
              Expandable(
                // 펼치지 않으면 아무것도 나오지 않음
                collapsed: const SizedBox(
                  // 보이지 않게 하기 위해 높이를 0으로 설정
                  height: 0,
                  // 그래프와 너비를 맞추기 위해서 너비를 최대로 설정
                  width: double.infinity,
                ),

                // 펼쳤을때 그래프가 나옴
                // IgnorePointer로 감싸서 터치시 그래프가 반응하지 않게 막음
                expanded: IgnorePointer(
                  ignoring: true,
                  // 그래프의 높이를 고정시킴
                  child: SizedBox(
                    height: 256,
                    child: charts.BarChart(
                      [
                        charts.Series<num, String>(
                            id: id,
                            data: graphData,
                            domainFn: (_, i) {
                              int len = graphData.length;
                              if (i == len - 1 && len >= 2) {
                                return "평균";
                              } else {
                                return (i! + 1).toString();
                              }
                            },
                            measureFn: (num i, _) => i,
                            colorFn: (_, i) {
                              int len = graphData.length;
                              // 평균
                              if (i == len - 1 && len >= 2) {
                                var color =
                                    Theme.of(context).colorScheme.secondary;
                                return charts.Color(
                                    r: color.red,
                                    g: color.green,
                                    b: color.blue);
                              } else {
                                var color =
                                    Theme.of(context).colorScheme.primary;
                                return charts.Color(
                                    r: color.red,
                                    g: color.green,
                                    b: color.blue);
                              }
                            })
                      ],
                      defaultRenderer: charts.BarRendererConfig(
                        maxBarWidthPx: 64,
                      ),
                    ),
                  ),
                ),
              ),

              // 제목과 점수 사이 여백
              const SizedBox(height: 8),

              // 점수 칸의 높이를 고정시킴
              // 경기당 점수 카드 리스트를 스크롤하려면 높이를 고정시켜야 함
              // 지울 경우 오류남
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    // 총 점수는 스크롤 상태에 관계없이 맨 왼쪽에 고정되어있음
                    TotalCard(record.sum()),

                    // 스크롤 가능한 각 경기당 점수 리스트
                    // 배경 카드의 남은 오른쪽 전부를 차지함
                    Expanded(
                      // 경기당 점수 카드들을 스크롤 가능하게 함
                      child: ListView.builder(
                        // 가로로 스크롤
                        scrollDirection: Axis.horizontal,

                        itemCount: record.len(),
                        itemBuilder: (context, i) {
                          return ScoreCard(record.index(i).value);
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 총 점수 카드
class TotalCard extends StatelessWidget {
  // 점수 저장 변수
  final int score;

  const TotalCard(
    this.score, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 가로폭을 고정시켜 점수 자릿수와 상관없이 일정한 너비를 가짐
    return SizedBox(
      width: 100,
      child: Card(
        // 카드 오른쪽에 여백을 줌
        // 점수 카드와 총 점수 카드 사이에 공간이 생김
        margin: const EdgeInsets.only(right: 8),

        // 주 색상으로 카드를 칠함
        // 앱의 테마 색에 반응하여 색이 변함
        color: Theme.of(context).colorScheme.primaryContainer,

        // 그림자 제거
        elevation: 0,

        child: Column(
          // 요소들을 세로축의 중앙으로 정렬
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "총점:",
              // 글씨를 작게 함
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              score.toString(),
              // 글씨를 크게 함
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// 일반 점수 카드
class ScoreCard extends StatelessWidget {
  // 점수 저장 변수
  final int score;

  const ScoreCard(
    this.score, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 어둡고 연한 색이 칠해진 카드
    return FilledCard(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        // 가로폭 고정
        child: SizedBox(
          width: 50,

          // 가운데에 숫자 배치
          child: Center(
            child: Text(
              score.toString(),
              // 글씨를 크게 함
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ));
  }
}
