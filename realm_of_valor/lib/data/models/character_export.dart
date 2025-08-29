import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'character_classes.dart';
import 'character_achievements.dart';
import 'multi_character.dart';

enum ExportFormat {
  json,
  xml,
  csv,
  binary,
  compressed,
}

enum ExportType {
  full,
  build,
  stats,
  achievements,
  equipment,
  skills,
  custom,
}

enum ImportValidationResult {
  valid,
  invalid_format,
  corrupted_data,
  version_mismatch,
  missing_required_fields,
  incompatible_version,
}

class CharacterExportData extends Equatable {
  final String id;
  final String characterId;
  final String characterName;
  final ExportType type;
  final ExportFormat format;
  final String version;
  final DateTime exportDate;
  final String exportedBy;
  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;
  final String? description;
  final List<String> tags;
  final bool isPublic;
  final bool isVerified;

  const CharacterExportData({
    required this.id,
    required this.characterId,
    required this.characterName,
    required this.type,
    required this.format,
    required this.version,
    required this.exportDate,
    required this.exportedBy,
    required this.data,
    required this.metadata,
    this.description,
    required this.tags,
    this.isPublic = false,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
    id,
    characterId,
    characterName,
    type,
    format,
    version,
    exportDate,
    exportedBy,
    data,
    metadata,
    description,
    tags,
    isPublic,
    isVerified,
  ];
}

class CharacterBuild extends Equatable {
  final String id;
  final String name;
  final String description;
  final CharacterClass characterClass;
  final ClassSpecialization? specialization;
  final List<String> skills;
  final Map<String, int> skillLevels;
  final Map<String, dynamic> equipment;
  final Map<String, int> stats;
  final List<String> achievements;
  final List<String> titles;
  final String? equippedTitle;
  final DateTime creationDate;
  final DateTime lastModifiedDate;
  final String createdBy;
  final List<String> tags;
  final bool isPublic;
  final int rating;
  final int downloads;
  final String? buildNotes;

  const CharacterBuild({
    required this.id,
    required this.name,
    required this.description,
    required this.characterClass,
    this.specialization,
    required this.skills,
    required this.skillLevels,
    required this.equipment,
    required this.stats,
    required this.achievements,
    required this.titles,
    this.equippedTitle,
    required this.creationDate,
    required this.lastModifiedDate,
    required this.createdBy,
    required this.tags,
    this.isPublic = false,
    this.rating = 0,
    this.downloads = 0,
    this.buildNotes,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    characterClass,
    specialization,
    skills,
    skillLevels,
    equipment,
    stats,
    achievements,
    titles,
    equippedTitle,
    creationDate,
    lastModifiedDate,
    createdBy,
    tags,
    isPublic,
    rating,
    downloads,
    buildNotes,
  ];
}

class ImportResult extends Equatable {
  final bool success;
  final ImportValidationResult validationResult;
  final String? errorMessage;
  final CharacterProfile? importedCharacter;
  final Map<String, dynamic>? importedData;
  final List<String> warnings;

  const ImportResult({
    required this.success,
    required this.validationResult,
    this.errorMessage,
    this.importedCharacter,
    this.importedData,
    required this.warnings,
  });

  @override
  List<Object?> get props => [
    success,
    validationResult,
    errorMessage,
    importedCharacter,
    importedData,
    warnings,
  ];
}

class CharacterExportService {
  static const String currentVersion = '1.0.0';
  static const List<String> supportedVersions = ['1.0.0', '0.9.0', '0.8.0'];

