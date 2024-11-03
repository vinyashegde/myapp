import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KanbanScreen extends StatefulWidget {
  final String userId;

  KanbanScreen({required this.userId});

  @override
  _KanbanScreenState createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  late CollectionReference tasks;

  @override
  void initState() {
    super.initState();
    // Reference the tasks collection specific to the logged-in user
    tasks = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kanban Board'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: tasks.orderBy('timestamp').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No tasks found."));
            }

            // Organize tasks into categories
            List<DocumentSnapshot> toDoTasks = [];
            List<DocumentSnapshot> inProgressTasks = [];
            List<DocumentSnapshot> doneTasks = [];

            for (var doc in snapshot.data!.docs) {
              var status = doc['status'] as String;
              if (status == 'To-Do') {
                toDoTasks.add(doc);
              } else if (status == 'In Progress') {
                inProgressTasks.add(doc);
              } else if (status == 'Done') {
                doneTasks.add(doc);
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KanbanColumn(
                      title: 'To-Do',
                      tasks: toDoTasks,
                      onTaskMoved: (task) => moveTask(task, 'To-Do'),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: KanbanColumn(
                      title: 'In Progress',
                      tasks: inProgressTasks,
                      onTaskMoved: (task) => moveTask(task, 'In Progress'),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: KanbanColumn(
                      title: 'Done',
                      tasks: doneTasks,
                      onTaskMoved: (task) => moveTask(task, 'Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void moveTask(DocumentSnapshot task, String newStatus) {
    tasks.doc(task.id).update({'status': newStatus});
  }

  void _showAddTaskDialog() {
    final TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: 'Task description'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  tasks.add({
                    'task': taskController.text,
                    'status': 'To-Do',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<DocumentSnapshot> tasks;
  final Function(DocumentSnapshot) onTaskMoved;

  KanbanColumn({
    required this.title,
    required this.tasks,
    required this.onTaskMoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: DragTarget<DocumentSnapshot>(
              onAccept: (task) {
                onTaskMoved(task);
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return Draggable<DocumentSnapshot>(
                      data: task,
                      feedback: Material(
                        elevation: 6.0,
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              task['task'],
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          color: Colors.blueAccent,
                        ),
                      ),
                      childWhenDragging: Container(),
                      child: Card(
                        margin: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 3.0,
                        child: ListTile(
                          title: Text(
                            task['task'],
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Icon(Icons.more_vert),
                          onTap: () {
                            // Handle task tap
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
