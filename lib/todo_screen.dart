import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodoScreen extends StatefulWidget {
  final User user;

  const TodoScreen({Key? key, required this.user}) : super(key: key);

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  late CollectionReference tasks;

  @override
  void initState() {
    super.initState();
    // Reference tasks collection specific to the logged-in user
    tasks = FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('tasks');
  }

  void _addTask() {
    if (_controller.text.isNotEmpty) {
      tasks.add({
        'task': _controller.text,
        'status': 'To-Do', // Default status
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Task input field
            _buildTaskInput(),
            const SizedBox(height: 16.0),
            // Task list
            Expanded(
              child: StreamBuilder(
                stream: tasks.orderBy('timestamp').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No tasks found.", style: TextStyle(fontSize: 18)));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((task) {
                      return _buildTaskItem(task);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Add Task',
          labelStyle: TextStyle(color: Colors.black54),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _addTask,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildTaskItem(DocumentSnapshot task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      child: ListTile(
        title: Text(
          task['task'],
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => task.reference.delete(),
        ),
      ),
    );
  }
}
