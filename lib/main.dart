import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const borderRadius = Radius.circular(8.0);
const maxCrossAxisExtent = 200.0;

extension ListExtension<T> on List<T> {
  List<T> inBetween(T item) {
    if (isEmpty) return <T>[];
    if (length == 1) return this;
    final List<T> list = <T>[];
    for (var i = 0; i < length - 1; i++) {
      list.add(this[i]);
      list.add(item);
    }
    list.add(this[length - 1]);
    return list;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(),
    );
  }
}

abstract class AsyncValue<T> {}

class Loading<T> extends AsyncValue<T> {}

class Error<T> extends AsyncValue<T> {
  final String message;
  Error(this.message);
}

class Data<T> extends AsyncValue<T> {
  final T data;
  Data(this.data);
}

class Meet {
  final DateTime time;
  final String title;
  final String description;
  Meet(this.time, this.title, this.description);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum MeetSegment { today, future, past }

class _MyHomePageState extends State<MyHomePage> {
  static const childCountMax = 5;
  var cardConstraints = BoxConstraints(minWidth: 170, maxWidth: 208);
  final List<ButtonSegment<MeetSegment>> segments = [
    ButtonSegment(value: MeetSegment.today, label: Text('Today')),
    ButtonSegment(value: MeetSegment.future, label: Text('Future')),
    ButtonSegment(value: MeetSegment.past, label: Text('Past')),
  ];
  //space where all the widet and interaction happens
  double get actionSpaceWidth {
    return maxCrossAxisExtent * childCountMax;
  }

  int childCount(BoxConstraints constraints) {
    if (constraints.maxWidth >= cardConstraints.minWidth * childCountMax) {
      return childCountMax;
    }
    if (constraints.maxWidth >=
        cardConstraints.minWidth * (childCountMax - 1)) {
      return childCountMax - 1;
    }
    throw Exception("Assumes This Screen Size for Mobile So throwing Error");
  }

  Set<MeetSegment> selected = {MeetSegment.today};
  AsyncValue<List<Meet>> state = Loading();
  Future<void> loadMeet() async {
    try {
      final res = await get(Uri.parse('http://localhost:0437/meet'));
      if (res.statusCode != 200) {
        state = Error("res.statusCode != 200");
        return;
      }
      final data = jsonDecode(res.body);
      if (data is! List) {
        state = Error("data is! List");
        return;
      }
      final List<Meet> list = [];
      for (var item in data) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        list.add(
          Meet(
            DateTime.parse(item['time']),
            item['title'],
            item['description'],
          ),
        );
      }
      state = Data(list);
    } catch (e) {
      print(e);
      state = Error('error paring');
    }
  }

  @override
  void initState() {
    loadMeet().then<void>((_) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalPadding = max(
          constraints.maxWidth - actionSpaceWidth,
          8,
        );
        return Scaffold(
          backgroundColor: Color(0xFFE8EBF7),
          body: switch (state) {
            Data(:final data) => CustomScrollView(
              slivers: [
                SliverAppBar(leading: Text("VCP")),
                SliverPadding(
                  padding: .symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: .centerLeft,
                      child: SegmentedButton(
                        style: ButtonStyle(
                          foregroundColor: WidgetStateColor.fromMap({
                            WidgetState.selected: Colors.white,
                            WidgetState.any: Colors.black,
                          }),
                          backgroundColor: WidgetStateColor.fromMap({
                            WidgetState.selected: Color(0xFF243064),
                            WidgetState.any: Colors.transparent,
                          }),
                        ),
                        segments: segments,
                        selected: selected,
                        onSelectionChanged: (sel) {
                          selected = sel;
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      childCount: data.length,
                      (BuildContext context, int index) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 160),
                          child: MeetCard(meet: data[index]),
                        );
                      },
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 64.0,
                      crossAxisCount: childCount(constraints),
                    ),
                  ),
                ),
              ],
            ),
            Error(:final message) => Center(child: Text(message)),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }
}

class MeetCard extends StatelessWidget {
  static const num headerHeight = 4.64;
  final Meet meet;
  const MeetCard({super.key, required this.meet});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 8.0;
        return Card(
          margin: .zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(borderRadius),
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .spaceBetween,
            children: [
              SizedBox(
                height: constraints.maxHeight / headerHeight,
                child: header,
              ),
              ...<Widget>[
                    SizedBox(),
                    Text(
                      "${meet.time.hour}:${meet.time.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(color: Color(0xFF3a4574)),
                    ),
                    Text(
                      meet.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF3a4574)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: padding),
                      child: Align(
                        alignment: .centerRight,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Color(0xFF243064),
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                borderRadius.x - 4,
                              ),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            "Meet",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ]
                  .map<Widget>(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: item,
                    ),
                  )
                  .toList()
                  .inBetween(const SizedBox(height: padding)),
            ],
          ),
        );
      },
    );
  }

  Widget get header => Container(
    decoration: BoxDecoration(
      color: Color(0xFF243064),
      borderRadius: .vertical(top: borderRadius),
    ),
    child: Align(
      alignment: .centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(meet.title, style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
