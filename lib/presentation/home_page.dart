import 'package:flutter/material.dart';

import '../data/task_api.dart';
import 'process_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});
  final TaskApi api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.api.savedUrl ?? 'https://flutter.webspark.dev/flutter/api',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await widget.api.saveUrl(_urlController.text);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ProcessPage(api: widget.api),
      ));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Shortest Path')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          const Icon(Icons.alt_route, size: 64),
                          const SizedBox(height: 20),
                          Text('Знайдіть найкоротший шлях',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          const Text(
                            'Введіть URL API. Застосунок отримає завдання, '
                            'розрахує маршрути та надішле їх на перевірку.',
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              key: const Key('api-url'),
                              controller: _urlController,
                              enabled: !_starting,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.go,
                              autocorrect: false,
                              enableSuggestions: false,
                              onFieldSubmitted: (_) => _start(),
                              decoration: const InputDecoration(
                                labelText: 'API URL',
                                hintText: 'https://example.com/api?key=value',
                                helperText: 'Підтримуються GET-параметри в URL',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.link),
                              ),
                              validator: (value) {
                                final uri = Uri.tryParse((value ?? '').trim());
                                if (uri == null ||
                                    !{'http', 'https'}.contains(uri.scheme) ||
                                    uri.host.isEmpty) {
                                  return 'Введіть коректний HTTP або HTTPS URL';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _starting ? null : _start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
