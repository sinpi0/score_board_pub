// DB 라이브러리 사용
// @Hive.--- 형식으로 되어있는 것들은 DB 관련 코드임
// 일반적인 클래스 사용에는 아무 영향이 없음
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

import 'package:score_board/data.dart';

part 'core.g.dart';

// 규칙 == 경기 종류
// 규칙에 따라서 팀의 경기 내역을 저장하는 공간이 나뉨
// 각 규칙은 Rule을 통해 저장하며, 모든 규칙을 DataManager에서 관리함

// 규칙 데이터를 저장하는 클래스
// 이 클래스가 각각의 규칙 하나를 나타냄
@HiveType(typeId: 1)
class Rule {
  // 규칙 이름
  @HiveField(0)
  final String name;

  const Rule(this.name);

  @override
  String toString() {
    return name;
  }
}

// 점수 Wrapper 클래스
// 값 대신 레퍼런스를 전달하기 위해서 존재함
// 메모리 할당 상태를 알아야 이해할 수 있음
@HiveType(typeId: 2)
class Score {
  @HiveField(0)
  int value;

  Score(this.value);

  @override
  String toString() {
    return value.toString();
  }
}

// 경기 기록
// 한 경기의 각 라운드당 점수를 저장함
// 일반적으로 Team에 저장되어 팀의 지난 경기 기록을 나타냄
// 점수판의 점수 기록용으로도 사용 가능
@HiveType(typeId: 3)
class ScoreRecord {
  // 라운드당 점수 모음
  // 리스트이기 때문에 n번째 라운드 점수는 _records[n-1]로 접근해야함
  @HiveField(0)
  final List<Score> _records;

  ScoreRecord(this._records);

  // 비어있는 새 경기 기록 생성
  ScoreRecord empty() {
    return ScoreRecord([]);
  }

  // i-1번째 경기의 점수 데이터를 가져옴
  // 변수가 public이 아니기 때문에 메소드로 값을 가져와야 함
  Score index(int i) {
    return _records[i];
  }

  // 새로운 라운드를 생성하고 점수를 입력
  void addScore(int i) {
    _records.add(Score(i));
  }

  // 진행한 라운드 수를 반환
  int len() {
    return _records.length;
  }

  // 점수 총합을 반환
  int sum() {
    int sum = 0;
    for (var element in _records) {
      sum += element.value;
    }
    return sum;
  }

  List<Score> getRecords() {
    return List.unmodifiable(_records);
  }

  @override
  String toString() {
    return _records.toString();
  }
}

@HiveType(typeId: 4)
class Records {
  @HiveField(0)
  final List<ScoreRecord> _records;

  Records(this._records);

  List<ScoreRecord> getRecords() {
    return List.unmodifiable(_records);
  }

  void addRecord(ScoreRecord record) {
    _records.add(record);
  }
}

// 팀 클래스
// 팀의 이름과 구성원 목록, 경기 기록이 저장됨
// 팀 정보를 분석하는 메소드를 여기에 추가할 예정
@HiveType(typeId: 5)
class Team {
  // 팀 이름
  @HiveField(0)
  final String name;

  // 구성원 목록
  @HiveField(1)
  final List<String> _members;

  // 팀의 모든 경기 기록
  // 각 규칙의 경기 기록 리스트들을 하나의 리스트로 묶음
  // 각 규칙별 경기 기록 리스트는 _games[경기 규칙 index] 형식으로 접근
  // 특정 규칙의 n번째 경기 기록은 _games[경기 규칙 index][n+1] 형식으로 접근
  // 경기 규칙 index는 DataManager를 따라야 함
  @HiveField(2)
  final List<Records> _games;

  Team(this.name, this._members, this._games);

  static Team empty(String name, List<String> members) {
    return Team(name, members, []);
  }

  // 새 규칙에 대응하는 경기 리스트를 생성
  // 일반적으론 쓰지 않고 DataManager에서 규칙 리스트 관리를 위해 사용할 것임
  void addRule() {
    _games.add(Records([]));
  }

  // 삭제된 규칙에 대응하는 경기 리스트를 제거
  // 일반적으론 쓰지 않고 DataManager에서 규칙 리스트 관리를 위해 사용할 것임
  void removeRule(int index) {
    _games.removeAt(index);
  }

  // 규칙별 경기 리스트에 새 기록을 추가함
  // rule은 DataManager의 경기 규칙 index에 해당함
  void addGame(int rule, ScoreRecord game) {
    _games[rule].addRecord(game);
  }

  // 특정 규칙의 모든 경기 기록을 반환
  // 내용을 수정하지 않도록 주의해야함
  Records getRecordOfRule(int ruleIndex) {
    return _games[ruleIndex];
  }

  // 규칙별 경기 휫수를 반환
  int getPlayCountOfRule(int rule) {
    return _games[rule].getRecords().length;
  }

  // 구성원을 반환
  List<String> getMembers() {
    return List.unmodifiable(_members);
  }

