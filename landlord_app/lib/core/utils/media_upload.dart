import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

Future<MultipartFile> multipartFromXFile(
  XFile file, {
  required bool isVideo,
}) async {
  final bytes = await file.readAsBytes();
  final filename = file.name.isEmpty
      ? (isVideo ? 'listing_video.mp4' : 'listing_image.jpg')
      : file.name;

  return MultipartFile.fromBytes(
    bytes,
    filename: filename,
    contentType: MediaType.parse(_mediaType(filename, isVideo: isVideo)),
  );
}

String _mediaType(String filename, {required bool isVideo}) {
  final extension = filename.split('.').last.toLowerCase();
  const imageTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
  };
  const videoTypes = {
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4v': 'video/x-m4v',
    'webm': 'video/webm',
    'avi': 'video/x-msvideo',
  };

  return (isVideo ? videoTypes[extension] : imageTypes[extension]) ??
      (isVideo ? 'video/mp4' : 'image/jpeg');
}

class XFileImagePreview extends StatelessWidget {
  final XFile file;
  final BoxFit fit;

  const XFileImagePreview({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(snapshot.data!, fit: fit);
      },
    );
  }
}
