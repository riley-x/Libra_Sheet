import 'package:flutter/material.dart';
import 'package:libra_sheet/data/database/libra_database.dart';

class DatabaseScreen extends StatelessWidget {
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("All the data in the app is saved to the following file:"),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SelectableText(
                LibraDatabase.db.path,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Text(
              "The app will also periodically make backups in the same folder. If you ever need to"
              " restore a backup, simply replace the file above. I recommend also saving a backup to the"
              " cloud."),
        ],
      ),
    );
  }
}
