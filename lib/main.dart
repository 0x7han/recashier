import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  database();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PathProvider()),
    ],
    child: const MyApp(),
  ));
  doWhenWindowReady(() {
    const initialSize = Size(1366, 722);
    appWindow
      ..minSize = initialSize
      ..size = initialSize
      ..alignment = Alignment.center
      ..show();
  });
}

List<Barang> barangs = [];

Future<Database> database() async {
  var databaseFactory = databaseFactoryFfi;
  String dbPath = p.join(io.Directory.current.path, 'sys32.db');

  return await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) {
        db.execute('''
            CREATE TABLE `penjualan` (
              `id` integer PRIMARY KEY AUTOINCREMENT,
              `tanggal` text,
              `kasir` text,
              `pembeli` text,
              `tipe_pembayaran` text,
              `tipe_harga` text,
              `jumlah_item` integer,
              `total_harga` real,
              `tunai` real,
              `kembali` real
            );

            CREATE TABLE `penjualan2` (
              `id` integer PRIMARY KEY AUTOINCREMENT,
              `penjualan_id` integer,
              `barang` text,
              `harga` real,
              `qty` integer,
              `total_harga` real
            );

        ''');
      },
    ),
  );
}

class PathProvider with ChangeNotifier {}

class Barang {
  String barang;
  String satuan;
  int qst;
  double hnaPpn;
  double medis;
  double warung;
  double otc;

  Barang(
      {required this.barang,
      required this.satuan,
      required this.qst,
      required this.hnaPpn,
      required this.medis,
      required this.warung,
      required this.otc});
}

class Keranjang {
  String barang;
  double harga;
  int qty;
  double totalHarga;

  Keranjang(
      {required this.barang,
      required this.harga,
      required this.qty,
      required this.totalHarga});
}

class Penjualan {
  late int? id;
  late String? tanggal;
  late String? kasir;
  late String pembeli;
  late String tipePembayaran;
  late String tipeHarga;
  late int jumlahItem;
  late double totalHarga;
  late double tunai;
  late double kembali;

  Penjualan(
      {this.id,
      this.tanggal,
      this.kasir,
      required this.pembeli,
      required this.tipePembayaran,
      required this.tipeHarga,
      required this.jumlahItem,
      required this.totalHarga,
      required this.tunai,
      required this.kembali});

  Map<String, dynamic> toMap() => {
        'tanggal': tanggal,
        'kasir': kasir,
        'pembeli': pembeli,
        'tipe_pembayaran': tipePembayaran,
        'tipe_harga': tipeHarga,
        'jumlah_item': jumlahItem,
        'total_harga': totalHarga,
        'tunai': tunai,
        'kembali': kembali,
      };
  Penjualan.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    tanggal = map['tanggal'];
    kasir = map['kasir'];
    pembeli = map['pembeli'];
    tipePembayaran = map['tipe_pembayaran'];
    tipeHarga = map['tipe_harga'];
    jumlahItem = map['jumlah_item'];
    totalHarga = map['total_harga'];
    tunai = map['tunai'];
    kembali = map['kembali'];
  }
}

class Penjualan2 {
  late int? id;
  late int? penjualanId;
  late String barang;
  late double harga;
  late int qty;
  late double totalHarga;

  Penjualan2(
      {this.id,
      required this.penjualanId,
      required this.barang,
      required this.harga,
      required this.qty,
      required this.totalHarga});

  Map<String, dynamic> toMap() => {
        'penjualan_id': penjualanId,
        'barang': barang,
        'harga': harga,
        'qty': qty,
        'total_harga': totalHarga,
      };
  Penjualan2.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    penjualanId = map['penjualan_id'];
    barang = map['barang'];
    harga = map['harga'];
    qty = map['qty'];
    totalHarga = map['total_harga'];
  }
}

class Laporan {
  final String tanggal;
  final String penanggungJawab;

  final double pendapatan;
  final double nominalKasir;
  final bool sesuai;
  final String? alasan;

  Laporan({
    required this.tanggal,
    required this.penanggungJawab,
    required this.pendapatan,
    required this.nominalKasir,
    required this.sesuai,
    this.alasan,
  });
}

class PenjualanController {
  String dateNow = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  String kasir = 'Admin';
  String tableName = 'penjualan';

  Future<List<Map<String, dynamic>>> get({String? date}) async {
    String d = DateFormat("yyyy-MM-dd").format(DateTime.parse(date ?? dateNow));
    var db = await database();
    List<Map<String, dynamic>> maps;
    maps =
        await db.query(tableName, where: 'tanggal LIKE ?', whereArgs: ['%$d%']);
    //print(maps);
    return maps;
  }

  Future<List<Map<String, dynamic>>> getCount({String? date}) async {
    String d = DateFormat("yyyy-MM-dd").format(DateTime.parse(date ?? ''));
    var db = await database();
    List<Map<String, dynamic>> maps;
    maps = await db.rawQuery(
        "SELECT COUNT(*) AS row FROM $tableName WHERE tanggal LIKE '%$d%'");
    //print(maps.first['row']);
    return maps.first['row'];
  }

  Future<String?> sumTotalHargaSeluruh(String date) async {
    var db = await database();
    List<Map<String, dynamic>> maps;
    maps = await db.rawQuery(
        "SELECT SUM(total_harga) AS pendapatan FROM $tableName WHERE tanggal LIKE '%$date%'");

    return maps.first['pendapatan'].toString();
  }

