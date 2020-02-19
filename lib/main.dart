import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:ui';

//Firebase Realtime Databaseを利用
import 'package:firebase_database/firebase_database.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => TimeTableView(),
        '/regist': (context) => ClassRegistView(),
        '/confirm': (context) => ClassConfirmView(),
      },
    );
  }
}

//ホーム画面。
//登録した時間割の閲覧。
class TimeTableView extends StatefulWidget {

  TimeTableView({Key key}) : super(key: key);

  @override
  _TimeTableViewState createState() => _TimeTableViewState();
}

class _TimeTableViewState extends State<TimeTableView>
with SingleTickerProviderStateMixin {

  final List<Tab> _tabs = <Tab>[
    Tab(text: '１週間の時間割'),
    Tab(text: '集中講義'),
  ];
  final List<String> _days = [
    '月', '火', '水', '木', '金',
  ];

  TabController _tabController;

  int _dayIndex;
  int _periodIndex;
  List<Widget> _classList = [];
  List<String> _tableSetClassNames = List(25);
  List<String> _tableSetTeacherNames = List(25);
  List<int> _tableSetColorIds = List(25);

  List<Widget> _intensiveClassList = <Widget>[];
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState()  {
    _tabController = TabController(
      vsync: this,
      length: _tabs.length,
    );
    for (var i = 0; i < 25; i++) {
      _tableSetClassNames[i] = '';
      _tableSetTeacherNames[i] = '';
      _tableSetColorIds[i] = 0;
    }
    getTables();
    getIntensiveClasses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('時間割アプリ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            margin: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
//                  constraints: BoxConstraints(maxWidth: 29.0 + 57.8 * 5),
                  color: Colors.black12,
                  padding: EdgeInsets.only(left: 29.0),
                  child: GridView.count(
                    crossAxisCount: 5,
                    physics: ScrollPhysics(),
                    shrinkWrap: true,
//                    childAspectRatio: 60 / 36,
                    childAspectRatio: (MediaQuery.of(context).size.width - 50*2 - 29) / 5 / 30, //画面幅に応じて幅可変、高さは30で固定
                    children: daySet(),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        constraints: BoxConstraints.expand(width: 29.0),
                        child: GridView.count(
                          crossAxisCount: 1,
                          physics: ScrollPhysics(),
                          shrinkWrap: true,
                          childAspectRatio: 29.0 / 85.6,
                          children: periodSet(),
                        ),
                      ),
                      Container(
//                        constraints: BoxConstraints.expand(width: 57.8 * 5),
                          constraints: BoxConstraints.expand(width: (MediaQuery.of(context).size.width - 50*2 -29 + 58)),
                          child: GridView.count(
                          crossAxisCount: 5,
                          physics: ScrollPhysics(),
                          shrinkWrap: true,
//                          childAspectRatio: 60 / 99.6,
                          childAspectRatio: (MediaQuery.of(context).size.width - 50*2 - 29 + 58) / 5 / 85.6,
                          children: classSet(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListView(
            shrinkWrap: true,
            children: _intensiveClassList,
          ),
        ],
      ),


      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: ConstantValues().getBottomNavigationBarItems(),
        onTap: (int value) => tapBottomIcon(value, context),
      ),
    );
  }

  void tapBottomIcon(int value, BuildContext context) {
    if (value == 1) {
      Navigator.pushNamed(context, '/regist');
    }
    else if(value == 2) {
      Navigator.pushNamed(context, '/confirm');
    }
  }

  List<Widget> daySet() {
    List<Widget> days = [];

    for (var i = 0; i < 5; i++) {
      days.add(
        Container(
          child: Center(
            child: Text(
              _days[i] + '曜日',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w200,
                fontFamily: "Roboto",
              ),
            ),
          ),
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: Color.fromARGB(100, 0, 0, 0)),
            ),
          ),
        ),
      );
    }

    return days;
  }

  List<Widget> periodSet() {
    List<Widget> periods = [];

    for (var i = 0; i < 5; i++) {
      var j = i + 1;
      periods.add(
        Container(
          padding: EdgeInsets.only(left: 5.0),
          child: Center(
            child: Text(
              "$j限",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w200,
                fontFamily: "Roboto",
              ),
            ),
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Color.fromARGB(100, 0, 0, 0)),
            ),
            color: Colors.black12,
          ),
        ),
      );
    }

    return periods;
  }

  List<Widget> classSet(BuildContext context) {
    List<Widget> classes = [];

    for (var i = 0; i < 5 * 5; i++) {
      classes.add(
        Container(
          child: FlatButton(
            color: ConstantValues().getColorList(150)[_tableSetColorIds[i]],
            padding: EdgeInsets.all(0.0),
            onPressed: () => tapTable(context, i),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _tableSetClassNames[i].length < 21 ? _tableSetClassNames[i] : _tableSetClassNames[i].substring(0, 20),
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      fontFamily: "Roboto",
                    ),
                  ),
                  Text(
                    _tableSetTeacherNames[i].length < 15 ? _tableSetTeacherNames[i] : _tableSetTeacherNames[i].substring(0, 15),
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w400,
                      fontFamily: "Roboto",
                    ),
                  ),
                ],
              ),
            ),
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Color.fromARGB(100, 0, 0, 0)),
              left: BorderSide(color: Color.fromARGB(100, 0, 0, 0)),
            ),
          ),
        ),
      );
    }

    return classes;
  }

  Future<void> tapTable(BuildContext context, int i) async {

    //テーブルが空の場合
    if (_tableSetClassNames[i] == '') {
      await showRegistedClasses(context);
      Map result = await showDialog(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
          title: Text(
            '授業を選択してください。',
            style: TextStyle(
              decoration: TextDecoration.underline,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 30.0),
          children: _classList,
        ),
      );

      if (result != null) {
        await setTable(result, i);
      }
    }

    //既に登録されている場合
    else {
      _dayIndex = i % 5;

      if (i < 5) {
        _periodIndex = 1;
      }
      else if (i < 10) {
        _periodIndex = 2;
      }
      else if (i < 15) {
        _periodIndex = 3;
      }
      else if (i < 20) {
        _periodIndex = 4;
      }
      else {
        _periodIndex = 5;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('【' + _days[_dayIndex] + '曜' + _periodIndex.toString() + '限' + '】'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _tableSetClassNames[i],
                  style: TextStyle(fontSize: 24.0),
                ),
                Padding(
                  padding: EdgeInsets.all(5.0),
                ),
                Text(
                  '（' + _tableSetTeacherNames[i] + '）',
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                '削除',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                setState(() {
                  _tableSetClassNames[i] = '';
                  _tableSetTeacherNames[i] = '';
                  _tableSetColorIds[i] = 0;
                });
                deleteTable(i);
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('詳細'),
              onPressed: () async {
                int colorId = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/tableEdit'),
                    builder: (BuildContext context) => TableEditView(tableId: i),
                  ),
                );

                if (colorId != null)
                  setState(() {
                    _tableSetColorIds[i] = colorId;
                  });

                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> showRegistedClasses(BuildContext context) async {

    //クラウド上の授業データをリストに追加
    List<Widget> defaultClassList = <Widget>[];
    defaultClassList = [
      Center(
        child: Text(
          '【デフォルトの授業】',
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10.0),
      ),
    ];

    DataSnapshot snapshot = await ConnectToDatabase().toCloud();
    List<dynamic> cloudClasses = await snapshot.value;

    for (Map map in cloudClasses) {
      if (map != null) {
        defaultClassList.add(
          SimpleDialogOption(
            onPressed: () => Navigator.pop<Map>(context, map),
            child: Wrap(
              direction: Axis.vertical,
              children: <Widget>[
                Text(
                  map['className'],
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  '（' + map['teacherName'] + '）',
                  style: TextStyle(
                    fontSize: 12.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(3.0),
                )
              ],
            ),
          ),
        );
      }
    }

    if (defaultClassList.length < 3) {
      defaultClassList.add(
        Center(
          child: Text(
            'デフォルトの授業が存在しません。',
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      );
    }
    setState(() {
      _classList = defaultClassList;
    });

    //カスタムで登録した授業データをリストに追加
    List<Widget> customClassList = <Widget>[];
    customClassList = [
      Center(
        child: Text(
          '【登録した授業】',
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(10.0),
      ),
    ];

    Database database = await ConnectToDatabase().toLocal('classData');

    List<Map> localClasses = await database.rawQuery('SELECT * FROM classData');

    for (Map map in localClasses) {
      customClassList.add(
        SimpleDialogOption(
          onPressed: () => Navigator.pop<Map>(context, map),
          child: Wrap(
            direction: Axis.vertical,
            children: <Widget>[
              Text(
                map['className'],
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              Text(
                '（' + map['teacherName'] + '）',
                style: TextStyle(
                  fontSize: 12.0,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(3.0),
              )
            ],
          ),
        ),
      );
    }

    if (customClassList.length < 3) {
      customClassList.add(
        Center(
          child: Text(
            '登録された授業がありません。',
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      );
    }

    setState(() {
      _classList.addAll(customClassList);
    });
  }

  Future<void> setTable(Map map, int i) async {
    setState(() {
      _tableSetClassNames[i] = map['className'];
      _tableSetTeacherNames[i] = map['teacherName'];
    });

    Database database = await ConnectToDatabase().toLocal('tableData');

    String query = 'INSERT INTO tableData(id, className, teacherName, colorId) VALUES($i, "' + map['className'] + '", "' + map['teacherName'] +'", 0)';

    await database.transaction((txn) async {
      txn.rawInsert(query);
    });
  }

  Future<void> registIntensiveClass(BuildContext context) async {

    String className = _controllerA.text;
    String teacherName = _controllerB.text;

    String query = 'INSERT INTO intensiveClassData(className, teacherName) VALUES("$className", "$teacherName")';

    Database database = await ConnectToDatabase().toLocal('intensiveClassData');

    if (className != '') {
      await database.transaction((txn) async {
        txn.rawInsert(query);
      });

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('【登録完了】'),
          content: Text('授業の新規登録が完了しました。登録した授業をMy時間割に追加することができます。'),
          actions: <Widget>[
            FlatButton(
              child: Text('閉じる'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('授業名が未記入です。'),
          actions: <Widget>[
            FlatButton(
              child: Text('閉じる'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    setState(() {
      _controllerA.clear();
      _controllerB.clear();
      FocusScope.of(context).requestFocus(new FocusNode());
    });
  }
  
  Future<void> saveMemo(int id) async {
    
    Database database = await ConnectToDatabase().toLocal('intensiveClassData');
    
    String query = 'UPDATE intensiveClassData set memo = "' + _memoController.text + '"where id = $id';

    await database.transaction((txn) async {
      txn.rawUpdate(query);
    });
  }

  Future<void> deleteTable(int i) async {

    Database database = await ConnectToDatabase().toLocal('tableData');

    await database.transaction((txn) async {
      txn.rawDelete('DELETE FROM tableData WHERE id = $i');
    });
  }

  Future<void> editIntensiveClass(int id) async {
    Database database = await ConnectToDatabase().toLocal('intensiveClassData');

    List<Map> result = await database.rawQuery('SELECT * FROM intensiveClassData WHERE id = $id');

    _memoController.text = result[0]['memo'];

    showDialog(
      context: this.context,
      builder: (BuildContext context) => AlertDialog(
        title: Wrap(
          alignment: WrapAlignment.center,
          direction: Axis.horizontal,
          children: <Widget>[
            Text(
              result[0]['className'],
              style: TextStyle(fontSize: 24.0)
            ),
            Text(
              '（' + result[0]['teacherName'] + '）',
                style: TextStyle(fontSize: 20.0)
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '【メモ】',
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _memoController,
                  decoration: InputDecoration(
                    hintText: 'メモを追加',
                  ),
                  style: TextStyle(
                      fontSize: 20.0
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
              child: Text(
                '削除',
                style: TextStyle(color: Colors.red)
              ),
              onPressed: () async {
                await database.transaction((txn) async {
                  txn.rawDelete('DELETE FROM intensiveClassData WHERE id = $id');
                });
                getIntensiveClasses();
                Navigator.pop(context);
              }
          ),
          FlatButton(
            child: Text('メモを保存'),
            onPressed: () async {
              await saveMemo(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> getTables() async {

    Database database = await ConnectToDatabase().toLocal('tableData');
    
    List<Map> tableSetClasses = await database.rawQuery('SELECT * FROM tableData');
    for (Map tableSetClass in tableSetClasses) {
      setState(() {
        _tableSetClassNames[tableSetClass['id']] = tableSetClass['className'];
        _tableSetTeacherNames[tableSetClass['id']] = tableSetClass['teacherName'] ?? '';
        _tableSetColorIds[tableSetClass['id']] = tableSetClass['colorId'] ?? 0;
      });
    }
  }

  Future<void> getIntensiveClasses() async {
    List<Widget> list = <Widget>[];

    Database database = await ConnectToDatabase().toLocal('intensiveClassData');

//    database.execute('CREATE TABLE intensiveClassData (id INTEGER PRIMARY KEY, className TEXT, teacherName TEXT, memo TEXT, colorID INTEGER)');

    List<Map> intensiveClasses = await database.rawQuery('SELECT * FROM intensiveClassData');
    for (Map intensiveClass in intensiveClasses) {
      list.add(
        ListTile(
          title: Text(intensiveClass['className']),
          subtitle: Text('（' + intensiveClass['teacherName'] + '）'),
            onTap: () => editIntensiveClass(intensiveClass['id']),
        ),
      );
    }

    setState(() {
      if (list.length > 0) {
        _intensiveClassList = list;
      }

      //集中講義が登録されていないとき
      else {
        _intensiveClassList = [Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(top: 200.0),
            child: Text(
              '登録された集中講義は\nありません。',
              style: TextStyle(fontSize: 28.0),
            ),
          ),
        )];
      }

      //集中講義の登録ボタン
      _intensiveClassList.add(
        Padding(
          padding: EdgeInsets.all(30.0),
          child: FlatButton(
            child: Text(
              '集中講義を登録！',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w100,
              ),
            ),
            padding: EdgeInsets.all(20.0),
            color: Colors.black12,
            onPressed: ()  {
              showDialog(
                context: this.context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text(
                    '集中講義を登録',
                    style: TextStyle(
                      fontSize: 28.0,
                      decoration: TextDecoration.underline
                    ),
                  ),
                  titlePadding: EdgeInsets.all(10.0),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                '【授業名】',
                                style: TextStyle(
                                    fontSize: 20.0
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5.0),
                              ),
                              TextField(
                                controller: _controllerA,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '必須',
                                ),
                                style: TextStyle(
                                    fontSize: 20.0
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(30.0),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  '【教師・講師名】',
                                  style: TextStyle(
                                      fontSize: 20.0
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(5.0),
                                ),
                                TextField(
                                  controller: _controllerB,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20.0
                                  ),
                                ),
                              ]
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('キャンセル'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    FlatButton(
                      child: Text('登録'),
                      onPressed: () {
                        registIntensiveClass(context);
                        getIntensiveClasses();
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

//登録した時間割の詳細情報を編集する画面
class TableEditView extends StatefulWidget {

  final int tableId;

  TableEditView({Key key, @required this.tableId}) : super(key: key);

  @override
  _TableEditViewState createState() => _TableEditViewState(tableId);
}

class _TableEditViewState extends State<TableEditView> {

  final int tableId;

  _TableEditViewState(this.tableId);

  final TextEditingController _memoController = TextEditingController();
  int tableSetColorId = 0;

  @override
  void initState() {
    getClassDetail();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('授業の詳細'),
        leading: BackButton(
          color: Colors.white,
        ),
        actions: <Widget>[
          IconButton(
            icon: Text(
              '取消',
              style: TextStyle(fontSize: 16.0),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: Text(
              '保存',
              style: TextStyle(fontSize: 16.0),
            ),
            onPressed: () async {
              await saveData();
              Navigator.pop(context, tableSetColorId);
            },
          ),
        ],
      ),
      body: Container(
      color: ConstantValues().getColorList(200)[tableSetColorId],
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '【メモ】',
                        style: TextStyle(
                          fontSize: 24.0,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20.0),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: TextField(
                          controller: _memoController,
                          decoration: InputDecoration(
                            hintText: 'メモを追加',
                          ),
                          style: TextStyle(
                              fontSize: 20.0
                          ),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20.0),
                      ),
                      Text(
                        '【背景色の選択】',
                        style: TextStyle(
                          fontSize: 24.0,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10.0),
                      ),
                      GridView.extent(
                        shrinkWrap: true,
                        maxCrossAxisExtent: (MediaQuery.of(context).size.width - 100.0) / 4,
                        mainAxisSpacing: 20.0,
                        crossAxisSpacing: 20.0,
                        childAspectRatio: (1),
                        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
                        children: colorsView(context),
                      ),
                    ],
                  ),
                ),
              )
          ),
        ),
      )
    );
  }

  List<Widget> colorsView(BuildContext context) {
    List<Widget> list = [];

    for (var i = 0; i < ConstantValues().getColorList(200).length; i++) {
      list.add(
        FlatButton(
          child: Text(''),
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.black,
              width: 0.25,
              style: BorderStyle.solid,
            ),
          ),
          color: ConstantValues().getColorList(200)[i],
          onPressed: () {
            setState(() {
              tableSetColorId = i;
            });
          },
        ),
      );
    }

    return list;
  }

  Future<void> getClassDetail() async {

    Database database = await ConnectToDatabase().toLocal('tableData');

    List<Map> tableSetClass = await database.rawQuery('SELECT * FROM tableData WHERE id = $tableId');

    setState(() {
      _memoController.text = tableSetClass[0]['memo'] ?? '';
      tableSetColorId = tableSetClass[0]['colorId'] ?? 0;
    });
  }

  Future<void> saveData() async {

    Database database = await ConnectToDatabase().toLocal('tableData');

    String query = 'UPDATE tableData set memo = "' + _memoController.text + '", colorId = $tableSetColorId where id = $tableId';

    await database.transaction((txn) async {
      txn.rawUpdate(query);
    });
  }
}

//授業をカスタムで新規登録する画面
class ClassRegistView extends StatefulWidget {

  ClassRegistView({Key key}) : super(key: key);

  @override
  _ClassRegistViewState createState() => _ClassRegistViewState();
}

class _ClassRegistViewState extends State<ClassRegistView> {

  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('授業の登録'),
      ),

      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => SingleChildScrollView(
//          physics: AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '【授業名】',
                            style: TextStyle(
                              fontSize: 20.0
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                          ),
                          TextField(
                            controller: _controllerA,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '必須',
                            ),
                            style: TextStyle(
                                fontSize: 20.0
                            ),
                          ),
                        ]
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(50.0),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '【教師・講師名】',
                            style: TextStyle(
                                fontSize: 20.0
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                          ),
                          TextField(
                            controller: _controllerB,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20.0
                            ),
                          ),
                        ]
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: ConstantValues().getBottomNavigationBarItems(),
        onTap: (int value) => tapBottomIcon(value, context),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () => registData(context),
      ),
    );
  }

  void tapBottomIcon(int value, BuildContext context) {
    if (value == 0) {
      Navigator.pop(context);
    }
    else if(value == 2) {
      Navigator.popAndPushNamed(context, '/confirm');
    }
  }

  void registData(BuildContext context) async {

    String className = _controllerA.text;
    String teacherName = _controllerB.text;

    String query = 'INSERT INTO classData(className, teacherName) VALUES("$className", "$teacherName")';

    Database database = await ConnectToDatabase().toLocal('classData');

    if (className != '') {
      await database.transaction((txn) async {
        txn.rawInsert(query);
      });

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('【登録完了】'),
          content: Text('授業の新規登録が完了しました。登録した授業をMy時間割に追加することができます。'),
          actions: <Widget>[
            FlatButton(
              child: Text('閉じる'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('授業名が未記入です。'),
          actions: <Widget>[
            FlatButton(
              child: Text('閉じる'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    setState(() {
      _controllerA.clear();
      _controllerB.clear();
      FocusScope.of(context).requestFocus(new FocusNode());
    });
  }
}

//クラウドに登録されている授業と、カスタムで追加登録した授業の一覧を閲覧する画面
//クラウドデータベースはFirebase Realtime Databaseを用いる。
class ClassConfirmView extends StatefulWidget {

  ClassConfirmView({Key key}) : super(key: key);

  @override
  _ClassConfirmViewState createState() => _ClassConfirmViewState();
}

class _ClassConfirmViewState extends State<ClassConfirmView>
with SingleTickerProviderStateMixin {

  final List<Tab> _tabs = <Tab>[
    Tab(text: 'デフォルトの授業'),
    Tab(text: '登録した授業'),
  ];

  TabController _tabController;
  List<Widget> _defaultClasses = <Widget>[];
  List<Widget> _customClasses = <Widget>[];

  @override
  void initState() {
    getDefaultClasses();
    getCustomClasses();
    _tabController = TabController(
      vsync: this,
      length: _tabs.length,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('授業一覧'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          ListView(
        shrinkWrap: true,
            children: _defaultClasses,
          ),
          ListView(
        shrinkWrap: true,
            children: _customClasses,
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: ConstantValues().getBottomNavigationBarItems(),
        onTap: (int value) => tapBottomIcon(value, context),
      ),
    );
  }

  Future<void> getDefaultClasses() async {
    List<Widget> list = <Widget>[];

    DataSnapshot snapshot = await ConnectToDatabase().toCloud();

    List<dynamic> classList = await snapshot.value;
    for (Map classData in classList) {
      if (classData != null) {
        list.add(
          ListTile(
            title: Text(classData['className']),
            subtitle: Text('（' + classData['teacherName'] + '）'),
          ),
        );
      }
    }

    setState(() {
      if (list.length > 0) {
        _defaultClasses = list;
      }
      //クラウド上にデータが１つもないとき
      else {
        _defaultClasses = [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: 250.0),
              child: Text(
                'デフォルトの授業が存在しません',
                style: TextStyle(fontSize: 28.0),
              ),
            ),
          )
        ];
      }
    });
  }

  void getCustomClasses() async {
    List<Widget> list = <Widget>[];

    Database database = await ConnectToDatabase().toLocal('classData');

    List<Map> result = await database.rawQuery('SELECT * FROM classData');

    for (Map map in result) {
      list.add(
        ListTile(
          title: Text(map['className']),
          subtitle: Text('（' + map['teacherName'] + '）'),
          onTap: () => unregistClass(map['id']),
        )
      );
    }

    setState(() {
      if (list.length > 0) {
        _customClasses = list;
      }
      //登録されたデータが１つもないとき
      else {
        _customClasses = [Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(top: 250.0),
            child: Text(
              '登録された授業は\nありません。',
              style: TextStyle(fontSize: 28.0),
            ),
          ),
        )];
      }
    });
  }

  Future<void> unregistClass(int id) async {

    Database database = await ConnectToDatabase().toLocal('classData');

    List<Map> result = await database.rawQuery('SELECT * FROM classData WHERE id = $id');

    showDialog(
      context: this.context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(result[0]['className'],textAlign: TextAlign.center,),
        content: Text('（' + result[0]['teacherName'] + '）', textAlign: TextAlign.center,),
       actions: <Widget>[
         FlatButton(
           child: Text(
               '削除',
               style: TextStyle(color: Colors.red)
           ),
           onPressed: () async {
             await database.transaction((txn) async {
               txn.rawDelete('DELETE FROM classData WHERE id = $id');
             });
             getCustomClasses();
             Navigator.pop(context);
           }
         ),
         FlatButton(
           child: Text('閉じる'),
           onPressed: () => Navigator.pop(context),
         ),
       ],
      ),
    );
  }

  void tapBottomIcon(int value, BuildContext context) {
    if (value == 0) {
      Navigator.pop(context);
    }
    else if(value == 1) {
      Navigator.popAndPushNamed(context, '/regist');
    }
  }
}

//複数個所で使われる定数やWidgetをまとめたクラス
class ConstantValues {

  List<Color> tableColors = <Color>[];
  List<BottomNavigationBarItem> bottomNavigationBarItems = <BottomNavigationBarItem>[];

  //Color型のリストを取得
  List<Color> getColorList(int opacity) {

    tableColors = [
      Color.fromARGB(opacity, 255, 255, 255),//0 <-デフォルト値（白透明）
      Color.fromARGB(opacity, 245, 176, 144),//1
      Color.fromARGB(opacity, 252, 215, 161),//2
      Color.fromARGB(opacity, 255, 249, 177),//3
      Color.fromARGB(opacity, 215, 231, 175),//4
      Color.fromARGB(opacity, 165, 212, 173),//5
      Color.fromARGB(opacity, 162, 215, 212),//6
      Color.fromARGB(opacity, 159, 217, 246),//7
      Color.fromARGB(opacity, 163, 188, 226),//8
      Color.fromARGB(opacity, 165, 154, 202),//9
      Color.fromARGB(opacity, 207, 167, 205),//10
      Color.fromARGB(opacity, 244, 180, 208),//11
    ];

    return tableColors;
  }

  List<BottomNavigationBarItem> getBottomNavigationBarItems() {

    bottomNavigationBarItems = [
      BottomNavigationBarItem(
          title: Text('My時間割'),
          icon: Icon(Icons.calendar_today)
      ),
      BottomNavigationBarItem(
          title: Text('授業を登録'),
          icon: Icon(Icons.add)
      ),
      BottomNavigationBarItem(
          title: Text('授業一覧'),
          icon: Icon(Icons.list)
      ),
    ];

    return bottomNavigationBarItems;
  }
}

//データベースに接続するための処理をまとめたクラス
class ConnectToDatabase {

  //ローカルデータベースに接続
  Future<Database> toLocal(String databaseTableName) async {

    String _query;

    switch (databaseTableName) {
      case 'classData': {
        _query = 'id INTEGER PRIMARY KEY, className TEXT, teacherName TEXT';
      }
      break;

      case 'tableData': {
        _query = 'id INTEGER PRIMARY KEY, className TEXT, teacherName TEXT, memo TEXT, colorId INTEGER';
      }
      break;

      case 'intensiveClassData': {
        _query = 'id INTEGER PRIMARY KEY, className TEXT, teacherName TEXT, memo TEXT, colorID INTEGER';
      }
      break;

      default: {
        _query = '';
      }
      break;
    }

    String dbPath = await getDatabasesPath();
    String path = join(dbPath, "timetable_for_students.db");

    Database database = await openDatabase(path, version: 1,onCreate: (Database db, int version) async {
      await db.execute('CREATE TABLE IF NOT EXISTS $databaseTableName ($_query)');
    });

    return database;
  }

  //クラウドのデータベース（Firebase Realtime Database）に接続
  Future<DataSnapshot> toCloud() async {

    DatabaseReference _reference =  FirebaseDatabase.instance.reference().child('classes').child('engineering').child('ele_info_phys').child('5_semester');

    return await _reference.once();
  }
}