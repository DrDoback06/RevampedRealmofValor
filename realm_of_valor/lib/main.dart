import 'app/app_bootstrap.dart';
import 'services/event_system.dart';

void main() async {
  // Initialize dynamic events system
  EventSystem.initializeDynamicEvents();
  
  bootstrapAndRunApp();
}