  Future<Penjualan> post(Penjualan penjualan) async {
    var db = await database();
    penjualan.tanggal = dateNow;
    penjualan.kasir = kasir;
    penjualan.id = await db.insert(tableName, penjualan.toMap());
    return penjualan;
  }
}

class Penjualan2Controller {
  String tableName = 'penjualan2';

  Future<List<Map<String, dynamic>>> get(int penjualanId) async {
    var db = await database();
    List<Map<String, dynamic>> maps;
    maps = await db
        .query(tableName, where: 'penjualan_id = ?', whereArgs: [penjualanId]);
    List<Map<String, dynamic>> maps2 = await db.query(tableName);
    //print(maps2);
    return maps;
  }

  Future<Penjualan2> post(Penjualan2 penjualan2) async {
    var db = await database();
    await db.insert(tableName, penjualan2.toMap());
    return penjualan2;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      restorationScopeId: "desktop-test1",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyMainPage(),
    );
  }
}

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> {
  final PenjualanController penjualanController = PenjualanController();
  final Penjualan2Controller penjualan2Controller = Penjualan2Controller();

  final TextEditingController alasanController = TextEditingController();
  final TextEditingController nominalKasirController = TextEditingController();
  final TextEditingController penanggungJawabController =
      TextEditingController();
  double nominalKasir = 0.0;

  void onNominal() {
    nominalKasir = double.tryParse(nominalKasirController.text) ?? 0.0;
  }

  bool isPendapatanMatch = false;

  void findPathHarga() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      io.File file = io.File(result.files.single.path!);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pathHarga', file.path);
      final String? path = prefs.getString('pathHarga');
      setState(() {});
      //print(path);
    } else {
      //print('batal');
    }
  }

  Future<String?> getPathHarga() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('pathHarga');
  }

  String toIDR(double value) {
    MoneyFormatter fmf = MoneyFormatter(
        amount: value,
        settings: MoneyFormatterSettings(
          symbol: 'Rp',
          thousandSeparator: '.',
          decimalSeparator: ',',
          symbolAndNumberSeparator: ' ',
          fractionDigits: 0,
        ));
    return fmf.output.symbolOnLeft;
  }

  String _dateTime = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> showDateTimePicker() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024, 4, 1), // harus berdasarkan data
      lastDate: DateTime(2025, 12, 1), //notes
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selectedDate != null) {
      setState(() {
        _dateTime = DateFormat("yyyy-MM-dd").format(selectedDate);
      });
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    DateTime dn = DateTime.now();
    String dateNow = DateFormat('yyyy-MM-dd').format(dn);
    String pen = await penjualanController.sumTotalHargaSeluruh(dateNow) ?? '';
    double pendapatan = double.tryParse(pen) ?? 0.0;
    Laporan laporan = Laporan(
      tanggal: dn.toString(),
      penanggungJawab: penanggungJawabController.text,
      pendapatan: pendapatan,
      nominalKasir: double.tryParse(nominalKasirController.text) ?? 0.0,
      sesuai: isPendapatanMatch,
      alasan: alasanController.text,
    );
    List<Map<String, dynamic>> penjualan =
        await penjualanController.get(date: _dateTime);

    
    print(penjualan);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          const pw.TextStyle headStyle = pw.TextStyle(
            fontSize: 32,
          );
          const pw.TextStyle subHeadStyle = pw.TextStyle(
            fontSize: 18,
          );
          const pw.TextStyle bodyStyle = pw.TextStyle(
            fontSize: 12,
          );
          return [
                  pw.Text('== APOTEK PINTU ==', style: headStyle),
                  pw.Text('Laporan Keuangan', style: subHeadStyle),
                  pw.Text('________________________________________________',
                      style: subHeadStyle),
                  pw.SizedBox(height: 16),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 200,
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('Tanggal ', style: bodyStyle),
                                      pw.Text('Penanggung Jawab ',
                                          style: bodyStyle),
                                      pw.Text('Pendapatan ', style: bodyStyle),
                                      pw.Text('Nominal Kasir ',
                                          style: bodyStyle),
                                      pw.Text('Sesuai ', style: bodyStyle),
                                      pw.Text('Alasan ', style: bodyStyle),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(': ${laporan.tanggal}',
                                          style: bodyStyle),
                                      pw.Text(': ${laporan.penanggungJawab}',
                                          style: bodyStyle),
                                      pw.Text(': ${toIDR(laporan.pendapatan)}',
                                          style: bodyStyle),
                                      pw.Text(
                                          ': ${toIDR(isPendapatanMatch ? pendapatan : nominalKasir)}',
                                          style: bodyStyle),
                                      pw.Text(': ${laporan.sesuai}',
                                          style: bodyStyle),
                                      pw.Text(': ${laporan.alasan} ',
                                          style: bodyStyle),
                                    ]),
                              ]),
                        ),
                      ]),
                  pw.Text('________________________________________________',
                      style: subHeadStyle),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: pw.EdgeInsets.all(8),
                    height: 40,
                    color: PdfColor.fromHex('#99f0b0'),
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.SizedBox(
                            width: 30,
                            child: pw.Text('No'),
                          ),
                          pw.SizedBox(
                            width: 50,
                            child: pw.Text('Jam'),
                          ),
                          pw.SizedBox(
                            width: 60,
                            child: pw.Text('Pembeli'),
                          ),
                          pw.SizedBox(
                            width: 120,
                            child: pw.Text('Tipe Pembayaran'),
                          ),
                          pw.SizedBox(
                            width: 80,
                            child: pw.Text('Tipe Harga'),
                          ),
                          pw.SizedBox(
                            width: 120,
                            child: pw.Text('Total Harga'),
                          ),
                        ]),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Column(
                      children: penjualan.asMap().entries.map((entry) {
                        
                        var index = entry.key +
                            1; // Menambahkan 1 karena indeks dimulai dari 0
                        var item = entry.value;
                        var penjualan2 =  penjualan2Controller.get(item['id']);
                        String tanggal = item['tanggal'];
                        String t = tanggal.substring(11);
                        String jam = t.substring(0, t.length - 3);
                        
                        return pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.SizedBox(
                              width: 30,
                              child: pw.Text('${index}'),
                            ),
                            pw.SizedBox(
                              width: 50,
                              child: pw.Text('${jam}'),
                            ),
                            pw.SizedBox(
                              width: 60,
                              child: pw.Text('${item['pembeli']}'),
                            ),
                            pw.SizedBox(
                              width: 120,
                              child: pw.Text('${item['tipe_pembayaran']}'),
                            ),
                            pw.SizedBox(
                              width: 80,
                              child: pw.Text('${item['tipe_harga']}'),
                            ),
                            pw.SizedBox(
                              width: 120,
                              child: pw.Text('${toIDR(item['total_harga'])}'),
                            ),
                            
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _dialogBuilder(
      BuildContext context, List<Penjualan> penjualan) async {
    TextTheme textTheme = Theme.of(context).textTheme;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    DateTime dn = DateTime.now();
    String dateNow = DateFormat('yyyy-MM-dd').format(dn);
    String pen = await penjualanController.sumTotalHargaSeluruh(dateNow) ?? '';
    double pendapatan = double.tryParse(pen) ?? 0.0;

    return showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, stfState) => AlertDialog(
            title: const Text('Buat Laporan'),
            content: SizedBox(
              width: 900,
              height: 500,
              child: Row(
                children: [
                  // SizedBox(
                  //   width: 500,
                  //   height: 500,
                  //   child: PdfPreview(
                  //     useActions: false,
                  //     build: (format) =>_generatePdf(penjualan: []),
                  //   ),
                  // ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Keterangan',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal ',
                                ),
                                Text('Penanggung Jawab '),
                                Text('Pendapatan '),
                                Text('Nominal Kasir '),
                                Text('Sesuai '),
                                Text('Alasan '),
                              ],
                            ),
                            SizedBox(
                              width: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ': $dateNow',
                                  ),
                                  Text(
                                    ': ${penanggungJawabController.text}',
                                  ),
                                  Text(': ${toIDR(pendapatan)}'),
                                  Text(
                                      ': ${toIDR(isPendapatanMatch ? pendapatan : nominalKasir)}'),
                                  Text(': $isPendapatanMatch'),
                                  Text(': ${alasanController.text}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isPendapatanMatch,
                                    onChanged: (bool? value) {
                                      stfState(() {
                                        isPendapatanMatch = value!;
                                      });
                                    },
                                  ),
                                  const Text(
                                      'Pendapatan sesuai dengan jumlah uang dikasir'),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: TextField(
                            controller: alasanController,
                            onChanged: (value) {
                              stfState(() {});
                            },
                            enabled: isPendapatanMatch ? false : true,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.primary)),
                              labelText: 'Alasan',
                              border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.primary)),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: TextField(
                            controller: nominalKasirController,
                            onChanged: (value) {
                              stfState(() {
                                onNominal();
                              });
                            },
                            enabled: isPendapatanMatch ? false : true,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.primary)),
                              labelText: 'Jumlah uang dikasir',
                              border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.primary)),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: TextField(
                            controller: penanggungJawabController,
                            onChanged: (value) {
                              stfState(() {});
                            },
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.primary)),
                              labelText: 'Penanggung Jawab',
                              border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: colorScheme.primary)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  var snackBar = SnackBar(
                    content: Text(
                        'File laporan tersimpan di folder Documents dengan nama : Recashier-$dateNow-${dn.hour}-${dn.minute}.pdf'),
                  );
                  final output = await getApplicationDocumentsDirectory();
                  final file = File(
                      '${output.path}/Recashier-$dateNow-${dn.hour}-${dn.minute}.pdf');
                  if (await file.exists()) {
                    await file.delete(); // Menghapus file jika sudah ada
                  }
                  await file.writeAsBytes(await _generatePdf());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pop(context);
                  }
                },
                // onPressed: () => Printing.layoutPdf(
                //     onLayout: (PdfPageFormat format) => _generatePdf()),
                label: const Text('Simpan'),
                icon: const Icon(Icons.picture_as_pdf),
              ),
              FilledButton.tonal(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Selesai')),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Re Cashier'),
        actions: [
          FutureBuilder<String?>(
            future: getPathHarga(),
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              Widget child;
              if (snapshot.hasData) {
                child = Text(snapshot.data ?? '');
              } else if (snapshot.hasError) {
                child = const Text('Data belum ada');
              } else {
                child = const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                );
              }
              return child;
            },
          ),
          const SizedBox(
            width: 16,
          ),
          FilledButton(
              onPressed: () => findPathHarga(),
              child: const Text("Pilih file")),
          const SizedBox(
            width: 16,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AddPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilledButton.tonalIcon(
                    onPressed: () => showDateTimePicker(),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Pilih tanggal')),
                const SizedBox(
                  width: 16,
                ),
                FilledButton.tonalIcon(
                    onPressed: () => _dialogBuilder(context, []),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Bikin laporan'))
              ],
            ),
          ),
          SizedBox(
            height: 550,
            child: SingleChildScrollView(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: penjualanController.get(date: _dateTime),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  Widget child;
                  if (snapshot.hasData) {
                    child = DataTable(
                      columns: const [
                        DataColumn(label: Text('No')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Kasir')),
                        DataColumn(label: Text('Pembeli')),
                        DataColumn(label: Text('Tipe Pembayaran')),
                        DataColumn(label: Text('Tipe Harga')),
                        DataColumn(label: Text('Total Item')),
                        DataColumn(label: Text('Total Harga')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: (() {
                        int index = 1; // Variable to keep track of the index
                        return snapshot.data!.map((item) {
                          //print(item);
                          final Penjualan penjualan = Penjualan.fromMap(item);
                          final currentIndex =
                              index++; // Increment the index for each item
                          return DataRow(cells: [
                            DataCell(Text(currentIndex
                                .toString())), // Use currentIndex for dynamic number
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(DateFormat("yyyy-MM-dd HH:mm:ss")
                                    .parse(penjualan.tanggal ?? '')
                                    .toString()),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(penjualan.kasir ?? ''),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(penjualan.pembeli),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(penjualan.tipePembayaran),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(penjualan.tipeHarga),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(penjualan.jumlahItem.toString()),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(toIDR(penjualan.totalHarga)),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Row(
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => DetailPage(
                                                    penjualan: penjualan,
                                                  )),
                                        );
                                      },
                                      child: const Text('Detail'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]);
                        }).toList();
                      })(),
                    );
                  } else if (snapshot.hasError) {
                    child = const Text('Data belum ada');
                  } else {
                    child = const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    );
                  }
                  return child;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FutureBuilder<String?>(
                  future: penjualanController.sumTotalHargaSeluruh(_dateTime),
                  builder:
                      (BuildContext context, AsyncSnapshot<String?> snapshot) {
                    Widget child;
                    if (snapshot.hasData) {
                      child = Text(
                          'Pendapatan ${_dateTime} : ${toIDR(double.tryParse(snapshot.data.toString()) ?? 0.0)}');
                    } else if (snapshot.hasError) {
                      child = const Text('Data belum ada');
                    } else {
                      child = const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(),
                      );
                    }
                    return child;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController pembeliController = TextEditingController(text: 'UMUM');
  TextEditingController tunaiController = TextEditingController(text: '');
  String kembali = '';
  String _groupHarga = 'OTC';
  String _groupPembayaran = 'Tunai';

  double tipeHarga(double otc, double medis, double warung) {
    double val = 0.0;
    switch (_groupHarga) {
      case 'OTC':
        val = otc;

      case 'Medis':
        val = medis;
      case 'Warung':
        val = warung;
      default:
    }

    return val;
  }

  void setPembayaran(String value) {
    setState(() {
      _groupPembayaran = value;
    });
  }

  void setHarga(String value) {
    setState(() {
      _groupHarga = value;
    });
  }

  Future<void> loadHargaExcel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String file = prefs.getString('pathHarga') ?? '';
    var bytes = io.File(file).readAsBytesSync();
    var excel = ex.Excel.decodeBytes(bytes);

    // print(excel.tables['Sheet1']?.maxColumns);
    // print(excel.tables['Sheet1']?.maxRows);

    // row

    for (var row in excel.tables['Sheet1']!.rows.skip(1)) {
      String barang = '';
      String satuan = '';
      int qst = 0;
      double hnaPpn = 0.0;
      double medis = 0.0;
      double warung = 0.0;
      double otc = 0.0;

      double tempHnaPpn = 0.0;
      for (var cell in row) {
        // print('cell ${cell?.rowIndex}/${cell?.columnIndex}');
        final value = cell?.value;
        // final numFormat =
        //     cell?.cellStyle?.numberFormat ?? ex.NumFormat.standard_0;
        var result;

        switch (value) {
          case null:
            break;
          case ex.TextCellValue():
            //print('  text: ${value.value}');
            result = value.value;
          case ex.FormulaCellValue():
            break;
          case ex.IntCellValue():
            //print('  int: ${value.value}');
            result = value.value;
          case ex.BoolCellValue():
            break;
          case ex.DoubleCellValue():
            //print('  double: ${value.value}');
            result = value.value;
          case ex.DateCellValue():
            break;
          case ex.TimeCellValue():
            break;
          case ex.DateTimeCellValue():
            break;
        }
        if (cell?.columnIndex == 1) {
          barang = result.toString();
        } else if (cell?.columnIndex == 2) {
          satuan = result.toString();
        } else if (cell?.columnIndex == 3) {
          qst = result is int ? result : 0;
        } else if (cell?.columnIndex == 4) {
          hnaPpn = double.tryParse(result.toString()) ?? 0.0;
          tempHnaPpn = hnaPpn;
        } else if (cell?.columnIndex == 5) {
          double res = tempHnaPpn * 1.07;
          medis = res;
        } else if (cell?.columnIndex == 6) {
          double res = tempHnaPpn * 1.11;
          warung = res;
        } else if (cell?.columnIndex == 7) {
          otc = double.tryParse(result.toString()) ?? 0.0;
        }
      }
      barangs.add(Barang(
          barang: barang,
          satuan: satuan,
          qst: qst,
          hnaPpn: hnaPpn,
          medis: medis,
          warung: warung,
          otc: otc));
    }
    // for (var barang in barangs) {
    //   print(barang.barang);
    //   print(barang.satuan);
    //   print(barang.hnaPpn);
    //   print(barang.medis);
    //   print(barang.warung);
    //   print(barang.otc);
    // }
  }

  // Future<List<Barang>> _filterData(String value) async{
  //   return barangs.where((item) => item.barang.contains(value)).toList();
  // }

  List<Barang> _filteredBarangs = [];

  Future<void> _filterData(String value) async {
    List<Barang> filteredBarangs = barangs
        .where((item) => item.barang.contains(value.toUpperCase()))
        .toList();
    setState(() {
      _filteredBarangs = filteredBarangs;
    });
  }

  String toIDR(double value, {bool isTotal = true}) {
    MoneyFormatter fmf = MoneyFormatter(
        amount: value,
        settings: MoneyFormatterSettings(
          symbol: isTotal ? 'Rp' : '@',
          thousandSeparator: '.',
          decimalSeparator: ',',
          symbolAndNumberSeparator: ' ',
          fractionDigits: 0,
        ));
    return fmf.output.symbolOnLeft;
  }

  void sumTotalHarga() {
    double totalHarga = _keranjang.fold(0, (previousValue, keranjang) {
      return previousValue + keranjang.totalHarga;
    });
    _totalHarga = totalHarga;
  }

  void sumTotalQty() {
    int totalQty = _keranjang.fold(0, (previousValue, keranjang) {
      return previousValue + keranjang.qty;
    });
    _totalQty = totalQty;
  }

  @override
  void initState() {
    super.initState();
    //print(barangs.isEmpty);
    if (barangs.isEmpty) {
      loadHargaExcel();
    }
  }

  final List<Keranjang> _keranjang = [];
  double _totalHarga = 0.0;
  int _totalQty = 0;

  final TextEditingController _searchController = TextEditingController();

  Future<Uint8List> _generatePdf(Penjualan penjualan) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (context) {
          const pw.TextStyle headStyle = pw.TextStyle(
            fontSize: 12,
          );
          const pw.TextStyle bodyStyle = pw.TextStyle(
            fontSize: 8,
          );
          return pw.Container(
            margin: const pw.EdgeInsets.only(right: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('- Apotek Pintu -', style: headStyle),
                pw.Text('Jl Raya Pangalengan No 755', style: bodyStyle),
                pw.Text('RW 22 RT 01, Kp Pintu', style: bodyStyle),
                pw.Text('Desa Sukamanah', style: bodyStyle),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(penjualan.tanggal.toString(), style: bodyStyle),
                      pw.Text(penjualan.kasir.toString(), style: bodyStyle),
                    ]),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Row(children: [
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text('Item', style: bodyStyle),
                  ),
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text('Qty', style: bodyStyle),
                  ),
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text('Harga', style: bodyStyle),
                  ),
                ]),
                for (var item in _keranjang)
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 60,
                        child: pw.Text(item.barang, style: bodyStyle),
                      ),
                      pw.SizedBox(
                        width: 20,
                        child: pw.Text(item.qty.toString(), style: bodyStyle),
                      ),
                      pw.SizedBox(
                          width: 50,
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(toIDR(item.totalHarga),
                                    style: bodyStyle),
                                pw.Text(toIDR(item.harga, isTotal: false),
                                    style: bodyStyle.copyWith(fontSize: 6)),
                              ])),
                    ],
                  ),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(penjualan.tipeHarga, style: bodyStyle),
                          pw.Text(penjualan.pembeli, style: bodyStyle),
                          pw.Text(penjualan.tipePembayaran, style: bodyStyle),
                        ],
                      ),
                      pw.Row(children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total ', style: bodyStyle),
                              pw.Text('Tunai ', style: bodyStyle),
                              pw.Text('Kembali ', style: bodyStyle),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(': ${toIDR(penjualan.totalHarga)}',
                                  style: bodyStyle),
                              pw.Text(': ${toIDR(penjualan.tunai)}',
                                  style: bodyStyle),
                              pw.Text(': ${toIDR(penjualan.kembali)}',
                                  style: bodyStyle),
                            ]),
                      ]),
                    ]),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Text('== Terimakasih ==', style: headStyle),
                pw.Text('Customer Service', style: bodyStyle),
                pw.Text('+62 821-1619-9684', style: bodyStyle),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _dialogBuilder(BuildContext context, Penjualan penjualan) {
    return showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cetak struk'),
          content: Container(
            color: Colors.red,
            width: 250,
            child: PdfPreview(
              useActions: false,
              build: (format) => _generatePdf(penjualan),
            ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: () => Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) => _generatePdf(penjualan)),
              label: const Text('Cetak'),
              icon: const Icon(Icons.print),
            ),
            FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPage()),
                  );
                },
                child: const Text('Selesai')),
          ],
        );
      },
    );
  }

  void onKembali() {
    double tunai = double.tryParse(tunaiController.text) ?? 0.0;
    double kembalian = tunai - _totalHarga;
    kembali = kembalian.isNegative ? '0' : kembalian.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final PenjualanController penjualanController = PenjualanController();
    final Penjualan2Controller penjualan2Controller = Penjualan2Controller();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyMainPage()),
                    ),
                icon: const Icon(Icons.arrow_back)),
            const SizedBox(
              width: 8,
            ),
            const Text('Kembali'),
          ],
        ),
      ),
      body: Container(
        child: Row(
          children: [
            Expanded(
                child: Container(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 32,
                        ),
                        Text(
                          'Perhatian ketika ada update data barang, harap mulai ulang aplikasi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        print(value);
                        _filterData(value);
                      },
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary)),
                        labelText: 'Cari barang',
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary)),
                      ),
                    ),
                  ),
                  FutureBuilder<List<Barang>?>(
                    future: Future.value(_filteredBarangs),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Barang>?> snapshot) {
                      Widget child;
                      if (snapshot.hasData) {
                        List<Barang>? data = snapshot.data;
                        child = Container(
                          padding: const EdgeInsets.all(8),
                          height: 490,
                          child: SingleChildScrollView(
                            child: DataTable(
                                dataRowMinHeight: 40,
                                dataRowMaxHeight: 60,
                                columns: const [
                                  DataColumn(label: Text('Barang')),
                                  DataColumn(label: Text('Satuan')),
                                  DataColumn(label: Text('Q/ST')),
                                  // DataColumn(label: Text('HNAPPN')),
                                  DataColumn(label: Text('0.07')),
                                  DataColumn(label: Text('11%')),
                                  DataColumn(label: Text('OTC')),
                                  DataColumn(label: Text('Aksi')),
                                ],
                                rows: data!
                                    .take(20)
                                    .map((Barang item) => DataRow(cells: [
                                          DataCell(Text(item.barang)),
                                          DataCell(Text(item.satuan)),
                                          DataCell(Text(item.qst.toString())),
                                          // DataCell(Text('Rp ${item.hnaPpn.toStringAsFixed(2)}')),
                                          DataCell(Text(toIDR(item.medis))),
                                          DataCell(Text(toIDR(item.warung))),
                                          DataCell(Text(toIDR(item.otc))),
                                          DataCell(
                                            SizedBox(
                                              width: 100,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: IconButton
                                                          .filledTonal(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        iconSize: 18,
                                                        onPressed: () {
                                                          if (!_keranjang.any(
                                                              (element) =>
                                                                  element
                                                                      .barang ==
                                                                  item.barang)) {
                                                            setState(() {
                                                              _keranjang.add(Keranjang(
                                                                  barang: item
                                                                      .barang,
                                                                  harga: tipeHarga(
                                                                      item.otc,
                                                                      item
                                                                          .medis,
                                                                      item
                                                                          .warung),
                                                                  qty: 1,
                                                                  totalHarga: tipeHarga(
                                                                      item.otc,
                                                                      item.medis,
                                                                      item.warung)));
                                                              sumTotalHarga();
                                                              sumTotalQty();
                                                            });
                                                          }
                                                          // print('=====');
                                                          // for (var item
                                                          //     in _keranjang) {
                                                          //   print(item.barang);
                                                          //   print(item.qty);
                                                          //   print(item
                                                          //       .totalHarga);
                                                          // }
                                                          // print('=====');
                                                        },
                                                        icon: const Icon(
                                                            Icons.add),
                                                        tooltip: 'Tambah',
                                                      )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ]))
                                    .toList()),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        child = const Text('Data belum ada');
                      } else {
                        child = const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(),
                        );
                      }
                      return child;
                    },
                  ),
                ],
              ),
            )),
            Container(
              width: 500,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        'Keranjang',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: pembeliController,
                                enabled: _groupHarga == 'OTC' ? false : true,
                                decoration: InputDecoration(
                                  labelText: 'Pembeli',
                                  border: const OutlineInputBorder(),
                                  errorText: pembeliController.text == ''
                                      ? 'Harap isi nama'
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  onKembali();
                                  setHarga('OTC');
                                  pembeliController.text = 'UMUM';
                                });
                                for (var itemKeranjang in _keranjang) {
                                  Barang? barang = barangs.firstWhere(
                                    (element) =>
                                        itemKeranjang.barang == element.barang,
                                  );
                                  setState(() {
                                    itemKeranjang.harga = barang.otc;
                                    itemKeranjang.totalHarga =
                                        itemKeranjang.qty * itemKeranjang.harga;
                                    sumTotalHarga();
                                  });
                                  print(itemKeranjang.barang);
                                  print(itemKeranjang.harga);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('OTC'),
                                  const Text('Umum'),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(top: 8),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _groupHarga == 'OTC'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: colorScheme.primary),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  onKembali();
                                  setHarga('Warung');
                                  pembeliController.text = '';
                                });
                                for (var itemKeranjang in _keranjang) {
                                  Barang? barang = barangs.firstWhere(
                                    (element) =>
                                        itemKeranjang.barang == element.barang,
                                  );
                                  setState(() {
                                    itemKeranjang.harga = barang.warung;
                                    itemKeranjang.totalHarga =
                                        itemKeranjang.qty * itemKeranjang.harga;
                                    sumTotalHarga();
                                  });
                                  print(itemKeranjang.barang);
                                  print(itemKeranjang.harga);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('11%'),
                                  const Text('Warung'),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(top: 8),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _groupHarga == 'Warung'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: colorScheme.primary),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  onKembali();
                                  setHarga('Medis');
                                  pembeliController.text = '';
                                });
                                for (var itemKeranjang in _keranjang) {
                                  Barang? barang = barangs.firstWhere(
                                    (element) =>
                                        itemKeranjang.barang == element.barang,
                                  );
                                  setState(() {
                                    itemKeranjang.harga = barang.medis;
                                    itemKeranjang.totalHarga =
                                        itemKeranjang.qty * itemKeranjang.harga;
                                    sumTotalHarga();
                                  });
                                  print(itemKeranjang.barang);
                                  print(itemKeranjang.harga);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('0.07'),
                                  const Text('Medis'),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(top: 8),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _groupHarga == 'Medis'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: colorScheme.primary),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      FutureBuilder<List<Keranjang>?>(
                        future: Future.value(_keranjang),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Keranjang>?> snapshot) {
                          Widget child;
                          if (snapshot.hasData) {
                            List<Keranjang>? data = snapshot.data;

                            child = SizedBox(
                              height: 300,
                              child: SingleChildScrollView(
                                child: DataTable(
                                    dataRowMinHeight: 30,
                                    dataRowMaxHeight: 50,
                                    columns: const [
                                      DataColumn(label: Text('Barang')),
                                      DataColumn(label: Text('        Qty')),
                                      DataColumn(label: Text('Jumlah')),
                                      DataColumn(label: Text('Aksi')),
                                    ],
                                    rows: data!.map((item) {
                                      Keranjang obj = _keranjang.firstWhere(
                                          (element) =>
                                              element.barang == item.barang);
                                      return DataRow(cells: [
                                        DataCell(Text(item.barang)),
                                        DataCell(Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    // disini

                                                    if (obj.qty > 1) {
                                                      onKembali();
                                                      obj.qty = obj.qty - 1;
                                                      obj.totalHarga =
                                                          obj.harga * obj.qty;
                                                      sumTotalHarga();
                                                      sumTotalQty();
                                                    }
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.arrow_left)),
                                            Text(
                                              item.qty.toString(),
                                              style: TextStyle(
                                                  color: colorScheme.primary),
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    onKembali();
                                                    obj.qty = obj.qty + 1;
                                                    obj.totalHarga =
                                                        obj.harga * obj.qty;
                                                    sumTotalHarga();
                                                    sumTotalQty();
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.arrow_right)),
                                          ],
                                        )),
                                        DataCell(Text(
                                            toIDR(item.totalHarga))), //disini
                                        DataCell(IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _keranjang.removeWhere(
                                                    (element) =>
                                                        element.barang ==
                                                        obj.barang);
                                                sumTotalHarga();
                                                onKembali();
                                              });
                                            },
                                            icon: const Icon(Icons.delete))),
                                      ]);
                                    }).toList()),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            child = const Text('Data belum ada');
                          } else {
                            child = const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(),
                            );
                          }
                          return child;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: tunaiController,
                          enabled: _groupPembayaran != 'Tunai' ? false : true,
                          decoration: InputDecoration(
                            labelText: 'Tunai',
                            border: const OutlineInputBorder(),
                            errorText: tunaiController.text.isEmpty
                                ? 'Harap isi nominal'
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              onKembali();
                            });
                          },
                          onEditingComplete: () {
                            double val = double.parse(tunaiController.text);
                            tunaiController.text = toIDR(val);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                setPembayaran('Tunai');
                                tunaiController.text = '';
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Tunai'),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _groupPembayaran == 'Tunai'
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    border:
                                        Border.all(color: colorScheme.primary),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                setPembayaran('Transfer');
                                tunaiController.text = '-';
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Transfer'),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _groupPembayaran == 'Transfer'
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    border:
                                        Border.all(color: colorScheme.primary),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Total : ${toIDR(_totalHarga)}'),
                          Text(
                              'Tunai : ${_groupPembayaran == 'Tunai' ? toIDR(double.tryParse(tunaiController.text) ?? 0.0) : '-'}'),
                          Text(
                              'Kembali : ${_groupPembayaran == 'Tunai' ? toIDR(double.tryParse(kembali) ?? 0.0) : '-'}'),
                        ],
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () async {
                      //ini
                      onKembali();
                      Penjualan penjualan =
                          await penjualanController.post(Penjualan(
                        pembeli: pembeliController.text,
                        tipePembayaran: _groupPembayaran,
                        tipeHarga: _groupHarga,
                        jumlahItem: _totalQty,
                        totalHarga: _totalHarga,
                        tunai: double.tryParse(tunaiController.text) ?? 0.0,
                        kembali: double.tryParse(kembali) ?? 0.0,
                      ));

                      for (var item in _keranjang) {
                        penjualan2Controller.post(Penjualan2(
                            penjualanId: penjualan.id,
                            barang: item.barang,
                            harga: item.harga,
                            qty: item.qty,
                            totalHarga: item.totalHarga));
                      }
                      _dialogBuilder(context, penjualan);
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Penjualan penjualan;
  const DetailPage({super.key, required this.penjualan});

  String toIDR(double value, {bool isTotal = true}) {
    MoneyFormatter fmf = MoneyFormatter(
        amount: value,
        settings: MoneyFormatterSettings(
          symbol: isTotal ? 'Rp' : '@',
          thousandSeparator: '.',
          decimalSeparator: ',',
          symbolAndNumberSeparator: ' ',
          fractionDigits: 0,
        ));
    return fmf.output.symbolOnLeft;
  }

  Future<Uint8List> _generatePdf(
      Penjualan penjualan, List<Map<String, dynamic>> penjualan2s) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (context) {
          const pw.TextStyle headStyle = pw.TextStyle(
            fontSize: 12,
          );
          const pw.TextStyle bodyStyle = pw.TextStyle(
            fontSize: 8,
          );
          return pw.Container(
            margin: const pw.EdgeInsets.only(right: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('- Apotek Pintu -', style: headStyle),
                pw.Text('Jl Raya Pangalengan No 755', style: bodyStyle),
                pw.Text('RW 22 RT 01, Kp Pintu', style: bodyStyle),
                pw.Text('Desa Sukamanah', style: bodyStyle),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(penjualan.tanggal.toString(), style: bodyStyle),
                      pw.Text(penjualan.kasir.toString(), style: bodyStyle),
                    ]),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Row(children: [
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text('Item', style: bodyStyle),
                  ),
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text('Qty', style: bodyStyle),
                  ),
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text('Harga', style: bodyStyle),
                  ),
                ]),
                for (var item in penjualan2s)
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 60,
                        child: pw.Text(item['barang'], style: bodyStyle),
                      ),
                      pw.SizedBox(
                        width: 20,
                        child:
                            pw.Text(item['qty'].toString(), style: bodyStyle),
                      ),
                      pw.SizedBox(
                          width: 50,
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(toIDR(item['total_harga']),
                                    style: bodyStyle),
                                pw.Text(toIDR(item['harga'], isTotal: false),
                                    style: bodyStyle.copyWith(fontSize: 6)),
                              ])),
                    ],
                  ),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(penjualan.tipeHarga, style: bodyStyle),
                          pw.Text(penjualan.pembeli, style: bodyStyle),
                          pw.Text(penjualan.tipePembayaran, style: bodyStyle),
                        ],
                      ),
                      pw.Row(children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total ', style: bodyStyle),
                              pw.Text('Tunai ', style: bodyStyle),
                              pw.Text('Kembali ', style: bodyStyle),
                            ],),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(': ${toIDR(penjualan.totalHarga)}',
                                  style: bodyStyle),
                              pw.Text(': ${toIDR(penjualan.tunai)}',
                                  style: bodyStyle),
                              pw.Text(': ${toIDR(penjualan.kembali)}',
                                  style: bodyStyle),
                            ]),
                      ]),
                    ]),
                pw.Text('--------------------------------------------',
                    style: bodyStyle),
                pw.Text('== Terimakasih ==', style: headStyle),
                pw.Text('Customer Service', style: bodyStyle),
                pw.Text('+62 821-1619-9684', style: bodyStyle),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final Penjualan2Controller penjualan2Controller = Penjualan2Controller();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyMainPage()),
                    ),
                icon: const Icon(Icons.arrow_back)),
            const SizedBox(
              width: 8,
            ),
            const Text('Kembali'),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.tonalIcon(
            onPressed: () async {
              List<Map<String, dynamic>> penjualan2s =
                  await penjualan2Controller.get(penjualan.id ?? 0);
              print(penjualan2s);
              Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) =>
                      _generatePdf(penjualan, penjualan2s));
            },
            label: Text('Cetak'),
            icon: Icon(Icons.print),
          ),
          SizedBox(width: 8,),
         FilledButton.tonalIcon(
                onPressed: () async {
                  String tanggal = penjualan.tanggal ?? '';
                  tanggal = tanggal.replaceAll(" ", "-").replaceAll(":", "");
                  List<Map<String, dynamic>> penjualan2s =
                  await penjualan2Controller.get(penjualan.id ?? 0);
                 var snackBar = SnackBar(
                    content: Text(
                        'File bill tersimpan di folder Documents dengan nama : Recashier-bill-${tanggal}-${penjualan.tipeHarga}-${penjualan.pembeli}.pdf'),
                  );
                  final output = await getApplicationDocumentsDirectory();
                  final file = File(
                      '${output.path}/Recashier-bill-${tanggal}-${penjualan.tipeHarga}-${penjualan.pembeli}.pdf');
                  if (await file.exists()) {
                    await file.delete(); // Menghapus file jika sudah ada
                  }
                  await file.writeAsBytes(await _generatePdf(penjualan, penjualan2s));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyMainPage()),
                    );
                  }
                   
                },
                label: const Text('Simpan'),
                icon: const Icon(Icons.picture_as_pdf),
              ), 
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 550,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 350,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal'),
                            Text('Kasir'),
                            Text('Pembeli'),
                            Text('Tipe Pembayaran'),
                            Text('Tipe Harga'),
                            Text('Total Item'),
                            Text('Total Harga'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat("yyyy-MM-dd HH:mm:ss")
                                .parse(penjualan.tanggal ?? '')
                                .toString()),
                            Text(penjualan.kasir.toString()),
                            Text(penjualan.pembeli),
                            Text(penjualan.tipePembayaran),
                            Text(penjualan.tipeHarga),
                            Text(penjualan.jumlahItem.toString()),
                            Text(toIDR(penjualan.totalHarga)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      height: 400,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: penjualan2Controller.get(penjualan.id ?? 0),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Map<String, dynamic>>>
                                snapshot) {
                          Widget child;
                          if (snapshot.hasData) {
                            child = DataTable(
                              columns: const [
                                DataColumn(label: Text('No')),
                                DataColumn(label: Text('Barang')),
                                DataColumn(label: Text('Qty')),
                                DataColumn(label: Text('Total Harga')),
                              ],
                              rows: (() {
                                int index =
                                    1; // Variable to keep track of the index
                                return snapshot.data!.map((item) {
                                  // print(item);
                                  final Penjualan2 penjualan2 =
                                      Penjualan2.fromMap(item);
                                  final currentIndex =
                                      index++; // Increment the index for each item
                                  return DataRow(cells: [
                                    DataCell(Text(currentIndex
                                        .toString())), // Use currentIndex for dynamic number
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: Text(penjualan2.barang),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: Text(penjualan2.qty.toString()),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child:
                                            Text(toIDR(penjualan2.totalHarga)),
                                      ),
                                    ),
                                  ]);
                                }).toList();
                              })(),
                            );
                          } else if (snapshot.hasError) {
                            child = const Text('Data belum ada');
                          } else {
                            child = const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(),
                            );
                          }
                          return child;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
