import 'package:flutter/material.dart';

class OfflinePaginationPage extends StatefulWidget {
  const OfflinePaginationPage({super.key});

  @override
  OfflinePaginationPageState createState() => OfflinePaginationPageState();
}

class OfflinePaginationPageState extends State<OfflinePaginationPage> {
  final ScrollController _scrollController = ScrollController();
  List<String> items = List.generate(50, (index) => 'Item $index');
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Reached the bottom of the list, load more data
      _loadMoreData();
    }
  }

  void _loadMoreData() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      // Simulate a delay to fetch more data
      await Future.delayed(const Duration(seconds: 2));

      // Add more items to the list
      List<String> newItems =
          List.generate(20, (index) => 'New Item ${items.length + index}');
      setState(() {
        items.addAll(newItems);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paginated List App'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: items.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Show loading indicator
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            // Display item
            return ListTile(
              title: Text(items[index]),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