  static CharacterExportData exportCharacter({
    required CharacterProfile character,
    required ExportType type,
    required ExportFormat format,
    required String exportedBy,
    String? description,
    List<String>? tags,
    bool isPublic = false,
  }) {
    final data = <String, dynamic>{};
    final metadata = <String, dynamic>{};

    switch (type) {
      case ExportType.full:
        data['character'] = _serializeCharacter(character);
        data['build'] = _createBuildFromCharacter(character);
        break;
      case ExportType.build:
        data['build'] = _createBuildFromCharacter(character);
        break;
      case ExportType.stats:
        data['stats'] = character.stats;
        data['level'] = character.level;
        data['experience'] = character.experience;
        break;
      case ExportType.achievements:
        data['achievements'] = character.achievements;
        data['titles'] = character.titles;
        data['equipped_title'] = character.equippedTitle;
        break;
      case ExportType.equipment:
        data['equipment'] = character.characterData['equipment'] ?? {};
        break;
      case ExportType.skills:
        data['skills'] = character.unlockedSkills;
        data['skill_mastery'] = character.skillMastery;
        break;
      case ExportType.custom:
        // Custom export - user defines what to include
        data['custom_data'] = character.characterData;
        break;
    }

    metadata['export_type'] = type.name;
    metadata['export_format'] = format.name;
    metadata['character_class'] = character.characterClass.name;
    metadata['character_level'] = character.level;
    metadata['specialization'] = character.specialization?.name;

    return CharacterExportData(
      id: 'export_${DateTime.now().millisecondsSinceEpoch}',
      characterId: character.id,
      characterName: character.name,
      type: type,
      format: format,
      version: currentVersion,
      exportDate: DateTime.now(),
      exportedBy: exportedBy,
      data: data,
      metadata: metadata,
      description: description,
      tags: tags ?? [],
      isPublic: isPublic,
    );
  }

  static String serializeExport(CharacterExportData exportData) {
    switch (exportData.format) {
      case ExportFormat.json:
        return jsonEncode({
          'id': exportData.id,
          'character_id': exportData.characterId,
          'character_name': exportData.characterName,
          'type': exportData.type.name,
          'format': exportData.format.name,
          'version': exportData.version,
          'export_date': exportData.exportDate.toIso8601String(),
          'exported_by': exportData.exportedBy,
          'data': exportData.data,
          'metadata': exportData.metadata,
          'description': exportData.description,
          'tags': exportData.tags,
          'is_public': exportData.isPublic,
          'is_verified': exportData.isVerified,
        });
      case ExportFormat.xml:
        return _serializeToXml(exportData);
      case ExportFormat.csv:
        return _serializeToCsv(exportData);
      case ExportFormat.binary:
        return _serializeToBinary(exportData);
      case ExportFormat.compressed:
        return _serializeToCompressed(exportData);
    }
  }

  static ImportResult importCharacter(String serializedData, ExportFormat format) {
    try {
      final exportData = _deserializeExport(serializedData, format);
      
      // Validate the export data
      final validationResult = _validateExportData(exportData);
      if (validationResult != ImportValidationResult.valid) {
        return ImportResult(
          success: false,
          validationResult: validationResult,
          errorMessage: 'Invalid export data: ${validationResult.name}',
          warnings: [],
        );
      }

      // Import based on type
      switch (exportData.type) {
        case ExportType.full:
          return _importFullCharacter(exportData);
        case ExportType.build:
          return _importBuild(exportData);
        case ExportType.stats:
          return _importStats(exportData);
        case ExportType.achievements:
          return _importAchievements(exportData);
        case ExportType.equipment:
          return _importEquipment(exportData);
        case ExportType.skills:
          return _importSkills(exportData);
        case ExportType.custom:
          return _importCustomData(exportData);
      }
    } catch (e) {
      return ImportResult(
        success: false,
        validationResult: ImportValidationResult.corrupted_data,
        errorMessage: 'Failed to import: $e',
        warnings: [],
      );
    }
  }

  static CharacterBuild createBuild({
    required String name,
    required String description,
    required CharacterProfile character,
    String? buildNotes,
    List<String>? tags,
    bool isPublic = false,
  }) {
    return CharacterBuild(
      id: 'build_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      characterClass: character.characterClass,
      specialization: character.specialization,
      skills: character.unlockedSkills,
      skillLevels: character.skillMastery,
      equipment: character.characterData['equipment'] ?? {},
      stats: character.stats,
      achievements: character.achievements,
      titles: character.titles,
      equippedTitle: character.equippedTitle,
      creationDate: DateTime.now(),
      lastModifiedDate: DateTime.now(),
      createdBy: character.id,
      tags: tags ?? [],
      isPublic: isPublic,
      buildNotes: buildNotes,
    );
  }

