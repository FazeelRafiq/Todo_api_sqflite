import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:simple_todo_app/DataBase/db_helper.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List items = [];
  final _formKey = GlobalKey<FormState>();
  bool isAlertSet = false;
  late StreamSubscription subscription;
  var isDeviceConnected = false;
  bool _isLoading = true;
  bool isEdit = false;


  void _refreshData() async {
    final data = await SQLHelper.getAllData();
    setState(() {
      items = data;
      _isLoading = false;
    });
  }

  void initState() {
    super.initState();
    _refreshData();
    fetchData();
    getConnectivity();

  }

  getConnectivity() =>
      subscription = Connectivity().onConnectivityChanged.listen(
              (connectivityResult)async {
            isDeviceConnected = await InternetConnectionChecker().hasConnection;
            if(!isDeviceConnected && isAlertSet == false){
              showDialogBox();
              setState(() {
                isAlertSet =true;
              });
            }
          });

  void dispose(){
    subscription.cancel();
    super.dispose();
  }



  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionContrller = TextEditingController();

  void showBottomSheet(String? id) async {
    var isSynced = 0;
    if (id != null) {
      final existingData =
          items.firstWhere((element) => element['_id'] == id);
      _titleController.text = existingData['title'];
      _descriptionContrller.text = existingData['description'];
      isSynced = existingData['isSynced'] ?? 0;
    }
    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 30,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                },
                controller: _titleController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Title'),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                },
                controller: _descriptionContrller,
                maxLines: 4,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Description'),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: ElevatedButton(
                    onPressed: () async {

                      if (_formKey.currentState!.validate()) {
                        if (id == null) {
                          final isSubmitted = await submitData(
                              _titleController.text,
                              _descriptionContrller.text);
                          await _addData(_titleController.text,
                              _descriptionContrller.text, isSubmitted ? 1 : 0);
                        }

                        if (id != null) {

                          await updatedData(id, _titleController.text, _descriptionContrller.text , isSynced);
                        }
                        _titleController.text = "";
                        _descriptionContrller.text = "";

                        Navigator.of(context).pop();
                        print('Data Added');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        id == null ? 'Submit' : 'Update',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }


  //////////////////////////////////////////////

  void showBottomSqfliteSheet(int? id)async{
    if(id!=null){
      final existingData = items.firstWhere((element) => element['id'] == id);
      _titleController.text = existingData['title'];
      _descriptionContrller.text = existingData['description'];
    }
    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(top: 30 , left: 15 , right: 15, bottom: MediaQuery.of(context).viewInsets.bottom + 50,),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                },
                controller: _titleController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Title'
                ),
              ),
              SizedBox(height: 10,),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                },
                controller: _descriptionContrller,
                maxLines: 4,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Description'
                ),
              ),
              SizedBox(height: 20,),
              Center(
                child: ElevatedButton(onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (id != null) {
                      await _updateSqfliteData(id);
                    }

                    _titleController.text = "";
                    _descriptionContrller.text = "";
                    Navigator.of(context).pop();
                    print('Data Added');
                  }

                },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(id == null ? 'Submit' : 'Update', style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),),
                    )),
              )

            ],
          ),
        ),
      ),
    );
  }


  /////////////////////////////////////////////






  Future<bool> submitData(title, description) async {
    try {
      final body = {
        "title": title,
        "description": description,
        "is_completed": false
      };
      final url = "https://api.nstack.in/v1/todos";
      final uri = Uri.parse(url);
      final response = await http.post(uri,
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 201) {
        showSuccessMessage('Creation Success');
        return true;
      } else {
        showErrorMessage('Creation failed');
        print(response.body);
        return false;
      }
    } catch(e) {
      print(e.toString());
      return false;
    }
  }

  Future<void> _updateSqfliteData(int id)async{
    await SQLHelper.updateSqfliteData(id, _titleController.text, _descriptionContrller.text);
    _refreshData();
  }

  void showSuccessMessage(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showErrorMessage(String message) {
    final snackbar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  Future<void> _addData(title, description, isSynced) async {
    await SQLHelper.createData(title, description, isSynced);
    _refreshData();
  }

  Future<void> _updateData(int id, title, description, isSynced) async {
    await SQLHelper.updateData(
        id, title, description, isSynced);
    _refreshData();
  }

  Future<void> _deleteData(int id) async {
    await SQLHelper.deleteData(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.redAccent, content: Text('Data Deleted')));
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEAF4),
      appBar: AppBar(
        centerTitle: true,
        title: Text('Todo List'),
        actions: [
          IconButton(
              onPressed: ()  {
                _refreshData();
              }, icon: Icon(Icons.cloud_off)),
          IconButton(
            onPressed: () async {
              isDeviceConnected = await InternetConnectionChecker().hasConnection;

              if(!isDeviceConnected){
                showDialogBox();
              }
              else {
                List<Map<String, dynamic>> unSyncedTodos = await SQLHelper
                    .getUnSyncedData();
                for (int i = 0; i < unSyncedTodos.length; i++) {
                  await submitData(unSyncedTodos[i]['title'],
                      unSyncedTodos[i]['description']);
                  await _updateData(
                      unSyncedTodos[i]['id'], unSyncedTodos[i]['title'],
                      unSyncedTodos[i]['description'], 1);
                }
              }
              _refreshData();
            },
            icon: const Icon(Icons.send),
          ),

        ],
        leading: IconButton(
            onPressed: () async {
          isDeviceConnected =
              await InternetConnectionChecker().hasConnection;

          if (!isDeviceConnected) {
            showDialogBox();
          }
          else {
            fetchData();
          }
        }, icon: Icon(Icons.sync)),

      ),
      body:Visibility(
        visible: _isLoading,
        child: Center(
    child: CircularProgressIndicator(),
    ),
        replacement: RefreshIndicator(
    onRefresh: fetchData,
        child: Visibility(
          visible: items.isNotEmpty,
          replacement: Center(
            child: Text('No do Items'),
          ),
          child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items [index];
                    final id = item['_id'];
                   return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text("${index + 1}")),
                          title: Padding(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              items[index]['title'],
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          subtitle: Text(items[index]['description']),
                          trailing: PopupMenuButton(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                isDeviceConnected =
                                await InternetConnectionChecker().hasConnection;

                                if (!isDeviceConnected) {
                                  showBottomSqfliteSheet(items[index]['id']);
                                }
                                else {
                                  showBottomSheet(id);
                                }

                              } else if (value == 'delete') {
                                isDeviceConnected =
                                await InternetConnectionChecker().hasConnection;

                                if (!isDeviceConnected) {
                                  _deleteData(items[index]['id']);
                                }
                                else {
                                  deleteById(id);
                                  _deleteData(items[index]['id']);

                                }
                              }
                            },
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(child: Text('Edit'), value: 'edit'),
                                PopupMenuItem(
                                  child: Text('Delete'),
                                  value: 'delete',
                                ),
                              ];
                            },
                          ),
                        ),
                      );

  }
  ),
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: Icon(Icons.add),
      ),
    );
  }

