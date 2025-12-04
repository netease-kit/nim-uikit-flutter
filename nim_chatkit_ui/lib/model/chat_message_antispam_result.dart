// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

///反垃圾原因
const int pornography = 100; // 色情
const int advertising = 200; // 广告
const int adLawViolation = 260; // 广告法
const int violence = 300; // 暴恐
const int contraband = 400; // 违禁
const int political = 500; // 涉政
const int abuse = 600; // 谩骂
const int spam = 700; // 灌水
const int other = 900; // 其他
const int inappropriateValues = 1100; // 涉价值观

class AntispamResult {
  Ext? ext;
  int? code;
  int? suggestion;
  String? type;
  String? version;
  String? taskId;
  int? status;

  AntispamResult({
    this.ext,
    this.code,
    this.suggestion,
    this.type,
    this.version,
    this.taskId,
    this.status,
  });

  factory AntispamResult.fromJson(Map<String, dynamic> json) {
    return AntispamResult(
      // 特殊处理：ext 在原 JSON 中是字符串，需要二次解析
      ext: json['ext'] != null
          ? (json['ext'] is String
              ? Ext.fromJson(jsonDecode(json['ext']))
              : Ext.fromJson(json['ext']))
          : null,
      code: json['code'],
      suggestion: json['suggestion'],
      type: json['type'],
      version: json['version'],
      taskId: json['taskId'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (ext != null) {
      data['ext'] = ext!.toJson();
    }
    data['code'] = code;
    data['suggestion'] = suggestion;
    data['type'] = type;
    data['version'] = version;
    data['taskId'] = taskId;
    data['status'] = status;
    return data;
  }
}

class Ext {
  Antispam? antispam;
  Language? language;

  Ext({this.antispam, this.language});

  factory Ext.fromJson(Map<String, dynamic> json) {
    return Ext(
      antispam:
          json['antispam'] != null ? Antispam.fromJson(json['antispam']) : null,
      language:
          json['language'] != null ? Language.fromJson(json['language']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (antispam != null) {
      data['antispam'] = antispam!.toJson();
    }
    if (language != null) {
      data['language'] = language!.toJson();
    }
    return data;
  }
}

class Antispam {
  String? dataId;
  String? riskDescription;
  int? suggestion;
  int? censorType;
  bool? isRelatedHit;
  int? label;
  int? censorTime;
  String? secondLabel;
  int? resultType;
  String? taskId;
  int? hitSource;
  List<LabelItem>? labels;

  Antispam({
    this.dataId,
    this.riskDescription,
    this.suggestion,
    this.censorType,
    this.isRelatedHit,
    this.label,
    this.censorTime,
    this.secondLabel,
    this.resultType,
    this.taskId,
    this.hitSource,
    this.labels,
  });

  factory Antispam.fromJson(Map<String, dynamic> json) {
    return Antispam(
      dataId: json['dataId'],
      riskDescription: json['riskDescription'],
      suggestion: json['suggestion'],
      censorType: json['censorType'],
      isRelatedHit: json['isRelatedHit'],
      label: json['label'],
      censorTime: json['censorTime'],
      secondLabel: json['secondLabel'],
      resultType: json['resultType'],
      taskId: json['taskId'],
      hitSource: json['hitSource'],
      labels: json['labels'] != null
          ? (json['labels'] as List).map((i) => LabelItem.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dataId'] = dataId;
    data['riskDescription'] = riskDescription;
    data['suggestion'] = suggestion;
    data['censorType'] = censorType;
    data['isRelatedHit'] = isRelatedHit;
    data['label'] = label;
    data['censorTime'] = censorTime;
    data['secondLabel'] = secondLabel;
    data['resultType'] = resultType;
    data['taskId'] = taskId;
    data['hitSource'] = hitSource;
    if (labels != null) {
      data['labels'] = labels!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LabelItem {
  List<SubLabel>? subLabels;
  int? level;
  int? label;

  LabelItem({this.subLabels, this.level, this.label});

  factory LabelItem.fromJson(Map<String, dynamic> json) {
    return LabelItem(
      subLabels: json['subLabels'] != null
          ? (json['subLabels'] as List)
              .map((i) => SubLabel.fromJson(i))
              .toList()
          : null,
      level: json['level'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (subLabels != null) {
      data['subLabels'] = subLabels!.map((v) => v.toJson()).toList();
    }
    data['level'] = level;
    data['label'] = label;
    return data;
  }
}

class SubLabel {
  String? subLabel;
  String? riskDescription;
  Details? details;
  bool? isRelatedLabel;

  SubLabel({
    this.subLabel,
    this.riskDescription,
    this.details,
    this.isRelatedLabel,
  });

  factory SubLabel.fromJson(Map<String, dynamic> json) {
    return SubLabel(
      subLabel: json['subLabel'],
      riskDescription: json['riskDescription'],
      details:
          json['details'] != null ? Details.fromJson(json['details']) : null,
      isRelatedLabel: json['isRelatedLabel'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['subLabel'] = subLabel;
    data['riskDescription'] = riskDescription;
    if (details != null) {
      data['details'] = details!.toJson();
    }
    data['isRelatedLabel'] = isRelatedLabel;
    return data;
  }
}

class Details {
  List<HitInfo>? hitInfos;

  Details({this.hitInfos});

  factory Details.fromJson(Map<String, dynamic> json) {
    return Details(
      hitInfos: json['hitInfos'] != null
          ? (json['hitInfos'] as List).map((i) => HitInfo.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (hitInfos != null) {
      data['hitInfos'] = hitInfos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HitInfo {
  List<Position>? positions;
  String? value;

  HitInfo({this.positions, this.value});

  factory HitInfo.fromJson(Map<String, dynamic> json) {
    return HitInfo(
      positions: json['positions'] != null
          ? (json['positions'] as List)
              .map((i) => Position.fromJson(i))
              .toList()
          : null,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (positions != null) {
      data['positions'] = positions!.map((v) => v.toJson()).toList();
    }
    data['value'] = value;
    return data;
  }
}

class Position {
  String? fieldName;
  int? startPos;
  int? endPos;

  Position({this.fieldName, this.startPos, this.endPos});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      fieldName: json['fieldName'],
      startPos: json['startPos'],
      endPos: json['endPos'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fieldName'] = fieldName;
    data['startPos'] = startPos;
    data['endPos'] = endPos;
    return data;
  }
}

class Language {
  String? dataId;
  List<LanguageDetail>? details;
  String? taskId;

  Language({this.dataId, this.details, this.taskId});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      dataId: json['dataId'],
      details: json['details'] != null
          ? (json['details'] as List)
              .map((i) => LanguageDetail.fromJson(i))
              .toList()
          : null,
      taskId: json['taskId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dataId'] = dataId;
    if (details != null) {
      data['details'] = details!.map((v) => v.toJson()).toList();
    }
    data['taskId'] = taskId;
    return data;
  }
}

class LanguageDetail {
  String? type;

  LanguageDetail({this.type});

  factory LanguageDetail.fromJson(Map<String, dynamic> json) {
    return LanguageDetail(
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    return data;
  }
}
