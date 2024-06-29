class ArchiveData {
  int count;
  String desc;
  int endTime;
  int startTime;
  bool isTop;

  ArchiveData({
    required this.count,
    required this.desc,
    required this.endTime,
    required this.startTime,
    this.isTop = false,
  });

  factory ArchiveData.fromJson(Map<String, dynamic> json) {
    return ArchiveData(
      count: json['count'],
      desc: json['desc'],
      endTime: json['endTime'],
      startTime: json['startTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'desc': desc,
      'endTime': endTime,
      'startTime': startTime,
    };
  }

  @override
  String toString() {
    return 'ArchiveData{count: $count, desc: $desc, endTime: $endTime, startTime: $startTime}';
  }
}

class ArchiveItem {
  int year;
  List<int> monthCount;

  //构造函数
  ArchiveItem({
    required this.year,
    required this.monthCount,
  });

  //工厂方法
  factory ArchiveItem.fromJson(Map<String, dynamic> json) {
    return ArchiveItem(
      year: json['year'],
      monthCount: (json['monthCount'] as List).map((e) => e as int).toList(),
    );
  }

  //toJson方法
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'monthCount': monthCount,
    };
  }

  //toString方法
  @override
  String toString() {
    return 'ArchiveItem{year: $year, monthCount: $monthCount}';
  }
}
