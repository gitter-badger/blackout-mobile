import 'package:Blackout/typedefs.dart';
import 'package:Blackout/widget/search_bar/search_bar.dart';
import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffold;
  final StringCallback searchCallback;

  const HomeSearchBar({
    Key key,
    @required this.scaffold,
    @required this.searchCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      scaffold: scaffold,
      height: 110.0,
      callback: searchCallback,
      child: Container(
        color: Theme.of(context).accentColor,
        width: MediaQuery.of(context).size.width,
        height: 110.0,
        child: const Center(
          child: const Text(
            "Blackout",
            style: const TextStyle(color: Colors.white70, fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
