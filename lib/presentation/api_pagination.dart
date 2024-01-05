import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiPaginationPage extends StatefulWidget {
  const ApiPaginationPage({super.key});

  @override
  ApiPaginationPageState createState() => ApiPaginationPageState();
}

class ApiPaginationPageState extends State<ApiPaginationPage> {
  final ScrollController _scrollController = ScrollController();
  List<String> items = [];
  bool isLoading = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadData();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Reached the bottom of the list, load more data
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    final response = await _fetchData(currentPage);

    setState(() {
      items = List<String>.from(response);
      currentPage++;
    });
  }

  Future<void> _loadMoreData() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      final response = await _fetchData(currentPage);

      setState(() {
        items.addAll(List<String>.from(response));
        currentPage++;
        isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchData(int page) async {
    final String apiUrl =
        'https://jsonplaceholder.typicode.com/posts?_page=$page';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['title'].toString()).toList();
    } else {
      throw Exception('Failed to load data');
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
            return SizedBox(
              height: 100,
              child: ListTile(
                title: Text(items[index]),
              ),
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
