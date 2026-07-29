import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/static_service.dart';

class StaticContentScreen extends StatefulWidget {
  final String service;

  const StaticContentScreen({super.key, required this.service});

  @override
  State<StaticContentScreen> createState() => _StaticContentScreenState();
}

class _StaticContentScreenState extends State<StaticContentScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await StaticService.getContent(widget.service);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = friendlyError(e, 'This content is not available yet.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_data?['title'] ?? widget.service),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _data?['content'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
    );
  }
}
