import 'package:get/get.dart';

import 'package:management_application/app/routes/route.dart';

class TabsController extends GetxController {
  RxInt selectIndex = RxInt(0);

  void onTap(int value, GetDelegate delegate) {
    //여기서 인터넷 주소 형식으로 데이터 전송된다.
    switch (value) {
      case 0:
        delegate.toNamed(Routes.HOME);
        break;
      // case 1:
      //   delegate.toNamed(Routes.LOCATIONLIST);
      //   break;
      // case 2:
      //   delegate.toNamed(Routes.MYPAGE);
      //   break;
      default:
    }
  }

  void checkCurrentLocation(GetNavConfig? currentRoute) {
    final currentLocation = currentRoute?.uri.toFilePath();
    selectIndex.value = 0;

    // if (currentLocation?.startsWith(Routes.LOCATIONLIST) == true) {
    //   selectIndex.value = 1;
    // } else if (currentLocation?.startsWith(Routes.MYPAGE) == true) {
    //   selectIndex.value = 2;
    // }
  }
}
