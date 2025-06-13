import 'package:aimapp/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/request_help_page.dart';
import 'package:aimapp/offer_help_page.dart';
import 'package:aimapp/settings_page.dart';
import 'package:aimapp/community_page.dart'; 

class HomePage extends StatefulWidget {
  final int userId;

  const HomePage({required this.userId, Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late Future<Map<String, dynamic>?> _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _userData = DatabaseHelper().getUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading user data'),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final user = snapshot.data!;
        final isHelper = user['isHelper'] == 1;
        final canAssistDeaf = user['canAssistDeaf'] == 1;
        final canAssistBlind = user['canAssistBlind'] == 1;
        final canAssistWheelchair = user['canAssistWheelchair'] == 1;
        
        return Scaffold(
  appBar: AppBar(
    title: Text('Welcome, ${user['username']}'),
    automaticallyImplyLeading: false, 
  ),
  body: _buildBody(isHelper, canAssistDeaf, canAssistBlind, canAssistWheelchair),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
     showSelectedLabels: true, 
  showUnselectedLabels: true, 
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.black), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.people, color: Colors.black), label: 'Community'),
      BottomNavigationBarItem(icon: Icon(Icons.person, color: Colors.black), label: 'Profile'),
      BottomNavigationBarItem(icon: Icon(Icons.settings, color: Colors.black), label: 'Settings'),
    ],
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black,
    onTap: (index) => setState(() => _currentIndex = index),
  ),
);
      },
    );
  }

  Widget _buildBody(bool isHelper, bool canAssistDeaf, bool canAssistBlind, bool canAssistWheelchair) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(isHelper, canAssistDeaf, canAssistBlind, canAssistWheelchair);
      case 1:
        return CommunityPage(userId: widget.userId);
      case 2:
        return ProfilePage(userId: widget.userId);
      case 3:
        return SettingsPage(userId: widget.userId);
      default:
        return Container();
    }
  }

  Widget _buildHomeContent(bool isHelper, bool canAssistDeaf, bool canAssistBlind, bool canAssistWheelchair) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (!isHelper)
            Column(
              children: [
                const Text(
                  'Request assistance for your needs',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestHelpPage(userId: widget.userId),
                    ),
                  ),
                  child: const Text('Request Help'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          
          if (canAssistDeaf || canAssistBlind || canAssistWheelchair)
            Column(
              children: [
                const Text(
                  'Offer your assistance to others',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OfferHelpPage(userId: widget.userId),
                    ),
                  ),
                  child: const Text('Offer Help'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper().getRequestsForUser(widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final requests = snapshot.data!;
                if (requests.isEmpty) {
                  return const Center(child: Text('Nothing to see here'));
                }

                // Separate requests by type
                final scheduledRequests = requests.where((r) => r['requestType'] == 'scheduled').toList();
                final immediateRequests = requests.where((r) => r['requestType'] == 'immediate').toList();
                requests.where((r) => r['status'] == 'accepted').toList();

                return ListView(
                  children: [
                    if (scheduledRequests.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Scheduled',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...scheduledRequests.map((request) => _buildRequestCard(context, request)),
                    ],
                    
                    if (immediateRequests.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Immediate',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...immediateRequests.map((request) => _buildRequestCard(context, request)),
                    ],
                    
                    
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    final isRequester = request['requesterId'] == widget.userId;
    final isScheduled = request['requestType'] == 'scheduled';
    final isAccepted = request['status'] == 'accepted';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(request['service']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request['date']} at ${request['time']}'),
            Row(
              children: [
                Text(
                  isRequester ? 'Requesting Help' : 'Offering Help',
                  style: TextStyle(
                    color: isRequester ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                // Only show status badge for scheduled requests
                if (isScheduled) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isAccepted ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAccepted ? 'Accepted' : 'Pending',
                      style: TextStyle(
                        color: isAccepted ? Colors.green[800] : Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Show "Immediate" badge
                if (!isScheduled) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Immediate',
                      style: TextStyle(
                        color: Colors.purple[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show cancel button for all pending or accepted requests regardless of user role
            if (request['status'] != 'completed' && request['status'] != 'cancelled')
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _confirmCancelRequest(context, request['id']),
              ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => _startChat(context, request, isRequester),
            ),
            const Icon(Icons.arrow_forward),
          ],
        ),
        onTap: () => _showRequestDetails(context, request, isRequester),
      ),
    );
  }

  Future<void> _confirmCancelRequest(BuildContext context, int requestId) async {
    final messenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseHelper().cancelRequest(requestId);
      
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      if (mounted) {
        setState(() {
          _loadUserData();
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startChat(BuildContext context, Map<String, dynamic> request, bool isRequester) async {
    final otherUserId = isRequester ? request['helperId'] : request['requesterId'];
    final otherUser = await DatabaseHelper().getUser(otherUserId);

    if (otherUser != null) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'otherUser': otherUser,
          'service': request['service'],
          'date': request['date'],
          'time': request['time'],
          'location': request['location'],
          'isRequestingHelp': isRequester,
          'userId': widget.userId,
          'requestType': request['requestType'],
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load user details')),
      );
    }
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request, bool isRequester) async {
    final otherUserId = isRequester ? request['helperId'] : request['requesterId'];
    final otherUser = await DatabaseHelper().getUser(otherUserId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request['service']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${request['date']}'),
            Text('Time: ${request['time']}'),
            Text('Location: ${request['location']}'),
            const SizedBox(height: 10),
            Text(
              isRequester ? 'You requested this help' : 'You offered to help with this',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRequester ? Colors.blue : Colors.green,
              ),
            ),
            if (request['requestType'] == 'scheduled')
              Text(
                'Type: Scheduled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            if (request['status'] == 'accepted')
              Text(
                'Status: Accepted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            const SizedBox(height: 10),
            if (otherUser != null)
              Text(
                isRequester
                    ? 'Helper: ${otherUser['username']}'
                    : 'Requester: ${otherUser['username']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          // Show cancel button for all non-completed or cancelled requests
          if (request['status'] != 'completed' && request['status'] != 'cancelled')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmCancelRequest(context, request['id']);
              },
              child: const Text('Cancel Request', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startChat(context, request, isRequester);
            },
            child: const Text('Chat'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (request['requestType'] == 'scheduled' && !isRequester && request['status'] != 'accepted')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseHelper().acceptScheduledRequest(request['id'], widget.userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request accepted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadUserData();
              },
              child: const Text('Accept'),
            ),
        ],
      ),
    );
  }
}