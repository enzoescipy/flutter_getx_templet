import 'package:<YOUR_PROJECT_NAME>/app/screen/ROOT/controller/ROOT_controller.dart';
import 'package:get/get.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<RootController>(RootController());
  }
}
