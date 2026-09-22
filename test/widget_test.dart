import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab1/controllers/audit_controller.dart';
import 'package:prm323_lab1/models/audit_result_item.dart';
import 'package:prm323_lab1/models/citation.dart';
import 'package:prm323_lab1/models/enums.dart';
import 'package:prm323_lab1/screens/home_screen.dart';
import 'package:prm323_lab1/services/backend_audit_service.dart';
import 'package:prm323_lab1/services/document_service.dart';

void main() {
  test('Rejects non-PDF input', () async {
    for (final name in ['notes.txt', 'report.json']) {
      await expectLater(
        DocumentService().fromPickedFile(_MemoryPdf(name, Uint8List(0))),
        throwsFormatException,
      );
    }
  });

  test('Cancel during file selection returns the workspace to a cancelled state', () async {
    final documents = _DelayedDocuments();
    final controller = AuditController(documents: documents);
    addTearDown(controller.dispose);

    final run = controller.importPickedFile();
    expect(controller.busy, isTrue);
    controller.cancel();
    documents.complete(null);
    await run;

    expect(controller.busy, isFalse);
    expect(controller.progress.phase, 'cancelled');
  });

  testWidgets('Upload enables an explicit analysis step', (tester) async {
    final bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);
    final documents = _PdfDocuments(_MemoryPdf('paper.PDF', bytes));
    final controller = AuditController(
      documents: documents,
      backend: _FakeBackend(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: controller)),
    );
    expect(find.text('Dán citation'), findsNothing);
    await tester.tap(find.text('Import PDF'));
    await tester.pumpAndSettle();
    expect(controller.errorMessage, isNull);
    expect(controller.sourceLabel, contains('paper.PDF'));
    expect(controller.report, isNull);
    expect(controller.readyToAnalyze, isTrue);
    await tester.tap(find.text('Bắt đầu phân tích'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.workingItems, isNotEmpty);
    expect(controller.report, isNotNull);
    expect(find.text('Danh sách trích dẫn'), findsOneWidget);
    expect(find.text('Xuất JSON'), findsOneWidget);

    documents.next = null;
    final previousItems = controller.workingItems;
    await tester.tap(find.text('Import PDF'));
    await tester.pumpAndSettle();
    expect(controller.workingItems, same(previousItems));
    expect(controller.busy, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _PdfDocuments extends DocumentService {
  PlatformFile? next;
  _PdfDocuments(this.next);
  @override
  Future<PlatformFile?> pickDocument() async => next;
}

class _DelayedDocuments extends DocumentService {
  final _picked = Completer<PlatformFile?>();

  @override
  Future<PlatformFile?> pickDocument() => _picked.future;

  void complete(PlatformFile? file) => _picked.complete(file);
}

class _FakeBackend extends BackendAuditService {
  @override
  Future<BackendUpload> upload({
    required String filename,
    required Uint8List bytes,
    required void Function(String phase, String message) onProgress,
  }) async {
    onProgress('uploading', 'Đang gửi PDF tới máy chủ…');
    return BackendUpload(documentId: 'test-document', filename: filename);
  }

  @override
  Future<BackendRunResult> analyze({
    required BackendUpload upload,
    required void Function(String phase, String message) onProgress,
  }) async {
    onProgress('analyzing', 'Máy chủ đang phân tích…');
    return BackendRunResult(
      sourceLabel: upload.filename,
      items: const [
        AuditResultItem(
          index: 0,
          citation: 'A. Nguyen. Example Paper. 2024.',
          pred: true,
          processingState: ProcessingState.completed,
          status: VerificationStatus.verified,
          method: 'fastapi_crossref',
          reason: 'Thông tin khớp với nguồn Crossref.',
          metadata: CitationMetadata(
            index: 0,
            raw: 'A. Nguyen. Example Paper. 2024.',
            title: 'Example Paper',
            year: '2024',
            metadataMethod: 'fastapi',
          ),
        ),
      ],
    );
  }
}

final class _MemoryPdf extends PlatformFile {
  @override
  final String name;
  final Uint8List bytes;
  _MemoryPdf(this.name, this.bytes);
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