  static CharacterProfile applyBuild(CharacterProfile character, CharacterBuild build) {
    return CharacterProfile(
      id: character.id,
      name: character.name,
      description: character.description,
      characterClass: build.characterClass,
      specialization: build.specialization,
      level: character.level,
      experience: character.experience,
      stats: build.stats,
      unlockedSkills: build.skills,
      skillMastery: build.skillLevels,
      achievements: character.achievements,
      titles: character.titles,
      equippedTitle: build.equippedTitle,
      creationDate: character.creationDate,
      lastLoginDate: DateTime.now(),
      playTime: character.playTime,
      characterData: {
        ...character.characterData,
        'equipment': build.equipment,
        'applied_build': build.id,
        'build_application_date': DateTime.now().toIso8601String(),
      },
    );
  }

  static Map<String, dynamic> _serializeCharacter(CharacterProfile character) {
    return {
      'id': character.id,
      'name': character.name,
      'description': character.description,
      'character_class': character.characterClass.name,
      'specialization': character.specialization?.name,
      'level': character.level,
      'experience': character.experience,
      'stats': character.stats,
      'unlocked_skills': character.unlockedSkills,
      'skill_mastery': character.skillMastery,
      'achievements': character.achievements,
      'titles': character.titles,
      'equipped_title': character.equippedTitle,
      'creation_date': character.creationDate.toIso8601String(),
      'last_login_date': character.lastLoginDate.toIso8601String(),
      'play_time': character.playTime,
      'character_data': character.characterData,
    };
  }

  static CharacterBuild _createBuildFromCharacter(CharacterProfile character) {
    return CharacterBuild(
      id: 'build_${DateTime.now().millisecondsSinceEpoch}',
      name: '${character.name}\'s Build',
      description: 'Build exported from ${character.name}',
      characterClass: character.characterClass,
      specialization: character.specialization,
      skills: character.unlockedSkills,
      skillLevels: character.skillMastery,
      equipment: character.characterData['equipment'] ?? {},
      stats: character.stats,
      achievements: character.achievements,
      titles: character.titles,
      equippedTitle: character.equippedTitle,
      creationDate: DateTime.now(),
      lastModifiedDate: DateTime.now(),
      createdBy: character.id,
      tags: [],
      isPublic: false,
    );
  }

  static String _serializeToXml(CharacterExportData exportData) {
    // Simplified XML serialization
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<character_export>');
    buffer.writeln('  <id>${exportData.id}</id>');
    buffer.writeln('  <character_name>${exportData.characterName}</character_name>');
    buffer.writeln('  <type>${exportData.type.name}</type>');
    buffer.writeln('  <version>${exportData.version}</version>');
    buffer.writeln('  <export_date>${exportData.exportDate.toIso8601String()}</export_date>');
    buffer.writeln('  <data>');
    buffer.writeln('    ${jsonEncode(exportData.data)}');
    buffer.writeln('  </data>');
    buffer.writeln('</character_export>');
    return buffer.toString();
  }

  static String _serializeToCsv(CharacterExportData exportData) {
    // Simplified CSV serialization
    final buffer = StringBuffer();
    buffer.writeln('id,character_name,type,version,export_date');
    buffer.writeln('${exportData.id},${exportData.characterName},${exportData.type.name},${exportData.version},${exportData.exportDate.toIso8601String()}');
    return buffer.toString();
  }

  static String _serializeToBinary(CharacterExportData exportData) {
    // Simplified binary serialization (base64 encoded)
    final jsonData = jsonEncode(exportData.data);
    return base64Encode(utf8.encode(jsonData));
  }

  static String _serializeToCompressed(CharacterExportData exportData) {
    // Simplified compression (base64 encoded with compression marker)
    final jsonData = jsonEncode(exportData.data);
    return 'COMPRESSED:${base64Encode(utf8.encode(jsonData))}';
  }

