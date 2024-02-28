import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:expandable/expandable.dart';

import 'package:score_board/core.dart';
import 'package:score_board/common_ui.dart';

// 빈 규칙
// 규칙 선택을 안했다는걸 표현함
const _nullRule = Rule("");

class ScoreBoard extends StatefulWidget {
  const ScoreBoard({Key? key}) : super(key: key);

  @override
  State<ScoreBoard> createState() => _ScoreBoardState();
}

// 점수판 페이지

class _ScoreBoardState extends State<ScoreBoard> {
  // 각 점수판의 데이터를 저장하는 리스트
  static final List<ScoreRecord> _boardDataList = [];

  // 점수판에 대응하는 팀을 저장하는 리스트
  // 각 팀은 _boardDataList의 대응하는 점수판과 같은 위치에 있어야 함
  static final List<Team> _teamList = [];

  // 현재 선택한 규칙
  // 처음 실행할 때 _nullRule로 설정해서 규칙 선택이 안된 상태가 됨
  static var _currentRule = _nullRule;

  @override
  Widget build(BuildContext context) {
    int len = _boardDataList.length;

    // 페이지를 완성시켜 출력
    // Column을 사용해서 맨 위에 규칙 제어기를 놓음
    return Column(
      children: [
        // 규칙 제어기
        ListTile(
          // 왼쪽에 규칙을 선택할 수 있는 위젯을 배치함
          title: RuleSelector(_currentRule, changeRule),

          // 오른쪽에 경기 종료 버튼을 배치함
          trailing: ElevatedButton(
              child: const Text("경기 종료",
              style: TextStyle(fontWeight: FontWeight.bold),),
              onPressed: () {
                showYesOrNoDialog(
                    context: context,
                    title: const Text("경기 종료"),
                    content: const Text("경기를 종료하시겠습니까? 저장된 경기 기록은 수정이 불가합니다."),
                    onYes: () {
                      if (_currentRule != _nullRule) {
                        final dbTeamList = Database.getTeams();
                        final int ruleIndex =
                            Database.getRules().indexOf(_currentRule);
                        final int len = _boardDataList.length;

                        for (int i = 0; i < len; i++) {
                          Database.addGameToTeam(
                              dbTeamList.indexOf(_teamList[i]),
                              ruleIndex,
                              _boardDataList[i]);
                        }
                      }
                      // 점수판에 아무것도 남지 않게 모두 삭제함
                      setState(() {
                        _boardDataList.clear();
                        _teamList.clear();
                        GlobalState.isRunning = false;
                      });
                    },
                    // 아니오 선택 시 아무것도 하지 않음
                    onNo: () {});
              }),
        ),

        // 나머지 빈 공간을 점수판으로 채움
        Expanded(
          // 점수판을 스크롤 가능하게 함
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12.0, 0.0, 20.0, 0.0),
            itemCount: len + 1,
            itemBuilder: (context, i) {
              if (i == len) {
                // 점수판 아래에 팀 추가 버튼 추가
                return TeamAddButton(_teamList, addBoard);
              } else {
                // contents에 점수판(TeamCard)를 추가
                // 점수판 데이터는 _boardDataList에서, 팀 이름은 _teamList에서 가져옴
                return TeamCard(_teamList[i].name, _boardDataList[i]);
              }
            },
          ),
        ),
      ],
    );
  }

  void changeRule(Rule rule) {
    setState(() {
      _boardDataList.clear();
      _teamList.clear();
      _currentRule = rule;
      GlobalState.isRunning = false;
    });
  }

  void addBoard(Team team) {
    setState(() {
      _teamList.add(team);
      _boardDataList.add(ScoreRecord([]));
      GlobalState.isRunning = true;
    });
  }
}

class RuleSelector extends StatelessWidget {
  final Rule rule;
  final Function(Rule) onChanged;

  const RuleSelector(this.rule, this.onChanged, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rules = Database.getRules();
    List<DropdownMenuItem<int>> menuList = [];
    var len = rules.length;
    for (int i = 0; i < len; i++) {
      menuList.add(DropdownMenuItem(
        value: i,
        child: Text(rules[i].name),
      ));
    }

    int? val;
    if (rule != _nullRule) {
      val = rules.indexOf(rule);
      if (val == -1) {
        val = null;
      }
    }
    return Row(
      children: [
        Text("경기 규칙  :   ", style: Theme.of(context).textTheme.titleMedium),
        DropdownButton<int>(
          value: val,
          items: menuList,
          onChanged: (value) {
            if (value != null) {
              onChanged(rules[value]);
            }
          },
        ),
      ],
    );
  }
}

class TeamAddButton extends StatelessWidget {
  final List<Team> excludedTeams;
  final Function(Team) onPressed;

  const TeamAddButton(this.excludedTeams, this.onPressed, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var teams = Database.getTeams();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: PopupMenuButton<int>(
        child: const ListTile(
          title: Text("팀 추가"),
        ),
        itemBuilder: (context) {
          List<PopupMenuItem<int>> ret = [];
          int len = teams.length;
          for (int i = 0; i < len; i++) {
            if (!excludedTeams.contains(teams[i])) {
              ret.add(PopupMenuItem(
                value: i,
                child: Text(teams[i].name),
              ));
            }
          }
          return ret;
        },
        onSelected: (value) {
          onPressed(teams[value]);
        },
      ),
    );
  }
}

class TeamCard extends StatefulWidget {
  final String title;
  final ScoreRecord data;

  const TeamCard(this.title, this.data, {Key? key}) : super(key: key);

