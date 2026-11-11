import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'api_service.dart';
import 'schedule_image_parser.dart';

class ScheduleImageRead {
  ScheduleImageRead(this.image, this.recognition);
  final Uint8List image;
  final ScheduleRecognition recognition;
}

class ScheduleOcr {
  Future<ScheduleImageRead?> pickAndRead() async {
    if (!Platform.isWindows)
      throw const ApiException('Đọc ảnh hiện hỗ trợ ứng dụng Windows.');
    final folder = await Directory.systemTemp.createTemp('attendance-ocr-');
    try {
      final script = File('${folder.path}/read_schedule.ps1');
      await script.writeAsString(
        await rootBundle.loadString('assets/scripts/read_schedule_ocr.ps1'),
      );
      // User-selected paths are never interpolated into a shell command.
      final process = await Process.start('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-STA',
        '-WindowStyle',
        'Hidden',
        '-File',
        script.path,
      ]);
      final output = process.stdout.transform(utf8.decoder).join();
      final errors = process.stderr.transform(utf8.decoder).join();
      final code = await process.exitCode.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          process.kill();
          throw const ApiException('Đọc ảnh quá thời gian. Vui lòng thử lại.');
        },
      );
      final stdout = await output;
      await errors;
      Json result;
      try {
        result = jsonDecode(stdout.trim().replaceFirst('\ufeff', '')) as Json;
      } catch (_) {
        throw const ApiException(
          'Không chạy được Windows OCR. Kiểm tra English OCR trong cài đặt ngôn ngữ Windows.',
        );
      }
      if (result['cancelled'] == true) return null;
      if (code != 0 || result['error'] != null)
        throw ApiException(
          'Windows OCR: ${result['error'] ?? 'Không đọc được ảnh'}',
        );
      final image = await File(result['path'] as String).readAsBytes();
      return ScheduleImageRead(image, ScheduleImageParser.parse(result));
    } finally {
      await folder.delete(recursive: true);
    }
  }
}