  static CharacterExportData _deserializeExport(String data, ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        final json = jsonDecode(data);
        return CharacterExportData(
          id: json['id'],
          characterId: json['character_id'],
          characterName: json['character_name'],
          type: ExportType.values.firstWhere((e) => e.name == json['type']),
          format: ExportFormat.values.firstWhere((e) => e.name == json['format']),
          version: json['version'],
          exportDate: DateTime.parse(json['export_date']),
          exportedBy: json['exported_by'],
          data: json['data'],
          metadata: json['metadata'] ?? {},
          description: json['description'],
          tags: List<String>.from(json['tags'] ?? []),
          isPublic: json['is_public'] ?? false,
          isVerified: json['is_verified'] ?? false,
        );
      case ExportFormat.xml:
        return _deserializeFromXml(data);
      case ExportFormat.csv:
        return _deserializeFromCsv(data);
      case ExportFormat.binary:
        return _deserializeFromBinary(data);
      case ExportFormat.compressed:
        return _deserializeFromCompressed(data);
    }
  }

  static CharacterExportData _deserializeFromXml(String data) {
    // Simplified XML deserialization
    final lines = data.split('\n');
    final id = lines[2].replaceAll('<id>', '').replaceAll('</id>', '').trim();
    final characterName = lines[3].replaceAll('<character_name>', '').replaceAll('</character_name>', '').trim();
    final type = lines[4].replaceAll('<type>', '').replaceAll('</type>', '').trim();
    final version = lines[5].replaceAll('<version>', '').replaceAll('</version>', '').trim();
    final exportDate = lines[6].replaceAll('<export_date>', '').replaceAll('</export_date>', '').trim();
    final dataJson = lines[8].trim();
    
    return CharacterExportData(
      id: id,
      characterId: 'imported_$id',
      characterName: characterName,
      type: ExportType.values.firstWhere((e) => e.name == type),
      format: ExportFormat.xml,
      version: version,
      exportDate: DateTime.parse(exportDate),
      exportedBy: 'imported',
      data: jsonDecode(dataJson),
      metadata: {},
      tags: [],
    );
  }

  static CharacterExportData _deserializeFromCsv(String data) {
    // Simplified CSV deserialization
    final lines = data.split('\n');
    final values = lines[1].split(',');
    
    return CharacterExportData(
      id: values[0],
      characterId: 'imported_${values[0]}',
      characterName: values[1],
      type: ExportType.values.firstWhere((e) => e.name == values[2]),
      format: ExportFormat.csv,
      version: values[3],
      exportDate: DateTime.parse(values[4]),
      exportedBy: 'imported',
      data: {},
      metadata: {},
      tags: [],
    );
  }

  static CharacterExportData _deserializeFromBinary(String data) {
    // Simplified binary deserialization
    final decoded = utf8.decode(base64Decode(data));
    final jsonData = jsonDecode(decoded);
    
    return CharacterExportData(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      characterId: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      characterName: 'Imported Character',
      type: ExportType.custom,
      format: ExportFormat.binary,
      version: currentVersion,
      exportDate: DateTime.now(),
      exportedBy: 'imported',
      data: jsonData,
      metadata: {},
      tags: [],
    );
  }

  static CharacterExportData _deserializeFromCompressed(String data) {
    // Simplified compressed deserialization
    final compressedData = data.replaceFirst('COMPRESSED:', '');
    final decoded = utf8.decode(base64Decode(compressedData));
    final jsonData = jsonDecode(decoded);
    
    return CharacterExportData(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      characterId: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      characterName: 'Imported Character',
      type: ExportType.custom,
      format: ExportFormat.compressed,
      version: currentVersion,
      exportDate: DateTime.now(),
      exportedBy: 'imported',
      data: jsonData,
      metadata: {},
      tags: [],
    );
  }

  static ImportValidationResult _validateExportData(CharacterExportData exportData) {
    // Check version compatibility
    if (!supportedVersions.contains(exportData.version)) {
      return ImportValidationResult.version_mismatch;
    }

    // Check required fields
    if (exportData.characterName.isEmpty || exportData.data.isEmpty) {
      return ImportValidationResult.missing_required_fields;
    }

    // Check data integrity
    try {
      jsonEncode(exportData.data);
    } catch (e) {
      return ImportValidationResult.corrupted_data;
    }

    return ImportValidationResult.valid;
  }

