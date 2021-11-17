//import 'dart:html';

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'authentication.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}
class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
            body: Center(
                child: Text(snapshot.error.toString(),
                    textDirection: TextDirection.ltr)));
      }
      if (snapshot.connectionState == ConnectionState.done) {
        return ChangeNotifierProvider(create: (_)=>AuthRepository.instance(),
            child: MyApp()
        );
      }
      return Center(child: CircularProgressIndicator());
        },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: RandomWords(),
    );
  }
}


class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final  _emailController=TextEditingController();
  final  _passwordController=TextEditingController();
  final  _passwordValidationController=TextEditingController();
  final  _sheetController=SnappingSheetController();
  bool passwordsMatch=true;
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);
 // final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
            icon: Icon(Provider.of<AuthRepository>(context,listen:true).isAuthenticated ? Icons.exit_to_app : Icons.login),
            onPressed: Provider.of<AuthRepository>(context,listen:true).isAuthenticated ? _logout : _loginRoute,
            tooltip: 'Login',
          ),
        ],
      ),
      body: Provider.of<AuthRepository>(context,listen:true).isAuthenticated
          ?
      SnappingSheet(
        controller: _sheetController,
          child:  _buildSuggestions(),
          grabbingHeight: 50,
          grabbing: Container(color: Colors.grey,
                        child: ListTile(
                            title: Text("Welcome Back, " + Provider.of<AuthRepository>(context,listen: true).user!.email!,
                                    style: TextStyle(fontSize: 17),
                            ),
                            trailing: Icon(Icons.keyboard_arrow_up),
                          onTap: () => setState(() {
                            if(_sheetController.currentPosition==25.0){
                              _sheetController.setSnappingSheetPosition(150.0);
                            }else{
                              _sheetController.setSnappingSheetPosition(25.0);
                            }
                          }),
                        ),
          ),
          sheetBelow: SnappingSheetContent(
              child:Container(color: Colors.white,
                      child: Card(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: Provider.of<AuthRepository>(context,listen: true).current_image_url==null
                                  ? DecorationImage(image : AssetImage('images/no_photo.png'))
                                  : DecorationImage(image:NetworkImage(Provider.of<AuthRepository>(context,listen: true).current_image_url))
                                  ),
                                ),
                              ),
                            Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text.rich(TextSpan(
                                    text: Provider.of<AuthRepository>(context,listen: true).user!.email,
                                    style: TextStyle(
                                      fontSize: 22,
                                    ),
                                  )),
                                ),
                                   SizedBox(
                                    height: 35,
                                    width: 130,
                                    child: ElevatedButton(
                                      child: const Text('Change avatar'),
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.lightBlue,
                                        onPrimary: Colors.white,
                                      ),
                                      onPressed: ()async{
                                        FilePickerResult? result = await FilePicker.platform.pickFiles();
                                        if (result == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No image selected"),duration: Duration(seconds: 2)));
                                        }else{
                                          Provider.of<AuthRepository>(context,listen: false).
                                          update_image_url(Provider.of<AuthRepository>(context,listen: false).user!.email,
                                              result.files.single.path!
                                          );
                                        }
                                      },
                                    ),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
              )
          ),
      ):_buildSuggestions(),
    );
  }

  void _logout()async{
     await Provider.of<AuthRepository>(context,listen:false).signOut();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully logged out"),duration: Duration(seconds: 2)));
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = Provider.of<AuthRepository>(context,listen: false).saved.map(
                (pair) {
                  return Dismissible(
                    confirmDismiss: (DismissDirection direction)async{
                      return showDialog(context: context, builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Delete Suggestion"),
                          content: Text("Are you sure you want to delete "+pair+" from your saved sugggestions?"),
                          actions: [
                            FlatButton(
                              child: Text("Yes",),
                              color: Colors.deepPurple,
                              textColor: Colors.white,
                              onPressed: (){
                                Provider.of<AuthRepository>(context,listen: false).removePair(pair);
                                Navigator.of(context).pop(true);

                              },
                            ),
                            FlatButton(
                              child: Text("No"),
                              color:Colors.deepPurple,
                              textColor: Colors.white,
                              onPressed: (){
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      });
                    },
                    key: ValueKey(pair),
                    background: Container(padding: EdgeInsets.only(left: 20.0),
                      alignment: Alignment.centerLeft,
                      color: Colors.deepPurple,
                      child: Row(children: [Icon(Icons.delete,color: Colors.white),Text('Delete Suggestion',style: TextStyle(color: Colors.white,fontSize: 18))]),
                      )
                    ,child: ListTile(
                      title: Text(
                        pair,
                        style: _biggerFont,
                      ),
                    ),
                  );
                }
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  void _loginRoute() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Login'),
              centerTitle: true,
            ),
            body: Column(
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.all(25.0),
                    child: (Text('Welcome to Startup Names Generator, please log in below',
                      style:TextStyle(
                        fontSize: 14,
                      ),
                    ))
                ),
                const SizedBox(height: 10),
                 TextField(
                  controller: _emailController,
                  obscureText: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
                 TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height:10),
                Provider.of<AuthRepository>(context,listen: true).status==Status.Authenticating ?
                  Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        backgroundColor: Colors.deepPurple,
                        strokeWidth: 2,
                      ))
                :
                SizedBox(
                  width: 360,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.deepPurple,
                      onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0))
                    ),
                    onPressed:()async{
                      if(await Provider.of<AuthRepository>(context,listen: false).signIn(_emailController.text,_passwordController.text)){
                  //      _emailController.text='';
                  //      _passwordController.text='';
                        Provider.of<AuthRepository>(context,listen: false).updatePairsAfterLoggingIn();
                        Navigator.of(context).pop();
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was an error logging into the app"),duration: Duration(seconds: 2)));
                      }
                    },
                    child: const Text(
                        'Log in',
                    ),
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: Colors.lightBlue,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0))
                    ),
                    onPressed:()async{
                      setState(() {
                        passwordsMatch=true;
                      });
                      return showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                           return StatefulBuilder( builder:(BuildContext context,setState)=>
                               Container(
                                  color: Colors.white,
                                  padding: MediaQuery.of(context).viewInsets,
                                   child: Column(mainAxisSize: MainAxisSize.min,
                                     children: <Widget>[
                                       ListTile(
                                         title: Center(
                                             child: Text('Please confirm your password below:')),
                                       ),
                                       Padding(
                                         padding: const EdgeInsets.all(16.0),
                                         child: TextFormField(
                                             obscureText: true,
                                             controller: _passwordValidationController,
                                             decoration: InputDecoration(
                                               errorText: passwordsMatch ? null : "Passwords must match",
                                               labelText: "Password",
                                             )),
                                       ),
                                       SizedBox(
                                         height: 55,
                                         width: 120,
                                         child: Container(
                                           margin: const EdgeInsets.only(
                                               bottom: 16.0),
                                           child: ElevatedButton(
                                               child: const Text('Confirm'),
                                               style: ElevatedButton.styleFrom(
                                                 primary: Colors.lightBlue,
                                                 onPrimary: Colors.white,
                                               ),
                                               onPressed: () async {
                                                 setState(() {
                                                   passwordsMatch = _passwordValidationController.text == _passwordController.text;
                                                 });
                                                 if (passwordsMatch) {
                                                   if (await Provider.of<AuthRepository>(context, listen: false)
                                                       .signUp(_emailController.text, _passwordController.text) != null) {
                                                     Navigator.of(context).pop();
                                                     Navigator.of(context).pop();
                                                   }
                                                 }else{
                                                   _passwordValidationController.text = '';
                                                 }
                                               }
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           )
                           );
                        },
                      );
                    },
                    child: const Text(
                      'New user? Click to sign up',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
         }
          return _buildRow(_suggestions[index].asPascalCase);
        }
    );
  }

  Widget _buildRow(String pair) {
    final alreadySaved = Provider.of<AuthRepository>(context,listen:false).saved.contains(pair);
    return ListTile(
      title: Text(
        pair,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.red : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            Provider.of<AuthRepository>(context,listen: false).removePair(pair);
          } else {
            Provider.of<AuthRepository>(context,listen: false).addPair(pair);
          }
        });
      },
    );
  }

}


