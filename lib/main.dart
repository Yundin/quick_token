import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  List<Function> _screens;
  int _selectedBarIndex = 0;
  final Map<CalcValue, num> calcValues = {
    CalcValue.attractionRate : 5.0,
    CalcValue.placementRate : 10,
    CalcValue.PD : 0,
    CalcValue.LGD : 1,
    CalcValue.placementTime : 30,
    CalcValue.portfolioSum : 1000000,
  };
  final Map<TokenizationValue, num> tokenizationValues = {
    TokenizationValue.creditsCount : 30,
    TokenizationValue.PD : 20,
    TokenizationValue.LGD : 10,
    TokenizationValue.creditSum : 50,
  };
  final Map<EmulationValue, num> emulationValues = {
    EmulationValue.meanmoney : 100000,
    EmulationValue.peopleCount : 5,
    EmulationValue.days : 60
  };
  final Map<RialtoValue, num> rialtoValues = {
    RialtoValue.attractionRate : 5,
    RialtoValue.placementRate : 10,
  };

  @override
  void initState() {
    super.initState();
    _screens = [
      _getTokenizationScreen,
      _getEmulationScreen,
      _getRialtoScreen,
      _getCalcScreen
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: _screens[_selectedBarIndex](),
        ),
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem> [
              BottomNavigationBarItem(icon: Icon(Icons.work), title: Text('Tokenization')),
              BottomNavigationBarItem(icon: Icon(Icons.group), title: Text('Emulation')),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance), title: Text('Rialto')),
              BottomNavigationBarItem(icon: Icon(Icons.cloud_off), title: Text('Calculator'))
            ],
            currentIndex: _selectedBarIndex,
            onTap: (int index) {
              setState(() {
                _selectedBarIndex = index;
              });
            }
        )
    );
  }

  Widget _getCalcScreen() {
    return CalcScreen(
        calcValues,
        (CalcValue index, num value) {
          setState(() {
            calcValues[index] = value;
          });
        }
    );
  }

  Widget _getTokenizationScreen() {
    return TokenizationScreen(
      tokenizationValues,
      (TokenizationValue index, num value) {
        setState(() {
          tokenizationValues[index] = value;
        });
      }
    );
  }

  Widget _getEmulationScreen() {
    return EmulationScreen(
        emulationValues,
        (EmulationValue index, num value) {
          setState(() {
            emulationValues[index] = value;
          });
        }
    );
  }

  Widget _getRialtoScreen() {
    return RialtoScreen(
        rialtoValues,
        emulationValues,
        tokenizationValues,
        (RialtoValue index, num value) {
          setState(() {
            rialtoValues[index] = value;
          });
        }
    );
  }
}

enum CalcValue { attractionRate, placementRate, PD, LGD, placementTime, portfolioSum }
class CalcScreen extends StatelessWidget {
  final Map<CalcValue, num> values;
  final double bankIncome;
  final Function(CalcValue index, num value) callback;

  CalcScreen._(this.values, this.callback, this.bankIncome);

  factory CalcScreen(Map<CalcValue, num> values, Function callback) {
    double LGD = (1 - pow((1 - (values[CalcValue.PD] / 100)), (values[CalcValue.placementTime] / 365))) * 100;
    double MDi = ((values[CalcValue.placementRate] / 100) - (365 / values[CalcValue.placementTime] + (values[CalcValue.placementRate] / 100)) * (values[CalcValue.LGD] / 100) * (LGD / 100)) * 100;
    double tokenSize = values[CalcValue.portfolioSum] * (1 + (values[CalcValue.attractionRate] / 100) * values[CalcValue.placementTime] / 365) / (1 + (MDi / 100) * values[CalcValue.placementTime] / 365);
    double bankIncome = values[CalcValue.portfolioSum] - tokenSize;
    return CalcScreen._(values, callback, bankIncome);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Ставка привлечения в процентах: ${values[CalcValue.attractionRate]}'),
        Slider(
          value: values[CalcValue.attractionRate],
          max: 30,
          divisions: 60,
          onChanged: (value) {
            callback(CalcValue.attractionRate, double.parse(value.toStringAsFixed(1)));
          },
        ),
        Text('Ставка размещения в процентах: ${values[CalcValue.placementRate]}'),
        _createHundredSlider(CalcValue.placementRate),
        Text('PD: ${values[CalcValue.PD]}'),
        Slider(
            value: values[CalcValue.PD].toDouble(),
            max: 20,
            divisions: 20,
            onChanged: (value) {
              callback(CalcValue.PD, value.round());
            }
        ),
        Text('LGD: ${values[CalcValue.LGD]}'),
        _createHundredSlider(CalcValue.LGD),
        Text('Срок размещения: ${values[CalcValue.placementTime]}'),
        Slider(
          value: values[CalcValue.placementTime].toDouble(),
          max: 365,
          divisions: 365,
          onChanged: (value) {
            callback(CalcValue.placementTime, value.round());
          },
        ),
        Text('Сумма токенизируемого портфеля: ${values[CalcValue.portfolioSum]}'),
        Slider(
          value: values[CalcValue.portfolioSum].toDouble(),
          max: 10000000,
          divisions: 100,
          onChanged: (value) {
            callback(CalcValue.portfolioSum, value.round());
          },
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
          child: Column(
            children: <Widget>[
              Text('Доход банка: ${bankIncome.toStringAsFixed(2)}'),
              Text('Доход банка в %: ${(bankIncome / values[CalcValue.portfolioSum] * 100).toStringAsFixed(2)}'),
            ],
          ),
        )
      ],
    );
  }

  Slider _createHundredSlider(CalcValue calcValue) {
    return Slider(
        value: values[calcValue].toDouble(),
        max: 100,
        divisions: 100,
        onChanged: (value) {
          callback(calcValue, value.round());
        }
    );
  }
}

