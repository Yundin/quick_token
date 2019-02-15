import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Token',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(title: 'Quick Token'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedBarIndex = 0;

  final List<double> sliderValues = [5, 10, 0, 1, 30, 1000000];
  List<Function> _widgets;

  @override
  void initState() {
    super.initState();
    _widgets = [
      _getFirstScreen,
      _getSecondScreen
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _widgets[_selectedBarIndex](),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem> [
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text('Base')),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), title: Text('More'))
        ],
        currentIndex: _selectedBarIndex,
        onTap: _onBarItemTapped
      ),
    );
  }

  void _onBarItemTapped(int index) {
    setState(() {
      _selectedBarIndex = index;
    });
  }

  Widget _getFirstScreen() {
    return FirstScreen(
        sliderValues,
        (int index, double value) {
          setState(() {
            sliderValues[index] = value;
          });
        }
    );
  }

  Widget _getSecondScreen() {
    return SecondScreen(
        sliderValues,
        (double value) {
          setState(() {
            sliderValues[5] = value;
          });
        }
    );
  }
}

class FirstScreen extends StatelessWidget {
  final List<double> values;
  final double MDi;
  final double LGD;
  final Function(int index, double value) callback;

  FirstScreen._(this.values, this.callback, this.MDi, this.LGD);

  factory FirstScreen(List<double> values, Function callback) {
    double LGD = (1 - pow((1 - (values[2] / 100)), (values[4] / 365))) * 100;
    double MDi = ((values[1] / 100) - (365 / values[4] + (values[1] / 100)) * (values[3] / 100) * (LGD / 100)) * 100;
    return FirstScreen._(values, callback, MDi, LGD);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Ставка привлечения в процентах: ${values[0]}'),
        Slider(
          value: values[0],
          max: 30,
          divisions: 60,
          onChanged: (value) {
            callback(0, double.parse(value.toStringAsFixed(1)));
          },
        ),
        Text('Ставка размещения в процентах: ${values[1].toStringAsFixed(0)}'),
        _createHundredSlider(1),
        Text('PD: ${values[2].toStringAsFixed(0)}'),
        _createHundredSlider(2),
        Text('LGD: ${values[3].toStringAsFixed(0)}'),
        _createHundredSlider(3),
        Text('Срок размещения: ${values[4].toStringAsFixed(0)}'),
        Slider(
          value: values[4],
          max: 365,
          divisions: 365,
          onChanged: (value) {
            callback(4, value.roundToDouble());
          },
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
          child: Column(
            children: <Widget>[
              Text('M[Di]: ${MDi.toStringAsFixed(2)}'),
              Text('LGD по сроку: ${LGD.toStringAsFixed(2)}')
            ],
          ),
        )
      ],
    );
  }

  Slider _createHundredSlider(int position) {
    return Slider(
      value: values[position],
      max: 100,
      divisions: 100,
      onChanged: (value) {
        callback(position, value.roundToDouble());
      }
    );
  }
}

class SecondScreen extends StatelessWidget {
  final List<double> values;
  final Function(double value) callback;
  final double MDi;
  final double LGD;
  final double tokenSize;
  final double bankIncome;

  SecondScreen._(this.values, this.callback, this.MDi, this.LGD, this.tokenSize, this.bankIncome);

  factory SecondScreen(List<double> values, Function callback) {
    double LGD = (1 - pow((1 - (values[2] / 100)), (values[4] / 365))) * 100;
    double MDi = ((values[1] / 100) - (365 / values[4] + (values[1] / 100)) * (values[3] / 100) * (LGD / 100)) * 100;
    double tokenSize = values[5] * (1 + (values[0] / 100) * values[4] / 365) / (1 + (MDi / 100) * values[4] / 365);
    double bankIncome = values[5] - tokenSize;
    return SecondScreen._(values, callback, MDi, LGD, tokenSize, bankIncome);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Сумма токенизируемого портфеля: ${values[5].toStringAsFixed(0)}'),
          Slider(
            value: values[5],
            max: 10000000,
            divisions: 100,
            onChanged: (value) {
              callback(value.roundToDouble());
            },
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
            child: Column(
              children: <Widget>[
                Text('M[Di]: ${MDi.toStringAsFixed(2)}'),
                Text('Размер токена: ${tokenSize.toStringAsFixed(2)}'),
                Text('Доход банка: ${bankIncome.toStringAsFixed(2)}'),
                Text('LGD по сроку: ${LGD.toStringAsFixed(2)}')
              ],
            ),
          )
        ]
    );
  }
}
