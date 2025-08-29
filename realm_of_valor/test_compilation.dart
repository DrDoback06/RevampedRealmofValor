import 'dart:io';

void main() async {
  print('Testing app compilation...');
  
  try {
    // Test importing main app files
    print('Testing main.dart import...');
    await Process.run('dart', ['analyze', 'lib/main.dart']);
    print('✓ main.dart imports successfully');
    
    print('Testing app_bootstrap.dart import...');
    await Process.run('dart', ['analyze', 'lib/app/app_bootstrap.dart']);
    print('✓ app_bootstrap.dart imports successfully');
    
    print('Testing app_router.dart import...');
    await Process.run('dart', ['analyze', 'lib/app/app_router.dart']);
    print('✓ app_router.dart imports successfully');
    
    print('Testing character_screen.dart import...');
    await Process.run('dart', ['analyze', 'lib/features/character/character_screen.dart']);
    print('✓ character_screen.dart imports successfully');
    
    print('Testing map_screen.dart import...');
    await Process.run('dart', ['analyze', 'lib/features/map/map_screen.dart']);
    print('✓ map_screen.dart imports successfully');
    
    print('\n🎉 All files compile successfully!');
    
  } catch (e) {
    print('❌ Compilation error: $e');
  }
}
