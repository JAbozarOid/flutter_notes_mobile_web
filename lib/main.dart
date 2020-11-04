import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notes/code/config.dart';
import 'package:flutter_notes/data/hiveDB.dart';
import 'package:flutter_notes/screens/add_note.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  if (!kIsWeb) {
    await Hive
        .initFlutter(); //waits to initialize path on flutter with the default path
  }
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(NoteTypeAdapter());
  Hive.registerAdapter(CheckListNoteAdapter());
  Hive.registerAdapter(TextNoteAdapter());
  await Hive.openBox<Note>(
      notesBox); //if it's the first time running, it will also create the "Box", else it will just open
  await Hive.openBox<TextNote>(
      textNotesBox); //this box will be used later for the Text Type entries
  await Hive.openBox<CheckListNote>(checkListNotesBox);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Notes App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text(appName),
          ),
          body: getNotes(),
          floatingActionButton: addNoteButton(),
        ));
  }

  addNoteButton() {
    return Builder(
      builder: (context) {
        return FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => AddNote()));
          },
        );
      },
    );
  }

  getNotes() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(notesBox).listenable(),
      builder: (context, Box<Note> box, _) {
        if (box.values.isEmpty) {
          return Center(
            child: Text("No Notes!"),
          );
        }
        List<Note> notes = getNotesList(); //get notes from box function
        return ReorderableListView(
            onReorder: (oldIndex, newIdenx) async {
              await reorderNotes(oldIndex, newIdenx, notes);
            },
            children: <Widget>[
              for (Note note in notes) ...[
                getNoteInfo(note),
              ],
            ]);
      },
    );
  }

  reorderNotes(oldIndex, newIdenx, notes) async {
    Box<Note> hiveBox = Hive.box<Note>(notesBox);
    if (oldIndex < newIdenx) {
      notes[oldIndex].position = newIdenx - 1;
      await hiveBox.put(notes[oldIndex].key, notes[oldIndex]);
      for (int i = oldIndex + 1; i < newIdenx; i++) {
        notes[i].position = notes[i].position - 1;
        await hiveBox.put(notes[i].key, notes[i]);
      }
    } else {
      notes[oldIndex].position = newIdenx;
      await hiveBox.put(notes[oldIndex].key, notes[oldIndex]);
      for (int i = newIdenx; i < oldIndex; i++) {
        notes[i].position = notes[i].position + 1;
        await hiveBox.put(notes[i].key, notes[i]);
      }
    }
  }

  getNotesList() {
    //get notes as a List
    List<Note> notes = Hive.box<Note>(notesBox).values.toList();
    notes = getNotesSortedByOrder(notes);
    return notes;
  }

  getNotesSortedByOrder(List<Note> notes) {
    //ordering note list by position
    notes.sort((a, b) {
      var aposition = a.position;
      var bposition = b.position;
      return aposition.compareTo(bposition);
    });
    return notes;
  }

  getNoteInfo(Note note) {
    return ListTile(
      dense: true,
      key: Key(note.key.toString()),
      title: Text(note.title),
    );
  }
}