  static ImportResult _importFullCharacter(CharacterExportData exportData) {
    try {
      final characterData = exportData.data['character'] as Map<String, dynamic>;
      
      final character = CharacterProfile(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        name: characterData['name'],
        description: characterData['description'],
        characterClass: CharacterClass.values.firstWhere((c) => c.name == characterData['character_class']),
        specialization: characterData['specialization'] != null 
            ? ClassSpecialization.values.firstWhere((s) => s.name == characterData['specialization'])
            : null,
        level: characterData['level'],
        experience: characterData['experience'],
        stats: Map<String, int>.from(characterData['stats']),
        unlockedSkills: List<String>.from(characterData['unlocked_skills']),
        skillMastery: Map<String, int>.from(characterData['skill_mastery']),
        achievements: List<String>.from(characterData['achievements']),
        titles: List<String>.from(characterData['titles']),
        equippedTitle: characterData['equipped_title'],
        creationDate: DateTime.now(),
        lastLoginDate: DateTime.now(),
        playTime: characterData['play_time'] ?? 0,
        characterData: Map<String, dynamic>.from(characterData['character_data'] ?? {}),
      );

      return ImportResult(
        success: true,
        validationResult: ImportValidationResult.valid,
        importedCharacter: character,
        warnings: ['Character imported successfully'],
      );
    } catch (e) {
      return ImportResult(
        success: false,
        validationResult: ImportValidationResult.corrupted_data,
        errorMessage: 'Failed to import character: $e',
        warnings: [],
      );
    }
  }

  static ImportResult _importBuild(CharacterExportData exportData) {
    try {
      final buildData = exportData.data['build'] as Map<String, dynamic>;
      
      final build = CharacterBuild(
        id: buildData['id'],
        name: buildData['name'],
        description: buildData['description'],
        characterClass: CharacterClass.values.firstWhere((c) => c.name == buildData['character_class']),
        specialization: buildData['specialization'] != null 
            ? ClassSpecialization.values.firstWhere((s) => s.name == buildData['specialization'])
            : null,
        skills: List<String>.from(buildData['skills']),
        skillLevels: Map<String, int>.from(buildData['skill_levels']),
        equipment: Map<String, dynamic>.from(buildData['equipment']),
        stats: Map<String, int>.from(buildData['stats']),
        achievements: List<String>.from(buildData['achievements']),
        titles: List<String>.from(buildData['titles']),
        equippedTitle: buildData['equipped_title'],
        creationDate: DateTime.now(),
        lastModifiedDate: DateTime.now(),
        createdBy: buildData['created_by'] ?? 'imported',
        tags: List<String>.from(buildData['tags'] ?? []),
        isPublic: buildData['is_public'] ?? false,
        buildNotes: buildData['build_notes'],
      );

      return ImportResult(
        success: true,
        validationResult: ImportValidationResult.valid,
        importedData: {'build': build},
        warnings: ['Build imported successfully'],
      );
    } catch (e) {
      return ImportResult(
        success: false,
        validationResult: ImportValidationResult.corrupted_data,
        errorMessage: 'Failed to import build: $e',
        warnings: [],
      );
    }
  }

  static ImportResult _importStats(CharacterExportData exportData) {
    return ImportResult(
      success: true,
      validationResult: ImportValidationResult.valid,
      importedData: exportData.data,
      warnings: ['Stats imported successfully'],
    );
  }

  static ImportResult _importAchievements(CharacterExportData exportData) {
    return ImportResult(
      success: true,
      validationResult: ImportValidationResult.valid,
      importedData: exportData.data,
      warnings: ['Achievements imported successfully'],
    );
  }

  static ImportResult _importEquipment(CharacterExportData exportData) {
    return ImportResult(
      success: true,
      validationResult: ImportValidationResult.valid,
      importedData: exportData.data,
      warnings: ['Equipment imported successfully'],
    );
  }

  static ImportResult _importSkills(CharacterExportData exportData) {
    return ImportResult(
      success: true,
      validationResult: ImportValidationResult.valid,
      importedData: exportData.data,
      warnings: ['Skills imported successfully'],
    );
  }

  static ImportResult _importCustomData(CharacterExportData exportData) {
    return ImportResult(
      success: true,
      validationResult: ImportValidationResult.valid,
      importedData: exportData.data,
      warnings: ['Custom data imported successfully'],
    );
  }
}
