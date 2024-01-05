import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertItem(String title) async {
    final Database? db = await database;
    await db!.insert(
      'items',
      {'title': title},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getItems() async {
    final Database? db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('items');

    return List.generate(maps.length, (i) {
      return maps[i]['title'];
    });
  }

  Future<void> clearItems() async {
    final Database? db = await database;
    await db!.delete('items');
  }
}

class ApiPaginationPage2 extends StatefulWidget {
  const ApiPaginationPage2({super.key});

  @override
  ApiPaginationPage2State createState() => ApiPaginationPage2State();
}

class ApiPaginationPage2State extends State<ApiPaginationPage2> {
  final ScrollController _scrollController = ScrollController();
  List<String> items = [];
  bool isLoading = false;
  int currentPage = 1;
  DatabaseHelper dbHelper = DatabaseHelper();
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _checkConnectivity();
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
    List<String> offlineData = await dbHelper.getItems();
    if (offlineData.isNotEmpty) {
      setState(() {
        items = offlineData;
      });
    } else if (isOnline) {
      await _fetchAndSaveData(currentPage);
    }
  }

  Future<void> _loadMoreData() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      await _fetchAndSaveData(currentPage);

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAndSaveData(int page) async {
    final response = await _fetchData(page);

    setState(() {
      items.addAll(response);
      currentPage++;
    });

    // Save the fetched data to the local database
    for (String title in response) {
      await dbHelper.insertItem(title);
    }
  }

  Future<List<String>> _fetchData(int page) async {
    final String apiUrl =
        'https://jsonplaceholder.typicode.com/posts?_page=$page';

    final response = await http.get(Uri.parse(apiUrl));
    print('response=> $response');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['title'].toString()).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOnline = false;
      });
    } else {
      setState(() {
        isOnline = true;
      });
    }
  }

  Future<void> _refreshData() async {
    if (isOnline) {
      await dbHelper.clearItems();
      setState(() {
        items = [];
        currentPage = 1;
        isLoading = false;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    print(isOnline);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paginated List App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(),
        child: ListView.builder(
          physics: const ClampingScrollPhysics(),
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
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
