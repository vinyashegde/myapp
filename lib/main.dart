import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'todo_screen.dart';
import 'kanban_screen.dart';
import 'music_screen.dart';
import 'setting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp()); // Removed const keyword
}

class MyApp extends StatelessWidget {
  // Define an instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already signed in
    User? user = _auth.currentUser; // Check current user

    return MaterialApp(
      title: 'Flutter Firebase App',
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black54),
        ),
      ),
      home: user != null
          ? Dashboard(user: user) // Directly go to Dashboard if signed in
          : SignInScreen(), // Otherwise, show SignInScreen
      routes: {
        '/signin': (context) => SignInScreen(), // SignInScreen route
      },
    );
  }
}

class SignInScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  SignInScreen({super.key});

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // Sign out the current user to ensure account selection
      await _googleSignIn.signOut();

      // Prompt user to select an account each time
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in process
        return null;
      }

      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Flutter Firebase App'),
        backgroundColor: Colors.blueAccent,
        elevation: 2.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign in to Continue',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: Icon(Icons.login, color: Colors.white),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  User? user = await signInWithGoogle(context);
                  if (user != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Dashboard(user: user)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Sign-in failed. Please try again.")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final User user;

  const Dashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 2.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Align items to start
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL ?? ''),
                      radius: 30.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      // Wrap this Column in Expanded
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user.displayName}',
                            style: TextStyle(
                                fontSize: 20.0, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                children: [
                  _buildDashboardButton(
                    context,
                    title: 'To-Do List',
                    icon: Icons.list,
                    color: Colors.greenAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TodoScreen(user: user)),
                      );
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    title: 'Kanban Board',
                    icon: Icons.view_kanban,
                    color: Colors.orangeAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                KanbanScreen(userId: user.uid)),
                      );
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    title: 'Lo-Fi Music',
                    icon: Icons.music_note,
                    color: Colors.purpleAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MusicScreen()),
                      );
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    title: 'Settings',
                    icon: Icons.settings,
                    color: Colors.blueGrey,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.all(16.0),
        elevation: 3.0,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40.0, color: Colors.white),
          const SizedBox(height: 10.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
