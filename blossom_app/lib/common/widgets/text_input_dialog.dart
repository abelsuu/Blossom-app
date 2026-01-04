import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String hintText;
  final String confirmText;
  final String cancelText;
  final Future<void> Function(String) onConfirm;
  final VoidCallback? onCancel;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.onConfirm,
    this.initialValue,
    this.hintText = 'Enter text...',
    this.confirmText = 'Save',
    this.cancelText = 'Cancel',
    this.onCancel,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
        enabled: !_isLoading,
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onCancel?.call();
                },
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_controller.text.trim().isNotEmpty) {
                    setState(() => _isLoading = true);
                    try {
                      await widget.onConfirm(_controller.text.trim());
                      if (!mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.confirmText),
        ),
      ],
    );
  }
}
