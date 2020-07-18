import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then(
      (data) {
        setState(
          () {
            _toDoList = json.decode(data);
          },
        );
      },
    );
  }

  void _addToDo() {
    setState(
      () {
        Map<String, dynamic> newToDo = Map();
        newToDo['title'] = _toDoController.text;
        _toDoController.text = "";
        newToDo['ok'] = false;
        _toDoList.add(newToDo);
        _saveData();
      },
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort(
        (a, b) {
          if (a['ok'] && !b['ok']) {
            return 1;
          } else if (!a['ok'] && b['ok']) {
            return -1;
          } else {
            return 0;
          }
        },
      );
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To Do List'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _toDoController,
                      validator: (value) {
                        if (value.isEmpty) {
                          return null;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'New Task',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _addToDo;
                    } else {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text('Please return some text')));
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
              onRefresh: _refresh,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(
          () {
            _lastRemovedPos = index;
            //_lastRemoved = Map.from(_toDoList[index]);
            _lastRemoved = _toDoList.removeAt(index);
            _lastRemoved.forEach(
              (key, value) {
                print(value);
              },
            );
            _saveData();
          },
        );
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_lastRemoved["title"]} Dismissed',
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          _toDoList[index]['title'],
        ),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]['ok'] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (c) {
          setState(
            () {
              _toDoList[index]['ok'] = c;
              _saveData();
            },
          );
        },
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = jsonEncode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsStringSync();
    } catch (e) {
      return null;
    }
  }
}