  @override
  String toString() {
    return "($name, $_members): $_games";
  }
}

// 데이터 관리 클래스
// 앱 실행 시 디스크에서 로드되어 규칙 목록과 팀 목록을 가져옴
// 규칙 추가 시 이 클래스가 모든 팀의 경기 기록에서 추가된 규칙을 위한 공간을 할당함
// 규칙 제거 시 이 클래스가 모든 팀의 경기 기록에서 제거된 규칙에 할당된 공간을 지움
@HiveType(typeId: 0)
class DataManager {
  // 규칙 리스트
  // 이 리스트의 규칙 index와 각 팀의 규칙 index가 동일해야함
  // 여기서 얻은 규칙 index를 통해 각 팀의 점수 데이터에 접근함
  @HiveField(0)
  final List<Rule> _ruleList;

  @HiveField(1)
  final List<Team> _teamList;

  DataManager(this._ruleList, this._teamList);

  // 규칙 리스트를 반환하는 함수
  // 반환값을 이용하여 리스트에 무엇이 몇 번째에 들어있는지 알 수 있음
  // 원본 리스트 값은 읽기만 가능하게 하고 수정은 불가능하게 함
  List<Rule> getRules() {
    return List.unmodifiable(_ruleList);
  }

  // 규칙의 index를 받아 해당하는 규칙의 이름을 반환하는 함수
  // 규칙 리스트가 private이기 때문에 함수를 통해서 이름을 알아내야함
  String getRuleName(int index) {
    return _ruleList[index].name;
  }

  // 규칙 추가
  // 모든 팀의 경기 기록에서 추가된 규칙을 위한 공간을 할당함
  void addRule(Rule rule) {
    _ruleList.add(rule);

    // 모든 팀 클래스에 새 규칙을 추가해야함 => 팀클래스 리스트를 받아 추가
    for (Team i in _teamList) {
      i.addRule();
    }
  }

  // 규칙 삭제
  // 모든 팀의 경기 기록에서 제거된 규칙에 할당된 공간을 지움
  void removeRule(int index) {
    _ruleList.removeAt(index);

    // 모든 팀 클래스에서 규칙을 삭제해야함 => 팀클래스 리스트를 받아 삭제
    for (Team i in _teamList) {
      i.removeRule(index);
    }
  }

  List<Team> getTeams() {
    return List.unmodifiable(_teamList);
  }

  // 팀 추가
  void addTeam(Team team) {
    // 새 팀의 경기 규칙 상태를 _ruleList와 동기화함
    int len = _ruleList.length;
    for (int i = 0; i < len; i++) {
      team.addRule();
    }

    _teamList.add(team);
  }

  // 팀 삭제
  void removeTeam(int index) {
    _teamList.removeAt(index);
  }

  // Team 클래스 메소드 Wrapper들
  // 원본 메소드에서 teamIndex로 팀을 골라야 하는 제한이 추가됨

  void addGameToTeam(int teamIndex, int ruleIndex, ScoreRecord game) {
    _teamList[teamIndex].addGame(ruleIndex, game);
  }

  Records getTeamRecordOfRule(int teamIndex, int ruleIndex) {
    return _teamList[teamIndex].getRecordOfRule(ruleIndex);
  }

  int getTeamPlayCountOfRule(int teamIndex, int rule) {
    return _teamList[teamIndex].getPlayCountOfRule(rule);
  }

  List<String> getTeamMembers(int teamIndex) {
    return _teamList[teamIndex].getMembers();
  }
}

// 데이터베이스 관리 클래스
// 모든 필드를 static으로 만들어서 인스턴스 없이 바로 메소드를 사용함
// 변수에 대입하지 않고 Database.메소드 형식으로 사용
class Database {
  // 데이터베이스 저장공간
  static late final Box _box;

  // 로드한 DataManager
  static late final DataManager _dataManager;

  // 로드한 설정(Settings) 데이터
  static late final Settings _settings;

  // 초기화
  // Hive.initFlutter() 이후 앱 시작전에 이 메소드를 호출해야함
  static void init() {
    _box = Hive.box(AppData.dbBoxKey);
    _dataManager =
        _box.get(AppData.dbDataManagerKey, defaultValue: DataManager([], []));
    _settings = _box.get(AppData.dbSettingsKey, defaultValue: Settings(1));
  }

  // _dataManager를 저장
  static void _saveDataManager() {
    _box.put(AppData.dbDataManagerKey, _dataManager);
  }

  // 아래는 _dataManager의 메소드를 간접적으로 사용하기 위한 Wrapper들임
  // 기본적으로 DataManager의 메소드들과 같은 동작을 함
  // 추가/제거 메소드는 동작 후 DB에 변경사항이 자동으로 저장됨

  static void addRule(Rule rule) {
    _dataManager.addRule(rule);
    _saveDataManager();
  }

  static void removeRule(int index) {
    _dataManager.removeRule(index);
    _saveDataManager();
  }