enum TokenizationValue { creditsCount, PD, LGD, creditSum }
class TokenizationScreen extends StatelessWidget {
  final Map<TokenizationValue, num> values;
  final Function(TokenizationValue index, num value) callback;

  TokenizationScreen(this.values, this.callback);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Количество кредитов: ${values[TokenizationValue.creditsCount]}'),
        _createHundredSlider(TokenizationValue.creditsCount),
        Text('PD: ${values[TokenizationValue.PD]}'),
        _createHundredSlider(TokenizationValue.PD),
        Text('LGD: ${values[TokenizationValue.LGD]}'),
        _createHundredSlider(TokenizationValue.LGD),
        Text('Сумма кредита: ${values[TokenizationValue.creditSum]}'),
        _createHundredSlider(TokenizationValue.creditSum),
      ],
    );
  }

  Slider _createHundredSlider(TokenizationValue field) {
    return Slider(
        value: values[field].toDouble(),
        max: 100,
        divisions: 20,
        onChanged: (value) {
          callback(field, value.round());
        }
    );
  }
}

enum EmulationValue { meanmoney, peopleCount, days }
class EmulationScreen extends StatelessWidget {
  final Map<EmulationValue, num> values;
  final Function(EmulationValue index, num value) callback;

  EmulationScreen(this.values, this.callback);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Начальные деньги людей: ${values[EmulationValue.meanmoney]}'),
        Slider(
            value: values[EmulationValue.meanmoney].toDouble(),
            max: 1000000,
            divisions: 20,
            onChanged: (value) {
              callback(EmulationValue.meanmoney, value.round());
            }
        ),
        Text('Количество людей: ${values[EmulationValue.peopleCount]}'),
        Slider(
            value: values[EmulationValue.peopleCount].toDouble(),
            max: 15,
            min: 3,
            divisions: 13,
            onChanged: (value) {
              callback(EmulationValue.peopleCount, value.round());
            }
        ),
        Text('Количество дней эмуляции: ${values[EmulationValue.days]}'),
        Slider(
            value: values[EmulationValue.days].toDouble(),
            max: 365,
            min: 50,
            divisions: 316,
            onChanged: (value) {
              callback(EmulationValue.days, value.round());
            }
        )
      ],
    );
  }
}

enum RialtoValue { attractionRate, placementRate }
class RialtoScreen extends StatefulWidget {
  final Map<RialtoValue, num> values;
  final Map<EmulationValue, num> emulationValues;
  final Map<TokenizationValue, num> tokenizationValues;
  final Function(RialtoValue index, num value) callback;


  RialtoScreen(this.values, this.emulationValues, this.tokenizationValues, this.callback);

  @override
  _RialtoScreenState createState() => _RialtoScreenState();
}

class _RialtoScreenState extends State<RialtoScreen> {

  bool requestPending = false;
  Future<http.Response> future;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Ставка привлечения: ${widget.values[RialtoValue.attractionRate]}'),
        _createHundredSlider(RialtoValue.attractionRate),
        Text('Ставка размещения: ${widget.values[RialtoValue.placementRate]}'),
        _createHundredSlider(RialtoValue.placementRate),
        Padding(
          padding: EdgeInsets.only(top: 70),
          child: requestState(),
        )
      ],
    );
  }

  Widget requestState() {
    if (!requestPending) {
      return RaisedButton(
        onPressed: () {
          setState(() {
            requestPending = true;
            future = http.post(
                "http://emulation.dlbas.me/emulate",
                body: json.encode(
                    {}..addAll(
                        widget.values.map(mapEntry)
                    )..addAll(
                        widget.emulationValues.map(mapEntry)
                    )..addAll(
                        widget.tokenizationValues.map(mapEntry)
                    )
                )
            );
          });
        },
        child: const Text('Начать эмуляцию'),
      );
    } else {
      return FutureBuilder<http.Response>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print(snapshot.data.statusCode);
            return Text('Эмуляция запущена');
          } else if (snapshot.hasError) {
            return Text('Ошибка');
          }
          return CircularProgressIndicator();
        },
      );
    }
  }

  var mapEntry = (key, value) => MapEntry(key.toString().split('.').last, value);

  Slider _createHundredSlider(RialtoValue field) {
    return Slider(
        value: widget.values[field].toDouble(),
        max: 100,
        divisions: 20,
        onChanged: (value) {
          widget.callback(field, value.round());
        }
    );
  }
}