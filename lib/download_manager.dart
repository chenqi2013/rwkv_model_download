/// 模型权重 & 词表文件
class RWKVModelFile {
  /// 模型权重 & 词表文件名称
  ///
  /// 作为 Key 值
  ///
  /// - 词库: `b_othello_vocab.txt`
  /// - ncnn 模型: `rwkv7_othello_26m_L10_D448_extended-ncnn.bin`
  /// - ncnn 模型配置: `rwkv7_othello_26m_L10_D448_extended-ncnn.param`
  /// - webgpu 模型: `rwkv7_othello_26m_L10_D448_extended.st`
  final String name;

  /// 文件大小, 以 bytes 为单位
  final int size;

  /// DEMO 名称
  ///
  /// 比如: "Othello", "Sudoku", "15puzzle", "Chat", etc
  final String demoName;

  /// 在沙盒中的路径, 供模型加载
  final String pathInSandbox;

  /// 我们应该更可以找 @Leo 要一下? 是在 HF 还是在 HF-mirror 上呢?
  final String remoteURL;

  final String md5;

  /// 下载完成时间
  final int downloadAt;

  const RWKVModelFile({
    required this.name,
    required this.demoName,
    required this.size,
    required this.pathInSandbox,
    required this.remoteURL,
    required this.md5,
    required this.downloadAt,
  });
}

enum RWKVDownloadTaskStatus {
  /// 下载完成
  complete,

  /// 取消下载
  canceled,

  /// 下载中
  running,

  /// 暂停下载
  paused,

  /// 下载失败
  fail,

  /// 开始解压
  unpressStart,

  /// 解压完成
  unpressFinish,
}

/// 下载进度
class RWKVDownloadStatus {
  /// 关联的文件
  final RWKVModelFile file;

  /// 下载进度, 0-100
  final int progress;

  /// 是否下载完成
  final bool isDone;

  const RWKVDownloadStatus({
    required this.file,
    required this.progress,
    required this.isDone,
  });
}

/// 下载管理类 API 需求
abstract class RWKVDownloadManager {
  /// 获取所有已下载的文件
  Future<List<RWKVModelFile>> getFiles();

  /// 获取正在进行的下载任务
  Future<List<Stream<RWKVDownloadStatus>>> getDownloadingTasks();

  /// 开始下载模型文件
  ///
  /// - [name] 文件名称, 如 `b_othello_vocab.txt`
  /// - [demoName] DEMO 名称, 如 `chat` / `othello` / `sudoku` / `15puzzle`
  /// - [refresh] 如果传入了刷新时间, 且本地下载好的文件, 其下载完成时间早于刷新时间, 则重新下载
  ///
  /// 如果调用该函数时, 对应的 demoName + name 任务已经存在, 则不开启新的下载任务, 返回正在进行中的 Stream
  ///
  /// 返回一个 Stream, 用于监听下载进度
  ///
  /// 当文件下载完成后, 返回一个 progress 为 100 的 DownloadTask, 代表已完成, 并关闭 Stream
  ///
  /// 如果文件已经下载好, 则直接返回一个 progress 为 100 的 DownloadTask, 代表已完成, 并关闭 Stream
  Future<Stream<RWKVDownloadStatus>> downloadFile({
    required String name,
    required String demoName,
    DateTime? refresh,
  });
}
