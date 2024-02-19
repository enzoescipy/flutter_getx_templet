import 'package:get/get.dart';

import 'package:management_application/app/screen/ROOT/view/ROOT_view.dart';
import 'package:management_application/app/screen/ROOT/binding/ROOT_binding.dart';
import 'package:management_application/app/screen/Tab/binding/tabs_binding.dart';
import 'package:management_application/app/screen/Tab/components/Home/binding/home_binding.dart';
import 'package:management_application/app/screen/Tab/components/Home/view/home_view.dart';
import 'package:management_application/app/screen/Tab/view/tabs_view.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> routes = [
    GetPage(name: _Paths.ROOT, 
    page: () => const RootView(),
    binding: RootBinding(),
    participatesInRootNavigator: true,
    preventDuplicates: true,
    children: [
      GetPage(
        preventDuplicates: true,
        name: _Paths.TAB,
        page: () => const TabsView(),
        binding: TabsBinding(),
        children: [
            GetPage(
              name: _Paths.Home,
              page: () => const HomeView(),
              title: 'Home',
              binding: HomeBinding(),
            ),
        ]
      )
    ],
    )

    // GetPage(
    //   name: _Paths.ROOT,
    //   page: () => const RootView(),
    //   binding: RootBinding(),
    //   participatesInRootNavigator: true,
    //   preventDuplicates: true,
    //   children: [
    //     GetPage(
    //       preventDuplicates: true,
    //       name: _Paths.LOGIN,
    //       page: () => const LoginView(),
    //       binding: LoginBinding()
    //     ),
    //     GetPage(
    //       preventDuplicates: true,
    //       name: _Paths.TAB,
    //       page: () => const TabsView(),
    //       bindings: [
    //         TabsBinding(),
    //       ],
    //       title: null,
    //       children: [
    //         ///홈
    //         GetPage(
    //           name: _Paths.Home,
    //           page: () => const HomeView(),
    //           title: 'Home',
    //           binding: HomeBinding(),
    //         ),
    //         /// 이야기 목록
    //         GetPage(
    //           name: _Paths.LOCATIONLIST,
    //           page: () => const PreviewScreen(),
    //           title: 'Storylist',
    //           binding: PreviewBinding(),
    //         ),
    //         GetPage(
    //           preventDuplicates: true,
    //           name: _Paths.MYPAGE,
    //           page: () => const MypageView(),
    //           title: 'Mypage',
    //           binding: MypageBinding(),
    //         )
    //       ],
    //     ),
    //   ],
    // ),
  ];
}

abstract class Routes {
  // /// 메인
  static const ROOT = _Paths.ROOT;

  // /// 로그인
  // static const LOGIN = _Paths.LOGIN;

  // /// 탭
  static const TAB = _Paths.TAB;

  // /// 홈
  static const HOME = _Paths.TAB + _Paths.Home;

  // ///위치
  // static const LOCATIONLIST = _Paths.TAB + _Paths.LOCATIONLIST;

  // ///생성
  // static const MYPAGE = _Paths.TAB + _Paths.MYPAGE;
}

abstract class _Paths {
  static const ROOT = '/';
  // static const LOGIN = '/login';
  static const TAB = '/tab';
  static const Home = '/home';
  // static const LOCATIONLIST = '/locationlist';
  // static const MYPAGE = '/mypage';
}
