import 'package:scientisst_db/scientisst_db.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Example(),
    );
  }
}

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  void initState() {
    super.initState();
    generateDB();
  }

  void generateDB() async {
    await ScientISSTdb.instance!.collection("movies").add(
      {
        "title": "Eternal Sunshine of the Spotless Mind",
        "year": 2004,
        "characters": [
          "Joel",
          "Clementine",
        ],
      },
    );

    DocumentReference inception =
        await ScientISSTdb.instance!.collection("movies").add(
      {
        "title": "Inception",
        "year": 2010,
        "characters": [
          "Cobb",
          "Arthur",
          "Ariadne",
        ],
      },
    );
    await ScientISSTdb.instance!
        .collection("movies")
        .document(inception.id)
        .collection("actors")
        .add(
      {
        "name": "Leonardo DiCaprio",
        "birthdate": DateTime(1974, 10, 11),
      },
    );
    await ScientISSTdb.instance!
        .collection("movies")
        .document(inception.id)
        .collection("actors")
        .add(
      {
        "name": "Joseph Gordon-Levitt",
        "birthdate": DateTime(1981, 2, 17),
      },
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Movies"),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: ScientISSTdb.instance!
              .collection("movies")
              .orderBy("year", descending: false)
              .getDocuments(),
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snap) {
            if (snap.hasError || snap.data == null)
              return Container();
            else
              return ListView.builder(
                itemCount: snap.data!.length,
                itemBuilder: (BuildContext context, int index) => ListTile(
                  title: Text(
                    snap.data![index].data["title"],
                  ),
                  subtitle: Text(
                    snap.data![index].data["year"].toString(),
                  ),
                ),
              );
          },
        ),
      ),
    );
  }
}
