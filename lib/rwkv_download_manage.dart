import 'dart:io';
// import 'dart:isolate';

// import 'package:archive/archive_io.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:rwkv_model_download/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:isolated_download_manager/isolated_download_manager.dart';
import 'package:path_provider/path_provider.dart';

class RWKVDownloadManage {
  // final ReceivePort _port = ReceivePort();

  static void pingDomain() {
    final ping = Ping('https://www.baidu.com', count: 5);
    ping.stream.listen((event) {
      debugPrint('event==${event.toString()}');
    });
  }

  // static void downloadFile33(String downloadurl) async {
  //   String downloadPath = await getCachePath();
  //   await DownloadManager.instance.init(
  //     isolates: 3,
  //   );

  //   Uri uri = Uri.parse(downloadurl);
  //   var name = uri.pathSegments.last;
  //   debugPrint('file name=$name');
  //   var request = DownloadManager.instance
  //       .download(downloadurl, path: '$downloadPath/$name');

  //   request.events.listen((event) {
  //     if (event is DownloadState) {
  //       debugPrint("event: $event");
  //       if (event == DownloadState.started) {
  //         // progressStatus(DownloadStatus.start, 0);
  //       } else if (event == DownloadState.finished) {
  //         debugPrint('finished');
  //         // CommonUtils.setIsdownload(true);
  //         // progressStatus(DownloadStatus.finish, 1.0);
  //       }
  //     } else if (event is double) {
  //       // progress.value = event;
  //       debugPrint("progress: ${(event * 100.0).toStringAsFixed(0)}%");
  //       // progressStatus(DownloadStatus.downloading, event);
  //     }
  //   }, onError: (error) {
  //     debugPrint("error $error");
  //     // progressStatus(DownloadStatus.fail, -1);
  //   });
  // }

  static Future<String> getCachePath() async {
    String tempDirPath = '';
    try {
      Directory tempDir = await getApplicationCacheDirectory();
      tempDirPath = tempDir.path;
    } catch (e) {
      debugPrint('Error getCachePath: $e');
    }
    return tempDirPath;
  }

  static void downloadFile(
      String downloadUrl,
      Function(double progress, RWKVDownloadTaskStatus status, String? path)
          callBack) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachePath;
    cachePath = prefs.getString(downloadUrl);
    if (cachePath != null && cachePath.isNotEmpty) {
      callBack(1.0, RWKVDownloadTaskStatus.unpressFinish, cachePath);
      return;
    }
    cachePath = await getCachePath();
    Uri uri = Uri.parse(downloadUrl);
    var name = uri.pathSegments.last;
    String fileNameWithoutExtension = name.replaceAll(RegExp(r'\.\w+$'), '');

    debugPrint('file name=$name');
    final task = DownloadTask(
      url: downloadUrl,
      filename: name,
      headers: {
        'x-api-key':
            '4s5aWqs2f4PzKfgLjuRZgXKvvmal5Z5iq0OzkTPwaA2axgNgSbayfQEX5FgOpTxyyeUM4gsFHHDZroaFDIE3NtSJD6evdz3lAVctyN026keeXMoJ7tmUy5zriMJHJ9aM'
      },
      baseDirectory: BaseDirectory.applicationLibrary,
      updates: Updates.statusAndProgress, // request status and progress updates
      requiresWiFi: true,
      retries: 2,
      allowPause: true,
      httpRequestMethod: 'GET',
    );

    String taskId = task.taskId;
    debugPrint('taskId==$taskId');
    double progress = 0.0;
    final result = await FileDownloader().download(
      task,
      onProgress: (progressTmp) {
        progress = progressTmp;
        callBack(progress, RWKVDownloadTaskStatus.running, null);
      },
      onStatus: (status) {
        debugPrint('Status: $status');
        if (status == TaskStatus.failed) {
          callBack(progress, RWKVDownloadTaskStatus.fail, null);
        }
      },
    );

    switch (result.status) {
      case TaskStatus.complete:
        {
          String path = await result.task.filePath();
          debugPrint('Success path=$path');
          callBack(progress, RWKVDownloadTaskStatus.complete, path);
          callBack(progress, RWKVDownloadTaskStatus.unpressStart, path);
          // await extractFileToDisk(
          //   path,
          //   cachePath,
          //   callback: (ArchiveFile entry) {
          //     debugPrint('depress=${entry.size}');
          //   },
          // );
          await unzipFile(path, cachePath);
          callBack(progress, RWKVDownloadTaskStatus.unpressFinish,
              '$cachePath/$fileNameWithoutExtension');

// Save an integer value to 'counter' key.
          await prefs.setString(
              downloadUrl, '$cachePath/$fileNameWithoutExtension');
          File(path).delete();
          // debugPrint('extractFileToDisk success');
        }

      case TaskStatus.canceled:
        callBack(progress, RWKVDownloadTaskStatus.canceled, null);

      case TaskStatus.paused:
        callBack(progress, RWKVDownloadTaskStatus.paused, null);

      default:
        callBack(progress, RWKVDownloadTaskStatus.fail, null);
    }
  }

//   static void downloadFile22(String downloadurl) async {
//     // Use .download to start a download and wait for it to complete

// // define the download task (subset of parameters shown)

//     String downloadPath = await getCachePath();

//     Uri uri = Uri.parse(downloadurl);
//     var name = uri.pathSegments.last;
//     debugPrint('file name=$name');

//     final taskId = await FlutterDownloader.enqueue(
//       url: downloadurl,
//       headers: {}, // optional: header send with url (auth token etc)
//       savedDir: downloadPath,
//       showNotification:
//           true, // show download progress in status bar (for Android)
//       openFileFromNotification:
//           true, // click on notification to open downloaded file (for Android)
//     );

//     await FlutterDownloader.registerCallback(downloadCallback);
//   }

  static void downloadCallback(String id, int status, int progress) {
    // final SendPort? send =
    //     IsolateNameServer.lookupPortByName('downloader_send_port');
    // send?.send([id, status, progress]);
    debugPrint('id==$id,status==$status,status==$progress');
  }

  Future<bool> directoryExists(String path) async {
    final directory = Directory(path);
    return await directory.exists();
  }

  static Future<void> unzipFile(String zipPath, String destiPath) async {
    final zipFile = File(zipPath);
    final destiDirectory = Directory(destiPath);
    await ZipFile.extractToDirectory(
      zipFile: zipFile,
      destinationDir: destiDirectory,
      onExtracting: (zipEntry, progress) {
        debugPrint('progress:${progress.toStringAsFixed(1)}%');
        debugPrint('uncompressSize=${zipEntry.uncompressedSize}');
        debugPrint('compressSize=${zipEntry.compressedSize}');
        return ZipFileOperation.includeItem;
      },
    );

    debugPrint('unzipfile success');
  }
}
