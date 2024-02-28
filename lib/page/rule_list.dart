import 'package:flutter/material.dart';

import 'package:score_board/core.dart';
import 'package:score_board/common_ui.dart';

// 규칙 목록을 보여주는 클래스
class RuleList extends StatefulWidget {
  const RuleList({Key? key}) : super(key: key);

  @override
  State<RuleList> createState() => _RuleListState();
}

class _RuleListState extends State<RuleList> {
  @override
  Widget build(BuildContext context) {
    // 규칙이름을 데이터 베이스에 저장하기 전 임시 저장하기 위해 만든 변수
    Stringdata data = Stringdata();
    // 규칙이름을 데이터 베이스에서 불러와 저장하는 리스트
    List<Rule> ruleList = Database.getRules();

    // 규칙의 개수 만큼의 BackgroundCard와 1개의 규칙 추가 버튼을 가로로 순차적으로 생성
    // len == 규칙 개수
    var len = ruleList.length;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12.0, 0.0, 20.0, 0.0),
      itemCount: len + 1,
      itemBuilder: (context, i) {
        // 만약 마지막 차례라면 규칙 추가 버튼 생성
        if (i == len) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextButton.icon(
              // 버튼을 누르면 규칙을 추가할 수 있는 팝업창 띄우기
              onPressed: () {
                // 팝업창 위젯
                Dialogs(
                  context,
                  <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      // 크기 고정을 위해 Container 안에 TextBox를 넣음
                      child: SizedBox(
                        width: 300,
                        // 팝업창 안에 규칙 이름을 입력받는 UI 생성
                        child: Column(children: [
                          TextBox("게임 이름을 입력하세요", data, 0),
                          //입력 완료 버튼 생성
                          Center(
                            child: TextButton(
                              child: const Text("입력 완료"),
                              onPressed: () {
                                // 입력값이 제대로 되지 않았으면 저장하지 않음
                                if (data.str == " ") {
                                  data.Clear();
                                  Navigator.of(context).pop();

                                  // 제대로 입력받았으면 DB에 저장
                                } else {
                                  setState(() {
                                    Database.addRule(Rule(data.str));
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
              label: const Text('규칙 추가',
              style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add),
            ),
          );
          // 마지막 차례가 아니면 규칙 이름 생성
        } else {
          return BackgroundCard(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: GestureDetector(
                onTap: () {
                Navigator.pushNamed(context, RuleInfoPage.routeName,
                    arguments: RuleInfoArgs(i));
                },
                child: ListTile(
                  title: Text(ruleList[i].name),
              
                  // 쓰레기통 버튼을 누르면 DB에서 규칙 삭제
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      if (GlobalState.isRunning) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(unableToDeleteAlert);
                      } else {
                        // 삭제 확인 팝업을 띄움
                        showYesOrNoDialog(
                            context: context,
                            title: const Text("규칙 삭제"),
                            content: const Text(
                                "규칙을 삭제하시겠습니까?\n해당 규칙으로 진행된 모든 경기 기록도 삭제됩니다."),
                            onYes: () {
                              // 규칙을 삭제함
                              setState(() {
                                Database.removeRule(i);
                              });
                            },
                            // 아니오 선택 시 아무것도 하지 않음
                            onNo: () {});
                      }
                    },
                  ),
                ),
              ));
        }
      },
    );
  }
}

class RuleInfoArgs {
  final int rule;

  const RuleInfoArgs(this.rule);
}

class RuleInfoPage extends StatelessWidget {
  static const routeName = '/ruleInfo';

  const RuleInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as RuleInfoArgs;
    final List<Pair<String, ScoreRecord>> records = [];
    for (var i in Database.getTeams()) {
      var name = i.name;
      for (var j in i.getRecordOfRule(args.rule).getRecords()) {
        records.add(Pair(name, j));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(Database.getRuleName(args.rule)),
        scrolledUnderElevation: 0.0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, i) {
                  var data = records[i];
                  return RecordCard(
                      title: data.first,
                      record: data.second,
                      id: i.toString());
                }),
          )
        ],
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
          widget.data.str = text;
        });
      },
      decoration: InputDecoration(labelText: widget.LabelText),
    );
  }
}

// 입력받은 데이터를 임시보관하기 위해 사용하는 클래스
class Stringdata {
  String str = " ";

  void Clear() {
    str = " ";
  }
}