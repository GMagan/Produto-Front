import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:core';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estoque',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 0, 0)),
        scaffoldBackgroundColor: Color.fromARGB(0, 29, 26, 26),
      ),
      home: const Dashboard(title: 'Catalogo de produtos'),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.title});

  final String title;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List items = [];
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    fetchProdutos();
  }

  Future<void> fetchProdutos() async {
    final apiUrl = Uri.parse('http://localhost:3000/produtos');
    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        setState(() {
          items = json.decode(response.body);
          isLoadingData = false;
        });
      } else {
        throw Exception('Falha ao carregar produtos');
      }
    } catch (e) {
      print('Erro: $e');
      setState(() {
        isLoadingData = false;
      });
    }
  }

  void navigateToprodutosCreation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const produtosCreationPage()),
    ).then((_) => fetchProdutos());
  }

  void navigateToprodutosDetails(BuildContext context, Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => produtosDetailPage(item: item)),
    ).then((_) => fetchProdutos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 152, 0, 198),
        title: Text(widget.title),
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['descricao'] ?? 'No description'),
                      subtitle: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preço: ${item['preco'] ?? 'N/A'}     '),
                          Text('Estoque: ${item['estoque'] ?? 'N/A'}     '),
                          Text('Data: ${item['data'] ?? 'N/A'}     '),
                        ],
                      ),
                      onTap: () => navigateToprodutosDetails(context, item),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToprodutosCreation(context),
        tooltip: 'Add produtos',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class produtosDetailPage extends StatefulWidget {
  final Map item;

  const produtosDetailPage({super.key, required this.item});

  @override
  State<produtosDetailPage> createState() => _produtosDetailPageState();
}

class _produtosDetailPageState extends State<produtosDetailPage> {
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController stockController;

  @override
  void initState() {
    super.initState();
    descriptionController =
        TextEditingController(text: widget.item['descricao']);
    priceController =
        TextEditingController(text: widget.item['preco'].toString());
    priceController.text = priceController.text.replaceAll('\$', '');
    stockController =
        TextEditingController(text: widget.item['estoque'].toString());
  }

  Future<void> updateItem() async {
    final apiUrl =
        Uri.parse('http://localhost:3000/produtos/${widget.item['id']}');
    final response = await http.put(
      apiUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'descricao': descriptionController.text,
        'preco': double.parse(priceController.text),
        'estoque': int.parse(stockController.text),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto atualizado')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao atualizar')),
      );
    }
  }

  Future<void> deleteItem() async {
    final apiUrl =
        Uri.parse('http://localhost:3000/produtos/${widget.item['id']}');
    final response = await http.delete(apiUrl);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto deletado')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao deletar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descricao'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preco'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estoque'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: updateItem,
                  child: const Text('Salvar'),
                ),
                ElevatedButton(
                  onPressed: deleteItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red
                  ),
                  child: const Text('Deletar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class produtosCreationPage extends StatefulWidget {
  const produtosCreationPage({super.key});

  @override
  State<produtosCreationPage> createState() => _produtosCreationPageState();
}

class _produtosCreationPageState extends State<produtosCreationPage> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  Future<void> createItem(
      String description, String price, String stock, String date) async {
    final apiUrl = Uri.parse('http://localhost:3000/produtos');
    final response = await http.post(
      apiUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'descricao': description,
        'preco': double.parse(price),
        'estoque': int.parse(stock),
        'data': date,
      }),
    );

    if (response.statusCode == 201) {
      print('Produto criado');
    } else {
      print('Erro ao criar: ${response.statusCode}');
    }
  }

  Future<void> pickDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      final formattedDate = DateFormat('MM/dd/yyyy').format(selectedDate);
      dateController.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descricao'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preco'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estoque'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Data'),
              onTap: () => pickDate(context),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  createItem(
                    descriptionController.text,
                    priceController.text,
                    stockController.text,
                    dateController.text,
                  ).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('produto criado')),
                    );
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao criar produto')),
                    );
                  });
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
