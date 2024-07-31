import "package:get/get.dart";
import 'package:flutter/material.dart';

import "package:<YOUR_PROJECT_NAME>/app/screen/Tab/components/Home/controller/home_controller.dart";

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('hello, world!'),
    );
  }
}