// final conn =  SQLHelper.db;
// Future<List<TodoModelClass>> fetchAllData()async{
//   final dbClient = await conn.db();
//   List<TodoModelClass> todoList = [];
//   try{
//     Map<List<String, dynamic>> maps = await dbClient.query(SQLHelper.createData);
//     for (var item in maps){
//       todoList.add(TodoModelClass.fromJson(item));
//     }
//   }catch(e){
//
//   }
// }

  Future<void> deleteById(String id) async{
    final url = "https://api.nstack.in/v1/todos/$id";
    final uri = Uri.parse(url);
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      final filtered = items.where((element) => element['_id'] != id).toList();
      setState(() {
        items = filtered;
        showSucesssMessage('Deleted');
      });
    } else{
      showErrorsMessage('Deletion Failed');
    }

  }
  void showSucesssMessage(String message){
    final snackbar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
  void showErrorsMessage(String message){
    final snackbar = SnackBar(content: Text(message),backgroundColor: Colors.red,);
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  Future <void> updatedData(id, title, description, isSynced) async {

    final body = {
      "title": title,
      "description": description,
      "is_completed": false
    };

    final url = "https://api.nstack.in/v1/todos/$id";
    final uri = Uri.parse(url);
    final response = await http.put(uri,
        body: jsonEncode(body),
        headers: {'Content-Type' : 'application/json'}
    );
    if (response.statusCode == 200){
      showSuccessMessage('Update Success');
    }
    else{
      showErrorMessage('Update failed');
      print(response.body);
    }
  }

  Future<void> fetchData()async{
    final url = "https://api.nstack.in/v1/todos?page=1&limit=10";
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if(response.statusCode ==200){
      final json = jsonDecode(response.body) as Map;
      final result = json['items'];
      setState(() {
        items = result;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }
  showDialogBox() => showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text('No Internet Connection'),
          content: Text('Plese Check Your Internet Connection'),
          actions: [
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    isAlertSet = true;
                  });
                },
                child: Text('OK'))
          ],
        ),
      );
}