  static String getRuleName(int index) {
    return _dataManager.getRuleName(index);
  }

  static List<Rule> getRules() {
    return _dataManager.getRules();
  }

  static void addTeam(Team team) {
    _dataManager.addTeam(team);
    _saveDataManager();
  }

  static void removeTeam(int index) {
    _dataManager.removeTeam(index);
    _saveDataManager();
  }

  static List<Team> getTeams() {
    return _dataManager.getTeams();
  }

  static void addGameToTeam(int teamIndex, int ruleIndex, ScoreRecord game) {
    _dataManager.addGameToTeam(teamIndex, ruleIndex, game);
    _saveDataManager();
  }

  static Records getTeamRecordOfRule(int teamIndex, int ruleIndex) {
    return _dataManager.getTeamRecordOfRule(teamIndex, ruleIndex);
  }

  static int getTeamPlayCountOfRule(int teamIndex, int rule) {
    return _dataManager.getTeamPlayCountOfRule(teamIndex, rule);
  }

  static List<String> getTeamMembers(int teamIndex) {
    return _dataManager.getTeamMembers(teamIndex);
  }

  // 설정을 저장
  static void _saveSettings() {
    _box.put(AppData.dbSettingsKey, _settings);
  }

  // 설정을 가져옴
  static Settings getSettings() {
    return Settings(_settings.scaleFactor);
  }

  // 확대 상수를 변경하고 저장
  static void setScaleFactor(double factor) {
    _settings.scaleFactor = factor;
    _saveSettings();
  }
}

@HiveType(typeId: 6)
// 설정 데이터 클래스
class Settings {
  // 화면을 확대할 때 몇 배로 하는지 결정하는 상수
  @HiveField(0)
  double scaleFactor;

  Settings(this.scaleFactor);
}

/*
// 통계 클래스
class Statistics {
  // 기울기와 y절편 변수 초기화
  double slope = 0, y_intercept = 0;

  // 평균을 구해주는 함수
  double Average(List<int> scores) {
    var sum = 0;
    for (var i in scores) {
      sum += i;
    }
    return sum / scores.length;
  }

  // 선형회귀함수
  // x축은 지금까지 플레이한 게임 횟수
  // y축은 점수
  void Linear_rgression(List<int> scores) {
    // sum1은 기울기의 분자
    // sum2는 기울기의 분모
    double sum1 = 0, sum2 = 0;

    // x와 y의 평균 변수
    double x_bar = (scores.length + 1) / 2;
    double y_bar = Average(scores);

    // x = x값 - x평균
    // y = y값 - y평균
    double x, y;
    for (int i = 0; i < scores.length; i++) {
      x = (i + 1 - x_bar);
      y = (scores[i] - y_bar);
      sum1 += x * y;
      sum2 += x * x;
    }
    slope = sum1 / sum2;
    y_intercept = y_bar - (slope * x_bar);
  }
}
*/

class ScoreRecordAnalyzer {
  static double calcAverage(ScoreRecord scores) {
    final len = scores.len();
    if (len == 0) {
      return 0;
    } else {
      return scores.sum() / scores.len();
    }
  }

  static double predictNext(ScoreRecord scores) {
    final int len = scores.len();
    if (len < 2) {
      return double.nan;
    }
    double sum1 = 0, sum2 = 0;

    // x와 y의 평균 변수
    double xBar = (len + 1) / 2;
    double yBar = calcAverage(scores);

    // x = x값 - x평균
    // y = y값 - y평균
    double x, y;
    for (int i = 0; i < len; i++) {
      x = (i + 1 - xBar);
      y = (scores.index(i).value - yBar);
      sum1 += x * y;
      sum2 += x * x;
    }
    final double slope = sum1 / sum2;
    final double yIntercept = yBar - (slope * xBar);

    // x가 1부터 시작해서 마지막 값의 x는 len + 1임
    return slope * (len + 1) + yIntercept;
  }
}

class TeamAnalyzer {
  // first는 평균, second는 표준편차
  static Pair<double, double> calcAvgOfRule(Team team, int rule) {
    List<ScoreRecord> records = team.getRecordOfRule(rule).getRecords();
    var len = records.length;
    if (len < 3) {
      return const Pair(double.nan, double.nan);
    } else {
      var record1 = records[len - 3];
      var record2 = records[len - 2];
      var record3 = records[len - 1];

      var sum1 = record1.sum();
      var sum2 = record2.sum();
      var sum3 = record3.sum();

      var avg = (sum1 + sum2 + sum3) / 3;

      return Pair(
          avg, sqrt((pow(sum1, 2) + pow(sum2, 2) + pow(sum3, 2)) / 3 - pow(avg, 2)));
    }
  }
}

class Pair<X, Y> {
  final X first;
  final Y second;

  const Pair(this.first, this.second);

  @override
  String toString() {
    return "($first, $second)";
  }
}

class GlobalState {
  static bool isRunning = false;
}
