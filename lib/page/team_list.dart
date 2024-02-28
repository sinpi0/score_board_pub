import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:score_board/core.dart';
import 'package:score_board/common_ui.dart';

class TeamList extends StatefulWidget {
  const TeamList({Key? key}) : super(key: key);

  @override
  State<TeamList> createState() => _TeamListState();
}

class _TeamListState extends State<TeamList> {
  @override
  Widget build(BuildContext context) {
    List<Team> teamList = Database.getTeams();
    var len = teamList.length;
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12.0, 0.0, 20.0, 0.0),
        itemCount: len + 1,
        itemBuilder: (context, i) {
          if (i == len) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TextButton.icon(
                onPressed: () {
                  Stringdata data = Stringdata();
                  Dialogs(
                    context,
                    <Widget>[
                      // 크기 고정을 위해 Container 안에 TextBox를 넣음
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 300,
                          child: Column(children: [
                            TextBox("팀 이름을 입력하세요", data, 0),
                            TextBox("팀원 이름을 입력하세요", data, 1),
                            TextBox("팀원 이름을 입력하세요", data, 2),
                            TextBox("팀원 이름을 입력하세요", data, 3),
                            Center(
                              child: TextButton(
                                child: const Text("입력 완료"),
                                onPressed: () {
                                  // 입력받은 데이터가 제대로 되지 않았으면 저장하지 않음
                                  if (data.str[0] == " " ||
                                      data.str[1] == " " ||
                                      data.str[2] == " ") {
                                    data.Clear();
                                    Navigator.of(context).pop();

                                    // 두 명만 입력받았을 경우 두 명만 저장
                                  } else if (data.str[3] == " ") {
                                    setState(() {
                                      List<String> members = [
                                        data.str[1],
                                        data.str[2],
                                      ];
                                      Database.addTeam(
                                          Team.empty(data.str[0], members));
                                      data.Clear();
                                    });
                                    Navigator.of(context).pop();
                                    //제대로 입력받았으면 DB에 저장
                                  } else {
                                    setState(() {
                                      List<String> members = [
                                        data.str[1],
                                        data.str[2],
                                        data.str[3]
                                      ];
                                      Database.addTeam(
                                          Team.empty(data.str[0], members));
                                      data.Clear();
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            )
                          ]),
                        ),
                      ),
                    ],
                  );
                },
                label: const Text('팀 추가',
                style: TextStyle(fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.add),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, TeamInfoPage.routeName,
                    arguments: TeamInfoArgs(teamList[i]));
              },
              child: BackgroundCard(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(teamList[i].name),

                    // delete 아이콘 버튼을 누르면 DB에서 팀 삭제
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        if (GlobalState.isRunning) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(unableToDeleteAlert);
                        } else {
                          showYesOrNoDialog(
                              context: context,
                              title: const Text("팀 삭제"),
                              content: const Text(
                                  "팀을 삭제하시겠습니까?\n해당 팀으로 진행된 모든 경기 기록도 삭제됩니다."),
                              onYes: () {
                                // 팀을 삭제함
                                setState(() {
                                  Database.removeTeam(i);
                                });
                              },
                              // 아니오 선택 시 아무것도 하지 않음
                              onNo: () {});
                        }
                      },
                    ),
                  )),
            );
          }
        });
  }
}

class TeamInfoArgs {
  final Team team;

  const TeamInfoArgs(this.team);
}

class TeamInfoPage extends StatelessWidget {
  static const routeName = '/teamInfo';

  const TeamInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as TeamInfoArgs;
    final ruleCount = Database.getRules().length;
    final recordsOfTeam = <Pair<int, ScoreRecord>>[];
    for (int i = 0; i < ruleCount; i++) {
      for (var j in args.team.getRecordOfRule(i).getRecords()) {
        recordsOfTeam.add(Pair(i, j));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${args.team.name} ${args.team.getMembers()}"),
        scrolledUnderElevation: 0.0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: recordsOfTeam.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final List<Pair<int, Pair<double, double>>> statusList = [];
                    final len = Database.getRules().length;
                    for (var j = 0; j < len; j++) {
                      var tmp = TeamAnalyzer.calcAvgOfRule(args.team, j);
                      if (!tmp.first.isNaN) {
                        statusList.add(Pair(j, tmp));
                      }
                    }
                    return TeamRecordStatusCard(recordStatus: statusList);
                  } else {
                    var data = recordsOfTeam[i - 1];
                    return RecordCard(
                        title: Database.getRuleName(data.first),
                        record: data.second,
                        id: i.toString());
                  }
                }),
          )
        ],
      ),
    );
  }
}

class TeamRecordStatusCard extends StatelessWidget {
  final List<Pair<int, Pair<double, double>>> recordStatus;

  const TeamRecordStatusCard({required this.recordStatus});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    if (recordStatus.isEmpty) {
      children.add(Text(
        "경기 횟수가 충분하지 않아 통계를 계산할 수 없습니다.",
        style: TextStyle(fontSize: 18),
      ));
    } else {
      children.add(Text(
        "최근 3경기 통계",
        style: Theme.of(context).textTheme.titleLarge,
      ));
      children.add(const SizedBox(height: 8));
      final List<Widget> wrapChildren = [];
      for (var i in recordStatus) {
        wrapChildren.add(FilledCard(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Text(
                "${Database.getRuleName(i.first)}(평균: ${i.second.first.toStringAsFixed(3)}, 표준편차: ${i.second.second.toStringAsFixed(3)})",
                style: Theme.of(context).textTheme.titleMedium)));
      }
      children.add(SizedBox(
        width: double.infinity,
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceEvenly,
          children: wrapChildren,
        ),
      ));
    }

    return BackgroundCard(
        color: Color.fromARGB(255, 242, 241, 251),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ));
  }
}

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

// 글씨 입력을 받는 위젯
// 인수로 텍스트와 받은 값을 저장할 Stringdata클래스를 받음
class TextBox extends StatefulWidget {
  final String LabelText;
  final Stringdata data;
  final int index;

  const TextBox(this.LabelText, this.data, this.index, {Key? key})
      : super(key: key);

  @override
  State<TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends State<TextBox> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: (text) {
        setState(() {
          widget.data.str[widget.index] = text;
        });
      },
      decoration: InputDecoration(labelText: widget.LabelText),
    );
  }
}

// 입력받은 데이터를 임시보관하기 위해 사용하는 클래스
class Stringdata {
  List<String> str = [" ", " ", " ", " "];

  void Clear() {
    str = [" ", " ", " ", " "];
  }
}
