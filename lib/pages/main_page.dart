import 'package:priobike/config/priobike_theme.dart';
import 'package:priobike/config/router.dart';
import 'package:priobike/pages/overview_page.dart';
import 'package:priobike/pages/map_page.dart';
import 'package:priobike/pages/news_page.dart';
import 'package:priobike/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  var _pageController = PageController(
    initialPage: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrioBikeTheme.background,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "BikeNow",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Dresden",
                style: GoogleFonts.inter(fontSize: 20, color: Colors.white60),
              ),
            ],
          ),
        ),
        elevation: PrioBikeTheme.buttonElevation,
        toolbarHeight: 100,
        backgroundColor: Colors.black.withOpacity(0),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.fact_check,
              color: Colors.white70,
            ),
            onPressed: () => Navigator.pushNamed(context, AppPage.log),
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white70,
            ),
            onPressed: () => Navigator.pushNamed(context, AppPage.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 30, 0, 10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Fahren",
                          style: TextStyle(
                            fontSize: 23,
                            color: _currentIndex == 0
                                ? Colors.white
                                : Colors.white30,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                        _pageController.animateToPage(0,
                            duration: Duration(milliseconds: 100),
                            curve: Curves.linear);
                      }),
                  GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Statistik",
                          style: TextStyle(
                            fontSize: 23,
                            color: _currentIndex == 1
                                ? Colors.white
                                : Colors.white30,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                        _pageController.animateToPage(1,
                            duration: Duration(milliseconds: 100),
                            curve: Curves.linear);
                      }),
                  GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Karte",
                          style: TextStyle(
                            fontSize: 23,
                            color: _currentIndex == 2
                                ? Colors.white
                                : Colors.white30,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                        _pageController.animateToPage(2,
                            duration: Duration(milliseconds: 100),
                            curve: Curves.linear);
                      }),
                  GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "News",
                          style: TextStyle(
                            fontSize: 23,
                            color: _currentIndex == 3
                                ? Colors.white
                                : Colors.white30,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                        });
                        _pageController.animateToPage(
                          3,
                          duration: Duration(milliseconds: 100),
                          curve: Curves.linear,
                        );
                      }),
                ]),
          ),
          Expanded(
            child: PageView(
              onPageChanged: (value) {
                setState(() {
                  _currentIndex = value;
                });
              },
              controller: _pageController,
              children: [
                OverviewPage(),
                StatisticsPage(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: MapPage(),
                ),
                NewsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
