import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contact.dart';
import 'add_contact_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  /// Firestore path: users/{uid}/contacts — each user has their own contacts.
  static CollectionReference<Map<String, dynamic>> _contactsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('contacts');
  }

  /// Ensures users/{uid} exists so the contacts subcollection can be used.
  static Future<void> _ensureUserCollection(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'uid': uid}, SetOptions(merge: true));
  }

  Future<void> _addContact(BuildContext context, String uid) async {
    final contact = await AddContactScreen.show(context);
    if (contact == null || !context.mounted) return;
    await _ensureUserCollection(uid);
    await _contactsRef(uid).add(contact.toMap());
  }

  Future<void> _editContact(BuildContext context, String uid, Contact contact) async {
    final updated = await AddContactScreen.show(context, contact: contact);
    if (updated == null || !context.mounted) return;
    await _contactsRef(uid).doc(contact.id).update({
      'name': updated.name,
      'phone': updated.phone,
      'email': updated.email,
    });
  }

  Future<void> _deleteContact(BuildContext context, String uid, Contact contact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove "${contact.name}" from your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _contactsRef(uid).doc(contact.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final uid = user.uid;
    final email = user.email ?? '';
    final displayName = user.displayName ?? '';
    final photoUrl = user.photoURL;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 24),
            onPressed: _signOut,
            tooltip: 'Sign out',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Icon(Icons.person_rounded, size: 32, color: colorScheme.onPrimaryContainer)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty ? displayName : 'Google account',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email.isNotEmpty ? email : 'Not signed in',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.mail_outline_rounded, size: 24, color: colorScheme.onSurfaceVariant),
                title: const Text('Email'),
                subtitle: email.isNotEmpty ? Text(email, style: const TextStyle(fontSize: 13)) : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              if (displayName.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.badge_outlined, size: 24, color: colorScheme.onSurfaceVariant),
                  title: const Text('Name'),
                  subtitle: Text(displayName, style: const TextStyle(fontSize: 13)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout_rounded, size: 24, color: colorScheme.error),
                title: Text('Sign out', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w500)),
                onTap: _signOut,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _contactsRef(uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          final contacts = docs
              .map((d) => Contact.fromMap(d.data(), d.id))
              .toList();

          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.contacts_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No contacts yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first contact',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final c = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(c.name),
                subtitle: [
                  if (c.phone.isNotEmpty) c.phone,
                  if (c.email.isNotEmpty) c.email,
                ].isNotEmpty
                    ? Text([if (c.phone.isNotEmpty) c.phone, if (c.email.isNotEmpty) c.email].join(' · '))
                    : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editContact(context, uid, c);
                    } else if (value == 'delete') {
                      _deleteContact(context, uid, c);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Delete')])),
                  ],
                ),
                onTap: () => _editContact(context, uid, c),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addContact(context, uid),
        tooltip: 'Add contact',
        child: const Icon(Icons.add),
      ),
    );
  }
}
