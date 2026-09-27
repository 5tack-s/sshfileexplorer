enum FileType { video, image, text, audio }

class File {
  final String path;
  late final dynamic data; //literally anything its data cast properly later
  final FileType type;

  File({required this.path, required this.type, required this.data});
  bool get isVideo => type == FileType.video;
  bool get isImage => type == FileType.image;
  bool get isText => type == FileType.text;
  bool get isAudio => type == FileType.audio;
}
