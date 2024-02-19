import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:management_application/app/routes/route.dart';

Future<void> main() async {
  ///파이어베이스 연동
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    GetMaterialApp.router(
      initialBinding: BindingsBuilder(
        () async {
          // 초기화 하면서 서비스를 가져온다.
          // Get.put(SplashService());
          // Get.put(LocationService());
          // Get.put(AuthService());
          // Get.put(UserService());
        },
      ),
      // builder: EasyLoading.init(),
      getPages: AppPages.routes,
    ),
  );
}
