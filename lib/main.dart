import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      scrollBehavior: MyCustomScrollBehavior(),
      home: const Timeline(),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class Timeline extends StatefulWidget {
  const Timeline({Key? key}) : super(key: key);

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> with TickerProviderStateMixin {
  late AnimationController animationController;

  DateTime fromDate = DateTime(DateTime.now().year);
  DateTime toDate = DateTime(DateTime.now().year + 1);

  List<User> usersInChart = [];
  List<Project> projectsInChart = [];

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        duration: const Duration(microseconds: 2000), vsync: this);
    animationController.forward();

    projectsInChart = projects;
    usersInChart = users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: InteractiveViewer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: GanttChart(
                animationController: animationController,
                fromDate: fromDate,
                toDate: toDate,
                data: projectsInChart,
                usersInChart: usersInChart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class GanttChart extends StatelessWidget {
  final AnimationController animationController;
  final DateTime fromDate;
  final DateTime toDate;
  final List<Project> data;
  final List<User> usersInChart;

  late int viewRange;
  int viewRangeToFitScreen = 6;
  late Animation<double> width;

  GanttChart({
    Key? key,
    required this.animationController,
    required this.fromDate,
    required this.toDate,
    required this.data,
    required this.usersInChart,
  }) : super(key: key) {
    viewRange = calculateNumberOfMonthsBetween(fromDate, toDate);
  }

  Color randomColorGenerator() {
    var r = Random();
    return Color.fromRGBO(r.nextInt(256), r.nextInt(256), r.nextInt(256), 0.75);
  }

  int calculateNumberOfMonthsBetween(DateTime from, DateTime to) {
    return (to.month - from.month + 12 * (to.year - from.year) + 1);
  }

  int calculateDistanceToLeftBorder(DateTime projectStartedAt) {
    if (projectStartedAt.compareTo(fromDate) <= 0) {
      return 0;
    } else {
      return calculateNumberOfMonthsBetween(fromDate, projectStartedAt) - 1;
    }
  }

  int calculateRemainingWidth(
      DateTime projectStartedAt, DateTime projectEndedAt) {
    int projectLength =
        calculateNumberOfMonthsBetween(projectStartedAt, projectEndedAt);
    if (projectStartedAt.compareTo(fromDate) >= 0 &&
        projectStartedAt.compareTo(toDate) <= 0) {
      if (projectLength <= viewRange) {
        return projectLength;
      } else {
        return viewRange -
            calculateNumberOfMonthsBetween(fromDate, projectStartedAt);
      }
    } else if (projectStartedAt.isBefore(fromDate) &&
        projectEndedAt.isBefore(fromDate)) {
      return 0;
    } else if (projectStartedAt.isBefore(fromDate) &&
        projectEndedAt.isBefore(toDate)) {
      return projectLength -
          calculateNumberOfMonthsBetween(projectStartedAt, fromDate);
    } else if (projectStartedAt.isBefore(fromDate) &&
        projectEndedAt.isAfter(toDate)) {
      return viewRange;
    }
    return 0;
  }

  List<Widget> buildChartBars(
      List<Project> data, double chartViewWidth, Color color) {
    List<Widget> chartBars = [];

    for (int i = 0; i < data.length; i++) {
      var remainingWidth =
          calculateRemainingWidth(data[i].startTime, data[i].endTime);
      if (remainingWidth > 0) {
        chartBars.add(GestureDetector(
          onTap: () {
            // print('Durée: ${data[i].duration} jours');
          },
          child: Container(
            margin: EdgeInsets.only(
                left: calculateDistanceToLeftBorder(data[i].startTime) *
                    chartViewWidth /
                    viewRangeToFitScreen,
                top: i == 0 ? 4.0 : 2.0,
                bottom: i == data.length - 1 ? 4.0 : 2.0),
            child: Tooltip(
              message:
                  "Durée: ${data[i].duration} jours\n Début: ${data[i].startTime.day}/${data[i].startTime.month}/${data[i].startTime.year}\n Fin: ${data[i].endTime.day}/${data[i].endTime.month}/${data[i].endTime.year}\n",
              child: Container(
                decoration: BoxDecoration(
                  color: data[i].color ?? randomColorGenerator(),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                height: 25.0,
                width: remainingWidth * chartViewWidth / viewRangeToFitScreen,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    data[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }

    return chartBars;
  }

  Widget buildHeader(double chartViewWidth, Color color) {
    List<Widget> headerItems = [];

    DateTime tempDate = fromDate;

    headerItems.add(SizedBox(
      width: chartViewWidth / viewRangeToFitScreen,
      child: const Text(
        'NAME',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.0,
        ),
      ),
    ));

    for (int i = 0; i < viewRange; i++) {
      headerItems.add(SizedBox(
        width: chartViewWidth / viewRangeToFitScreen,
        child: Text(
          tempDate.month.toString() + '/' + tempDate.year.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ));

      int month = tempDate.month;
      int year = tempDate.year;
      if (month == 12) {
        year++;
        month = 1;
      } else {
        month++;
      }
      tempDate = DateTime(year, month);
    }

    return Container(
      height: 25.0,
      color: color.withAlpha(100),
      child: Row(
        children: headerItems,
      ),
    );
  }

  Widget buildGrid(double chartViewWidth) {
    List<Widget> gridColumns = [];

    for (int i = 0; i <= viewRange; i++) {
      gridColumns.add(Container(
        decoration: BoxDecoration(
            border: Border(
                right:
                    BorderSide(color: Colors.grey.withAlpha(100), width: 1.0))),
        width: chartViewWidth / viewRangeToFitScreen,
        //height: 300.0,
      ));
    }

    return Row(
      children: gridColumns,
    );
  }

  Widget buildChartForEachUser(
      List<Project> userData, double chartViewWidth, User user) {
    Color color = randomColorGenerator();
    var chartBars = buildChartBars(userData, chartViewWidth, color);
    return SizedBox(
      height: chartBars.length * 30.0 + 25.0 + 40.0,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Stack(fit: StackFit.loose, children: <Widget>[
            buildGrid(chartViewWidth),
            buildHeader(chartViewWidth, color),
            Container(
                margin: const EdgeInsets.only(top: 25.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                            width: chartViewWidth / viewRangeToFitScreen,
                            height: chartBars.length * 30.0 + 40.0,
                            color: color.withAlpha(100),
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: 0,
                                child: Text(
                                  user.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: chartBars,
                        ),
                      ],
                    ),
                  ],
                )),
          ]),
        ],
      ),
    );
  }

  List<Widget> buildChartContent(double chartViewWidth) {
    List<Widget> chartContent = [];

    for (var user in usersInChart) {
      List<Project> projectsOfUser = [];

      projectsOfUser = projects
          .where((project) => project.participants.contains(user.id))
          .toList();

      if (projectsOfUser.isNotEmpty) {
        chartContent
            .add(buildChartForEachUser(projectsOfUser, chartViewWidth, user));
      }
    }

    return chartContent;
  }

  @override
  Widget build(BuildContext context) {
    var chartViewWidth = MediaQuery.of(context).size.width;
    var screenOrientation = MediaQuery.of(context).orientation;

    screenOrientation == Orientation.landscape
        ? viewRangeToFitScreen = 12
        : viewRangeToFitScreen = 6;

    return MediaQuery.removePadding(
      child: ListView(children: buildChartContent(chartViewWidth)),
      removeTop: true,
      context: context,
    );
  }
}

List<Project> projects = [
  Project(
    id: 1,
    name: 'Visu 1',
    startTime: DateTime(2022, 01, 01),
    endTime: DateTime(2022, 03, 01),
    participants: [1],
  ),
  Project(
    id: 1,
    name: 'Visu 2',
    startTime: DateTime(2022, 03, 01),
    endTime: DateTime(2022, 04, 01),
    participants: [1],
  ),
];

List<User> users = [
  User(id: 1, name: 'sat1'),
  User(id: 2, name: 'sat2'),
];

class User {
  int id;
  String name;

  User({required this.id, required this.name});
}

class Project {
  int id;
  String name;
  DateTime startTime;
  DateTime endTime;
  List<int> participants;
  Color? color;
  int duration;

  Project({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.participants,
    this.color,
    this.duration = 0,
  }) {
    duration = DateTimeRange(start: startTime, end: endTime).duration.inDays;
  }
}
