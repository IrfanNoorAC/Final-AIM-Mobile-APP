import 'package:flutter/material.dart';
import 'package:aimapp/community_model.dart';

class CommunityPage extends StatefulWidget {
  final int userId;

  const CommunityPage({required this.userId, Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communities'),automaticallyImplyLeading: false, ),
      body: ListView.builder(
        itemCount: communityList.length,
        itemBuilder: (context, index) {
          final community = communityList[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(community.image),
              ),
              title: Text(community.name),
              subtitle: Text(community.description),
              trailing: Icon(
                community.isMember ? Icons.check_circle : Icons.add_circle,
                color: community.isMember ? Colors.green : Colors.blue,
              ),
              onTap: () {
                // Navigate to community details if needed
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show create community dialog or navigate to next page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}