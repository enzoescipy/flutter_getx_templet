import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:<YOUR_PROJECT_NAME>/app/routes/route.dart';
import 'package:<YOUR_PROJECT_NAME>/app/screen/Tab/controller/tabs_controller.dart';

class TabsView extends GetView<TabsController> {
  const TabsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetRouterOutlet.builder(
      builder: (context, delegate, currentRoute) {
        //This router outlet handles the appbar and the bottom navigation bar
        controller.checkCurrentLocation(currentRoute);
        return Obx(() => Container(
              color: Colors.white,
              child: SafeArea(
                child: Scaffold(
                  body: GetRouterOutlet(
                    initialRoute: Routes.HOME,
                    key: Get.nestedKey(Routes.TAB),
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: controller.selectIndex.value,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedItemColor: Colors.grey[850],
                    unselectedItemColor: Colors.grey,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                    onTap: (value) {
                      controller.onTap(value, delegate);
                    },
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'home',
                      ),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.list),
                          label: '예시 2'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.face),
                          label: '예시 3'),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }
}
