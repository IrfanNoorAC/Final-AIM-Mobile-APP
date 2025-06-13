import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:aimapp/home_page.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> otherUser;
  final String service;
  final String date;
  final String time;
  final String location;
  final bool isRequestingHelp;
  final int userId;
  final String requestType; 

  const ChatPage({
    required this.otherUser,
    required this.service,
    required this.date,
    required this.time,
    required this.location,
    required this.isRequestingHelp,
    required this.userId,
    required this.requestType,
    Key? key,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _requestConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkExistingRequest();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      // For scheduled requests, only load messages if request is accepted
      if (widget.requestType == 'scheduled') {
        final requests = await DatabaseHelper().getRequestsForUser(widget.userId);
        final existingRequest = requests.firstWhere(
          (req) => 
            (widget.isRequestingHelp && req['helperId'] == widget.otherUser['id']) ||
            (!widget.isRequestingHelp && req['requesterId'] == widget.otherUser['id']),
          orElse: () => {},
        );
        
        if (existingRequest.isEmpty || existingRequest['status'] != 'accepted') {
          setState(() {
            _messages = [];
            _isLoading = false;
          });
          return;
        }
      }

      final messages = await DatabaseHelper().getMessagesBetweenUsers(
        widget.userId,
        widget.otherUser['id'],
      );
      setState(() {
        _messages = messages.map((msg) => ({
              ...msg,
              'isMe': msg['senderId'] == widget.userId,
              'time': DateTime.parse(msg['timestamp']),
            })).toList();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkExistingRequest() async {
    final requests = await DatabaseHelper().getRequestsForUser(widget.userId);
    final existingRequest = requests.firstWhere(
      (req) => 
        (widget.isRequestingHelp && req['helperId'] == widget.otherUser['id']) ||
        (!widget.isRequestingHelp && req['requesterId'] == widget.otherUser['id']),
      orElse: () => {},
    );
    if (existingRequest.isNotEmpty) {
      setState(() => _requestConfirmed = true);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    // For scheduled requests, only allow messaging if request is accepted
    if (widget.requestType == 'scheduled' && !_requestConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the request first')),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await DatabaseHelper().sendMessage(
        senderId: widget.userId,
        receiverId: widget.otherUser['id'],
        text: messageText,
      );

      setState(() {
        _messages.add({
          'text': messageText,
          'time': DateTime.now(),
          'isMe': true,
        });
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      // Restore message if failed
      _messageController.text = messageText; 
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser['username']),
            Text(
              widget.isRequestingHelp ? 'Requesting Help' : 'Offering Help',
              style: const TextStyle(fontSize: 12),
            ),
            if (widget.requestType == 'scheduled')
              Text(
                'Scheduled Request',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Service details banner
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.service} on ${widget.date} at ${widget.time} (${widget.location})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // For scheduled requests that are not accepted yet, show information message
          if (widget.requestType == 'scheduled' && !_requestConfirmed)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isRequestingHelp
                          ? 'Your request is pending acceptance'
                          : 'Please accept this request to start chatting',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Message input, disable if scheduled request not accepted
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: widget.requestType == 'immediate' || _requestConfirmed,
                    decoration: InputDecoration(
                      hintText: widget.requestType == 'scheduled' && !_requestConfirmed
                          ? 'Accept request to chat'
                          : 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: (widget.requestType == 'scheduled' && !_requestConfirmed)
                      ? null
                      : _sendMessage,
                ),
              ],
            ),
          ),
          
          // Action buttons (only show if request not confirmed)
          if (!_requestConfirmed) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment: message['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message['isMe'] ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message['text']),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message['time']),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 20),
            label: Text(widget.isRequestingHelp 
                ? widget.requestType == 'immediate' ? 'Confirm Request' : 'Post Request'
                : widget.requestType == 'immediate' ? 'Confirm Offer' : 'Accept Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => _confirmRequest(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => _rejectRequest(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRequest() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper().insertRequest(
        service: widget.service,
        date: widget.date,
        time: widget.time,
        location: widget.location,
        requestType: widget.requestType,
        helperId: widget.isRequestingHelp ? widget.otherUser['id'] : widget.userId,
        requesterId: widget.isRequestingHelp ? widget.userId : widget.otherUser['id'],
      );

      // For scheduled requests, mark as accepted if helper is confirming
      if (widget.requestType == 'scheduled' && !widget.isRequestingHelp) {
        final requests = await DatabaseHelper().getRequestsForUser(widget.userId);
        final request = requests.firstWhere(
          (req) => req['requesterId'] == widget.otherUser['id'],
        );
        await DatabaseHelper().acceptScheduledRequest(request['id'], widget.userId);
      }

      // Send confirmation message
      final confirmationMessage = widget.isRequestingHelp
          ? "Thank you for your help for ${widget.service} on ${widget.date}"
          : "I've confirmed my offer to help with ${widget.service} on ${widget.date}";
      
      await DatabaseHelper().sendMessage(
        senderId: widget.userId,
        receiverId: widget.otherUser['id'],
        text: confirmationMessage,
      );

      setState(() {
        _requestConfirmed = true;
        _messages.add({
          'text': confirmationMessage,
          'time': DateTime.now(),
          'isMe': true,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isRequestingHelp
              ? 'Help request confirmed!'
              : 'Help offer confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
      _scrollToBottom();
     
      // Modified navigation to ensure we go back to home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(userId: widget.userId),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest() async {
    setState(() => _isLoading = true);
    try {
      // Send rejection message
      final rejectionMessage = widget.isRequestingHelp
          ? "I've decided not to proceed for ${widget.service}"
          : "I won't be able to help with ${widget.service}";
      
      await DatabaseHelper().sendMessage(
        senderId: widget.userId,
        receiverId: widget.otherUser['id'],
        text: rejectionMessage,
      );

      // Just go back to the previous screen (which should be the available helpers list)
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}