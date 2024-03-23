import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  CustomTabBar({required this.controller, required this.tabs});

  final TabController controller;
  final List<Widget> tabs;

  @override
  Widget build(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;
    double tabBarScaling = screenWidth > 1400? 3.21: screenWidth > 1100? 0.6:0.4;
    return Padding(
      padding: EdgeInsets.only(right: screenWidth*0.05),
      child: Container(
      width: screenWidth*tabBarScaling,
            child: Theme
            (
              data: ThemeData(
                highlightColor: Colors.transparent,
                splashColor: Colors.grey,
                hoverColor: Colors.transparent
              ),
              child: TabBar(
                controller: controller, tabs: tabs,
                indicatorColor: Colors.white,
              )
            ),
      ),
    );      
        
    
  }
}