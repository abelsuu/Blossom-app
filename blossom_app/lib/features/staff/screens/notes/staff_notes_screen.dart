import 'package:flutter/material.dart';
import 'package:blossom_app/features/staff/services/staff_service.dart';
import 'package:blossom_app/common/widgets/text_input_dialog.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffNotesScreen extends StatefulWidget {
  final bool isTab;
  const StaffNotesScreen({super.key, this.isTab = false});

  @override
  State<StaffNotesScreen> createState() => _StaffNotesScreenState();
}

class _StaffNotesScreenState extends State<StaffNotesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- CLIENT NOTES ACTIONS ---

  void _showEditClientNoteDialog(
    String bookingId,
    String noteId,
    String currentContent,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => TextInputDialog(
        title: 'Edit Client Note',
        initialValue: currentContent,
        hintText: 'Enter note here...',
        confirmText: 'Save',
        onConfirm: (text) async {
          await StaffService.updateBookingNote(bookingId, noteId, text);
        },
      ),
    );
  }

  void _deleteClientNote(String bookingId, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StaffService.deleteBookingNote(bookingId, noteId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- PERSONAL NOTES ACTIONS ---

  void _showAddPersonalNoteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => TextInputDialog(
        title: 'New Personal Note',
        hintText: 'Enter your personal note...',
        confirmText: 'Add',
        onConfirm: (text) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await StaffService.addPersonalNote(user.uid, text);
          }
        },
      ),
    );
  }

  void _showEditPersonalNoteDialog(String noteId, String currentContent) {
    showDialog(
      context: context,
      builder: (dialogContext) => TextInputDialog(
        title: 'Edit Personal Note',
        initialValue: currentContent,
        hintText: 'Enter note here...',
        confirmText: 'Save',
        onConfirm: (text) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await StaffService.updatePersonalNote(user.uid, noteId, text);
          }
        },
      ),
    );
  }

  void _deletePersonalNote(String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Personal Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.pop(context);
                await StaffService.deletePersonalNote(user.uid, noteId);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Beige background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
        title: const Text(
          'Notes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Client Notes'),
            Tab(text: 'Personal Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildClientNotesTab(), _buildPersonalNotesTab()],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showAddPersonalNoteDialog,
              backgroundColor: const Color(0xFFD4AF37), // Gold
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildClientNotesTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Notes by Customer Name',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Notes List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: StaffService.getAllNotesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading notes'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allNotes = snapshot.data ?? [];
              final filteredNotes = allNotes.where((note) {
                final customerName = (note['customerName'] ?? '')
                    .toString()
                    .toLowerCase();
                return customerName.contains(_searchQuery);
              }).toList();

              if (filteredNotes.isEmpty) {
                return const Center(
                  child: Text(
                    'No client notes found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: filteredNotes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  return _buildClientNoteCard(note);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientNoteCard(Map<String, dynamic> note) {
    final customerName = note['customerName'] ?? 'Unknown Customer';
    final content = note['content'] ?? '';
    final timestamp = note['timestamp'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    final bookingId = note['bookingId'];
    final noteId = note['id'];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () =>
                        _showEditClientNoteDialog(bookingId, noteId, content),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteClientNote(bookingId, noteId),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalNotesTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view personal notes'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: StaffService.getPersonalNotesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading notes'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return const Center(
            child: Text(
              'No personal notes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: notes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final note = notes[index];
            return _buildPersonalNoteCard(note);
          },
        );
      },
    );
  }

  Widget _buildPersonalNoteCard(Map<String, dynamic> note) {
    final content = note['content'] ?? '';
    final timestamp = note['timestamp'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    final noteId = note['id'];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7), // Light Yellowish for distinction
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1.5,
        ), // Gold border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37), // Gold color title
                  fontStyle: FontStyle.italic,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () =>
                        _showEditPersonalNoteDialog(noteId, content),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deletePersonalNote(noteId),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