  @override
  State<TeamCard> createState() => _TeamCardState();
}

// 각 팀별 점수판
class _TeamCardState extends State<TeamCard> {
  // 점수판의 데이터
  late final String _title;
  late final ScoreRecord _data;
  final _controller = ExpandableController();

  // 몰라도 됨
  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final List<num> graphData = [];

    // Expandable이 변할때 setState()를 실행하지 않아서 그래프가 보이지 않아도 데이터를 생성함
    for (var i in _data.getRecords()) {
      graphData.add(i.value);
    }
    final predictedValue = ScoreRecordAnalyzer.predictNext(_data);
    if (!predictedValue.isNaN) {
      graphData.add(predictedValue);
      graphData.add(ScoreRecordAnalyzer.calcAverage(_data));
    }

    // 각 점수판을 둘러싸는 사각형 배경
    return GestureDetector(
      onTap: () {
        _controller.toggle();
      },
      child: BackgroundCard(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ExpandableNotifier(
          controller: _controller,
          child: Column(
            // 위젯을 왼쪽으로 정렬함
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // 팀 이름을 제목으로 설정
              Text(_title, style: Theme.of(context).textTheme.titleLarge),

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
                            id: _title,
                            data: graphData,
                            domainFn: (_, i) {
                              int len = graphData.length;
                              if (i == len - 2 && len >= 2) {
                                return "예측";
                              } else if (i == len - 1 && len >= 2) {
                                return "평균";
                              } else {
                                return (i! + 1).toString();
                              }
                            },
                            measureFn: (num i, _) => i,
                            colorFn: (_, i) {
                              int len = graphData.length;
                              // 예측
                              if (i == len - 2 && len >= 2) {
                                var color =
                                    Theme.of(context).colorScheme.tertiary;
                                return charts.Color(
                                    r: color.red,
                                    g: color.green,
                                    b: color.blue);
                              }
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
                    TotalCard(_data.sum()),

                    // 스크롤 가능한 각 경기당 점수 리스트
                    // 배경 카드의 남은 오른쪽 전부를 차지함
                    Expanded(
                      // 경기당 점수 카드들을 스크롤 가능하게 함
                      child: ListView.builder(
                        // 가로로 스크롤
                        scrollDirection: Axis.horizontal,

                        // 각 경기당 점수 카드와 점수 추가 버튼을 생성
                        // 반복을 데이터 길이보다 +1번 하여 마지막에 점수 추가 버튼을 넣음
                        itemCount: _data.len() + 1,
                        itemBuilder: (context, i) {
                          // 데이터 길이 - 1 -> 값 변경 가능한 점수 카드
                          if (i == _data.len() - 1) {
                            return ScoreEditCard(_data.index(i), () {
                              setState(() {});
                            });

                            // 마지막 -> 점수 추가 버튼
                          } else if (i == _data.len()) {
                            return IconButton(
                              // 버튼에 여백을 줌
                              padding: const EdgeInsets.all(16.0),

                              // 버튼이 눌릴 경우 새 점수를 추가하고 다시 화면을 그림
                              // 화면이 다시 그려지면 새로운 점수 카드가 추가됨
                              onPressed: () {
                                setState(() {
                                  _data.addScore(0);
                                });
                              },

                              // 아이콘 설정
                              icon: const Icon(Icons.add),

                              // 퍼짐 효과 크기
                              splashRadius: 24,
                            );
                          }

                          // 0 ~ 데이터 길이 - 2 -> 일반 점수 카드
                          return ScoreCard(_data.index(i).value);
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

// 수정 가능한 점수 카드
class ScoreEditCard extends StatelessWidget {
  // 점수를 Score 클래스 그대로 가져옴
  // Reference로 가져오기 때문에 값 변경시 원본 리스트에 반영됨
  // 메모리 할당 상태를 알아야 이해할 수 있음
  final Score score;

  // 버튼이 눌릴 경우 실행할 코드
  final Function onPressed;

  const ScoreEditCard(this.score, this.onPressed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 외곽선 있는 채도 낮은 카드
    return OutlinedCard(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        // 숫자와 버튼을 가로로 나열
        child: Row(
          children: [
            // 숫자의 가로폭을 고정시켜 숫자의 자릿수가 늘어도 차지하는 너비는 변하지 않음
            SizedBox(
              width: 50,
              // 고정된 공간 속 가운데에 숫자 배치
              child: Center(
                child: Text(
                  score.value.toString(),
                  // 글씨를 크게 함
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            // 숫자와 버튼 사이 빈 공간
            const SizedBox(width: 8),

            // 버튼의 가로폭을 고정시킴
            SizedBox(
              width: 24,
              // 버튼을 세로로 나열
              child: Column(
                children: [
                  // + 버튼
                  IconButton(
                    // 차지하는 여백을 최대한 줄임
                    padding: EdgeInsets.zero,

                    // 눌릴 경우 값을 1 증가시키고 정해진 코드를 실행
                    onPressed: () {
                      score.value++;
                      onPressed();
                    },

                    // + 아이콘
                    icon: const Icon(
                      Icons.add,
                    ),

                    // 버튼의 퍼짐 효과 크기
                    splashRadius: 12,
                  ),

                  // - 버튼
                  IconButton(
                      padding: EdgeInsets.zero,

                      // 눌릴 경우 값을 1 감소시키고 정해진 코드를 실행
                      onPressed: () {
                        score.value--;
                        onPressed();
                      },

                      // - 아이콘
                      icon: const Icon(Icons.remove),
                      splashRadius: 12),
                ],
              ),
            ),
          ],
        ));
  }
}
