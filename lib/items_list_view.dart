library items_list_view;

import 'package:flutter/material.dart';

class ItemsListView<T> extends StatefulWidget {
  final ItemsLoader<T> itemsLoader;
  final ItemWidgetBuilder<T> itemBuilder;
  final Widget loadingWidget;
  final Widget emptyItemsWidget;
  final int pageSize;

  ItemsListView(
      {Key key,
      @required this.itemsLoader,
      @required this.itemBuilder,
      this.loadingWidget,
      this.emptyItemsWidget,
      this.pageSize = 10})
      : super(key: key);

  @override
  ItemsListViewState<T> createState() => ItemsListViewState<T>(
      itemsLoader: itemsLoader,
      itemBuilder: itemBuilder,
      loadingWidget: loadingWidget,
      emptyItemsWidget: emptyItemsWidget,
      pageSize: pageSize);
}

class ItemsListViewState<T> extends State<ItemsListView<T>> {
  final ItemsLoader<T> itemsLoader;
  final ItemWidgetBuilder<T> itemBuilder;
  final Widget loadingWidget;
  final Widget emptyItemsWidget;
  final int pageSize;

  ItemsListViewState(
      {@required this.itemsLoader,
      @required this.itemBuilder,
      this.loadingWidget,
      this.emptyItemsWidget,
      this.pageSize = 10});

  ScrollController controller;

  List<T> items = List<dynamic>();
  bool isLast = false;
  bool isFirst = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    controller = new ScrollController()..addListener(_scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(_scrollListener);
  }

  void refresh() {
    setState(() {
      isFirst = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFirst) {
      var firstPage = loadPage(0);
      return FutureBuilder(
        future: firstPage,
        builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              items = snapshot.data;
              isFirst = false;
              return buildList(context);
            }
          }
          return loadingWidget ?? Center(child: CircularProgressIndicator());
        },
      );
    }
    return buildList(context);
  }

  Widget buildList(BuildContext context) {
    if (items.length == 0) {
      return emptyItemsWidget ?? Container();
    }
    var count = items.length;
    var loadingIndex = -1;
    if (isLoading) {
      count += 1;
      loadingIndex = items.length;
    }
    return Scrollbar(
        child: ListView.builder(
            controller: controller,
            itemCount: count,
            itemBuilder: (context, index) {
              if (loadingIndex == index) {
                return Center(
                    child: Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator()));
              }
              return itemBuilder(context, items[index]);
            }));
  }

  void _scrollListener() async {
    if (isLoading) return;

    isLoading = true;
    setState(() {});
    if (controller.position.extentAfter < 10) {
      if (!isLast) {
        var page = await loadPage(items.length);
        items.addAll(page);
      }
    }
    isLoading = false;
    setState(() {});
  }

  Future<List<T>> loadPage(int index) async {
    var skip = (index ~/ pageSize) * pageSize;

    var result = await itemsLoader(skip, pageSize);
    isLast = result.length < pageSize;
    return result;
  }
}

typedef ItemWidgetBuilder<T> = Widget Function<T>(BuildContext context, T item);
typedef ItemsLoader<T> = Future<List<T>> Function<T>(int skip, int take);
