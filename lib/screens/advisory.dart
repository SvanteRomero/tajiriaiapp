// lib/screens/advisory.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/features/advisor_chat/viewmodel/advisor_chat_viewmodel.dart';
import '/core/models/message_model.dart';

class AdvisoryPage extends StatelessWidget {
  final User user;
  const AdvisoryPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const AdvisorChatBody();
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
    context.read<AdvisorChatViewModel>().sendMessage(_textController.text);
    _textController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.watch<AdvisorChatViewModel>();
    viewModel.addListener(() {
      if (mounted) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<AdvisorChatViewModel>(
            builder: (context, viewModel, child) {
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: viewModel.messages.length + (viewModel.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (viewModel.isLoading && index == viewModel.messages.length) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: viewModel.messages[index]);
                },
              );
            },
          ),
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
                    hintText: "Ask a question...",
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
          color: isUser ? theme.primaryColor : Colors.white,
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
          style: GoogleFonts.poppins(color: isUser ? Colors.white : Colors.black87),
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
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)),
            const SizedBox(width: 12),
            Text("Tajiri is thinking...", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}