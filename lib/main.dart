import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:vcp/authorization.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vcp/auth/auth.dart';
import 'package:vcp/router/router_bloc.dart';
import 'package:vcp/router/router_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(
    MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (_) => AuthBloc())],
      child: const MyApp(),
    ),
  );
}

const apiServiceBaseURL =
    "https://workplace-anatomy-speaker-merry.trycloudflare.com";
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: RouterCubit(context.read()),
      builder: (context, GoRouter state) {
        return MaterialApp.router(
          routerConfig: state,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
        );
      },
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
      final client = BrowserClient()..withCredentials = true;

      final res = await client.get(
        Uri.parse('https://$apiServiceBaseURL/api/meet'),
      );
      // final res = await get(Uri.parse('https://$apiServiceBaseURL/meet'), headers: );
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
          (constraints.maxWidth - actionSpaceWidth) / 2,
          8,
        );
        return Scaffold(
          backgroundColor: Color(0xFFE8EBF7),
          body: switch (state) {
            Data(:final data) => CustomScrollView(
              slivers: [
                SliverAppBar(leading: Text("VCP"), actions: [
                  ],
                ),
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

class AuthHandleGoogle extends StatefulWidget {
  const AuthHandleGoogle({super.key});

  @override
  State<AuthHandleGoogle> createState() => _AuthHandleGoogleState();
}

class _AuthHandleGoogleState extends State<AuthHandleGoogle> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) return;

    final cookies = html.document.cookie;

    if (cookies == null) return;

    const prefix = "authorization=";

    for (final item in cookies.split(";")) {
      final cookie = item.trim();

      if (!cookie.startsWith(prefix)) continue;

      final cookieValue = cookie.substring(prefix.length);

      ApiService.initialize(cookieValue);

      _persistAndMove(cookieValue);

      break;
    }
  }

  Future<void> _persistAndMove(String auth) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("authorization", auth);

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      moveToHome(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: 100,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void moveToHome(_) {
    context.go('/login');
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FilledButton(
        onPressed: () {
          launchUrl(
            Uri.parse("$apiServiceBaseURL/api/auth/google"),
            webOnlyWindowName: "_self",
          );
        },
        child: Text("Sign in With Google"),
      ),
    );
  }
}

class GettingStarted extends StatefulWidget {
  const GettingStarted({super.key});

  @override
  State<GettingStarted> createState() => _GettingStartedState();
}

class _GettingStartedState extends State<GettingStarted> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Getting Started"),
        actions: [
          FilledButton(
            onPressed: () {
              launchUrl(
                Uri.parse("$apiServiceBaseURL/api/auth/google"),
                webOnlyWindowName: "_self",
              );
            },
            child: Text("Sign in With Google"),
          ),
        ],
      ),
    );
  }
}
