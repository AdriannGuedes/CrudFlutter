import "package:flutter/material.dart";
import "db/database.dart";
import "log_screen.dart";


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allData = [];

  bool _isLoading = true;

  void _refreshData() async {
    final data = await Database.buscarPessoas();
    setState(() {
      _allData = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _addPessoa() async {
    int? cpf = int.tryParse(_cpfController.text) ?? 0;
    await Database.adicionarPessoa(_nomeController.text, cpf);
    _refreshData();
  }

  Future<void> _editarPessoa(int id) async {
    int? cpf = int.tryParse(_cpfController.text) ?? 0;
    await Database.editarPessoa(id, _nomeController.text, cpf);
    _refreshData();
  }

  void _deletarPessoa(int id) async {
    await Database.deletarPessoa(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.redAccent, content: Text("Pessoa deletada")));
    _refreshData();
  }

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();

  void showBottomSheet(int? id) async {
    if (id != null) {
      final existingData =
      _allData.firstWhere((element) => element['id'] == id);
      _nomeController.text = existingData['nome'];
      _cpfController.text = existingData['cpf'].toString();
    }

    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 30,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Nome",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cpfController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Cpf",
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  String nome = _nomeController.text.trim();
                  String cpf = _cpfController.text.trim();

                  if (nome.isEmpty || cpf.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Os campos Nome e CPF são obrigatórios."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  if (id == null) {
                    await _addPessoa();
                  }
                  if (id != null) {
                    await _editarPessoa(id);
                  }

                  _nomeController.text = "";
                  _cpfController.text = "";

                  Navigator.of(context).pop();
                  print("Pessoa adicionada");
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    id == null ? "Add Pessoa" : "Update",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8A8A8A),
      appBar: AppBar(
        title: const Text("Cadastro Pessoas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _allData.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.all(15),
          child: ListTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                _allData[index]['nome'],
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            subtitle: Text(_allData[index]['cpf'].toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: (){
                      showBottomSheet(_allData[index]['id']);
                    },
                    icon: Icon(Icons.edit,
                      color: Colors.indigo,
                    ),),
                IconButton(
                  onPressed: (){
                    _deletarPessoa(_allData[index]['id']);
                  },
                  icon: Icon(Icons.delete,
                    color: Colors.redAccent,
                  ),),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
