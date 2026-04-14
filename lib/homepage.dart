import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final tglTextController = TextEditingController();
  final labelTextController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  void openNoteBox({String? docId, String? existingTitle, String? existingContent, String? existingTgl, String? existingLabel}) async {
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingContent ?? '';
      tglTextController.text = existingTgl ?? '';
      labelTextController.text = existingLabel ?? '';
    } else {
      titleTextController.clear();
      contentTextController.clear();
      tglTextController.clear();
      labelTextController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Create new Note" : "Edit Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Title"),
                controller: titleTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Content"),
                controller: contentTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Tgl"),
                controller: tglTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Label"),
                controller: labelTextController,
              ),
            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                if (docId == null) {
                  firestoreService.addNote(
                    titleTextController.text,
                    contentTextController.text,
                    tglTextController.text,
                    labelTextController.text,
                  );
                } else {
                  firestoreService.updateNote(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    tglTextController.text,
                    labelTextController.text,
                  );
                }
                titleTextController.clear();
                contentTextController.clear();
                tglTextController.clear();
                labelTextController.clear();

                Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Notes"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, 'login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;

            return GridView.builder(
              itemCount: notesList.length,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];
                String docId = document.id;

                Map<String, dynamic> data =
                document.data() as Map<String, dynamic>;
                String noteTitle = data['title'];
                String noteContent = data['content'];
                String noteTgl = data['tgl'] ?? '';
                String noteLabel = data['label'] ?? '';

                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  noteTitle,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.fade,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  noteContent,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  noteTgl,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  noteLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                openNoteBox(
                                  docId: docId,
                                  existingContent: noteContent,
                                  existingTitle: noteTitle,
                                  existingTgl: noteTgl,
                                  existingLabel: noteLabel,
                                );
                              },
                              icon: const Icon(Icons.edit, size: 20),
                            ),
                            IconButton(
                              onPressed: () {
                                firestoreService.deleteNote(docId);
                              },
                              icon: const Icon(Icons.delete, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text("No data"),
            );
          }
        },
      ),
    );
  }
}