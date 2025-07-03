import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tajiri_ai/features/advisor_chat/viewmodel/advisor_chat_viewmodel.dart';
import 'package:tajiri_ai/core/models/message_model.dart';

class AdvisoryPage extends StatelessWidget {
  final User user;
  const AdvisoryPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Provide the ViewModel here, where we have access to the user's ID.
    // This ensures the ViewModel is correctly initialized with the user's data.
    return ChangeNotifierProvider(
      create: (_) => AdvisorChatViewModel(userId: user.uid),
      child: const AdvisorChatBody(),
    );
  }
}

class AdvisorChatBody extends StatefulWidget {
  const AdvisorChatBody({super.key});

  @override
  State<AdvisorChatBody> createState() => _AdvisorChatBodyState();
}

class _AdvisorChatBodyState extends State<AdvisorChatBody> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    // The sendMessage method now handles all Firestore writes.
    context.read<AdvisorChatViewModel>().sendMessage(_textController.text);
    _textController.clear();
    FocusScope.of(context).unfocus();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // Use a StreamBuilder to listen to the real-time chat history.
          child: StreamBuilder<List<Message>>(
            stream: context.watch<AdvisorChatViewModel>().messagesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print(snapshot.error);
                return const Center(child: Text("Error loading chat history."));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return Center(
                   child: Text(
                     "Ask Tajiri anything to start the conversation!",
                     style: GoogleFonts.poppins(color: Colors.grey),
                   ),
                 );
              }

              final messages = snapshot.data!;
              _scrollToBottom(); // Scroll to the latest message.

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: messages[index]);
                },
              );
            },
          ),
        ),
        // This consumer ensures the typing indicator only shows when loading.
        Consumer<AdvisorChatViewModel>(
            builder: (context, viewModel, child) {
                return viewModel.isLoading ? const TypingIndicator() : const SizedBox.shrink();
            }
        ),
        _buildTextInputArea(),
      ],
    );
  }

  Widget _buildTextInputArea() {
    final viewModel = context.watch<AdvisorChatViewModel>();
    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Theme.of(context).cardColor,
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: "Ask a question or log a transaction...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  ),
                  onSubmitted: viewModel.isLoading ? null : (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: viewModel.isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isUser ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(5),
            bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.poppins(color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 5,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Theme.of(context).primaryColor)),
            const SizedBox(width: 12),
            Text("Tajiri is thinking...",
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}