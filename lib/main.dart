import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const BooksApp());

class BooksApp extends StatelessWidget {
  const BooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142B4A);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كتب ومصادر اللغة الإنجليزية',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const BooksScreen(),
    );
  }
}

class BookItem {
  const BookItem({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.fileName,
  });

  final String title;
  final String subtitle;
  final String url;
  final String fileName;
}

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final Dio _dio = Dio();
  final Map<int, double> _progress = {};
  final Map<int, bool> _downloading = {};
  final Map<int, CancelToken> _cancelTokens = {};
  final Map<int, String> _downloadedPaths = {};

  static const List<BookItem> books = [
    BookItem(title: 'كتاب الأدب', subtitle: 'Literature', url: 'https://files.catbox.moe/2eug5u.pdf', fileName: 'Literature.pdf'),
    BookItem(title: 'كتاب حقوق الإنسان', subtitle: 'Human Rights', url: 'https://files.catbox.moe/t5dy8v.pdf', fileName: 'Human_Rights.pdf'),
    BookItem(title: 'كتاب الصوت', subtitle: 'Phonetics', url: 'https://files.catbox.moe/y83yk4.pdf', fileName: 'Phonetics.pdf'),
    BookItem(title: 'كتاب القراءة', subtitle: 'Select Readings', url: 'https://files.catbox.moe/t98rc2.pdf', fileName: 'Select_Readings.pdf'),
    BookItem(title: 'كتاب الكتابة', subtitle: 'Writing in Paragraphs', url: 'https://files.catbox.moe/g5ajzz.pdf', fileName: 'Writing_in_Paragraphs.pdf'),
    BookItem(title: 'كتاب القواعد', subtitle: 'Grammar in Use', url: 'https://files.catbox.moe/0xp0df.pdf', fileName: 'Grammar_in_Use.pdf'),
    BookItem(title: 'كتاب الاستماع الأول', subtitle: 'Listening 1', url: 'https://files.catbox.moe/9gqupj.pdf', fileName: 'Listening_1.pdf'),
    BookItem(title: 'كتاب الاستماع الثاني', subtitle: 'Listening 2', url: 'https://files.catbox.moe/3shiiy.pdf', fileName: 'Listening_2.pdf'),
  ];

  Future<Directory> _downloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) return dir;
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> _downloadOrOpen(int index) async {
    final book = books[index];
    final existingPath = _downloadedPaths[index];

    if (existingPath != null && await File(existingPath).exists()) {
      await OpenFile.open(existingPath);
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[index] = cancelToken;
    setState(() {
      _downloading[index] = true;
      _progress[index] = 0;
    });

    try {
      final directory = await _downloadDirectory();
      final savePath = '${directory.path}/${book.fileName}';

      await _dio.download(
        book.url,
        savePath,
        cancelToken: cancelToken,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(minutes: 3),
        ),
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress[index] = total > 0 ? received / total : 0;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _downloadedPaths[index] = savePath;
        _downloading[index] = false;
        _progress[index] = 1;
      });
      await OpenFile.open(savePath);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _downloading[index] = false);
      if (CancelToken.isCancel(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إيقاف التحميل')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تحميل الكتاب. تحقق من الإنترنت وحاول مجدداً.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloading[index] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء فتح الكتاب أو تحميله')),
      );
    } finally {
      _cancelTokens.remove(index);
    }
  }

  void _cancelDownload(int index) {
    _cancelTokens[index]?.cancel('Cancelled by user');
    if (mounted) setState(() => _downloading[index] = false);
  }

  @override
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('Screen disposed');
    }
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كتب المرحلة الأولى', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مكتبتك الدراسية', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('حمّل كتب المرحلة الأولى وافتحها بصيغة PDF', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text('المصادر الدراسية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF142B4A))),
                  const Spacer(),
                  Text('${books.length} كتب', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final book = books[index];
                  final downloading = _downloading[index] ?? false;
                  final progress = _progress[index] ?? 0;
                  final downloaded = _downloadedPaths.containsKey(index);

                  return Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7ECF4)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE5484D), size: 29),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF172B4D))),
                              const SizedBox(height: 3),
                              Text(book.subtitle, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                              if (downloading) ...[
                                const SizedBox(height: 9),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    minHeight: 5,
                                    backgroundColor: const Color(0xFFE9EEF6),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : 'جارٍ التحميل...',
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                              ] else if (downloaded) ...[
                                const SizedBox(height: 4),
                                const Text('تم التحميل • اضغط للفتح', style: TextStyle(fontSize: 10, color: Colors.green)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: downloading ? 'إيقاف التحميل' : downloaded ? 'فتح الكتاب' : 'تحميل الكتاب',
                          onPressed: downloading ? () => _cancelDownload(index) : () => _downloadOrOpen(index),
                          style: IconButton.styleFrom(
                            backgroundColor: downloading ? const Color(0xFFFFE8E8) : const Color(0xFFEAF1FF),
                            foregroundColor: downloading ? Colors.red : const Color(0xFF2563EB),
                          ),
                          icon: Icon(downloading ? Icons.close_rounded : downloaded ? Icons.menu_book_rounded : Icons.download_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
