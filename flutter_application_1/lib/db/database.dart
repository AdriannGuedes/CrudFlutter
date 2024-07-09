import 'dart:async';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';


class Database {
  static final StreamController<List<Map<String, dynamic>>> _logController =
  StreamController.broadcast();

  static Stream<List<Map<String, dynamic>>> get logStream =>
      _logController.stream;


  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE cadastro_pessoas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      cpf INTEGER NOT NULL UNIQUE CHECK(cpf > 0 AND cpf < 9999999999)
    )""");

    await database.execute("""
      CREATE TABLE log_operacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
        tipo_operacao TEXT NOT NULL CHECK(tipo_operacao IN ('Insert', 'Update', 'Delete'))
      )
    """);

    await database.execute("""
      CREATE TRIGGER log_operacoes_insert
      AFTER INSERT ON cadastro_pessoas
      BEGIN
          INSERT INTO log_operacoes (tipo_operacao)
          VALUES ('Insert');
      END;
    """);

    await database.execute("""
      CREATE TRIGGER log_operacoes_update
      AFTER UPDATE ON cadastro_pessoas
      BEGIN
          INSERT INTO log_operacoes (tipo_operacao)
          VALUES ('Update');
      END;
    """);

    await database.execute("""
      CREATE TRIGGER log_operacoes_delete
      AFTER DELETE ON cadastro_pessoas
      BEGIN
          INSERT INTO log_operacoes (tipo_operacao)
          VALUES ('Delete');
      END;
    """);
  }

  static Future<sql.Database> db() async {
    sql.databaseFactory = databaseFactoryFfi;
    return await sql.openDatabase("cadastro.db", version: 1,
        onCreate: (sql.Database database, int version) async {
          await createTables(database);
        });

  }

  static Future<int> adicionarPessoa(String nome, int cpf) async {
    final db = await Database.db();

    List<Map<String, dynamic>> result = await db.query(
      'cadastro_pessoas',
      where: 'cpf = ?',
      whereArgs: [cpf],
    );

    if (result.isNotEmpty) {
      throw Exception('CPF já existe no banco de dados');
    }

    final data = {'nome': nome, 'cpf': cpf};
    final id = await db.insert('cadastro_pessoas', data);
    atualizarLog('Insert');
    return id;


  }

  static Future<List<Map<String, dynamic>>> buscarPessoas() async {
    final db = await Database.db();
    return db.query('cadastro_pessoas', orderBy: 'id');

  }

  static Future<List<Map<String, dynamic>>> buscarUmaPessoa(int id) async {
    final db = await Database.db();
    return db.query('cadastro_pessoas',
        where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> editarPessoa(int id, String nome, int cpf) async {
    final db = await Database.db();
    final data = {'nome': nome, 'cpf': cpf};
    final result = await db
        .update('cadastro_pessoas', data, where: "id = ?", whereArgs: [id]);
    atualizarLog('update');
    return result;
  }

  static Future<void> deletarPessoa(int id) async {
    final db = await Database.db();
    try {
      await db.delete('cadastro_pessoas', where: "id = ?", whereArgs: [id]);
      atualizarLog('delete');
    } catch (e) {
      print('Erro ao deletar pessoa: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> buscarLogOperacoes() async {
    final db = await Database.db();
    return db.query('log_operacoes', orderBy: 'data_hora DESC');
  }

  static void atualizarLog(String tipoOperacao) async {
    final agora = DateTime.now().toUtc(); // Captura a data e hora atuais em UTC
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(agora); // Formata a data e hora

    final data = {
      'data_hora': formattedDate, // Define a data e hora formatada
      'tipo_operacao': tipoOperacao, // Define o tipo de operação (Insert, Update, Delete)
    };

    final db = await Database.db();
    await db.insert('log_operacoes', data); // Insere os dados na tabela log_operacoes

    final logs = await buscarLogOperacoes();
    _logController.sink.add(logs); // Atualiza o stream com os logs

  }


  static void dispose() {
    _logController.close();
  }
}