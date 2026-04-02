import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 1. 设置窗口选项 (5.0.0 版本写法)
  // 注意：这里不再设置 windowState
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600), // 给一个默认初始大小，防止在某些系统上闪烁
    center: true, // 居中
    backgroundColor: Colors.transparent, // 设置背景透明
    skipTaskbar: true, // 不在任务栏显示
    titleBarStyle: TitleBarStyle.hidden,// 隐藏标题栏（配合无边框）
  );

  // 应用选项
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 2. 在这里进行窗口状态的控制 (这是 5.0.0 的关键变化)

    // 先设置无边框
    await windowManager.setAsFrameless();

    // 设置始终置顶
    await windowManager.setAlwaysOnTop(true);

    // 关键修复：先最大化，再全屏
    // 注意：在某些系统上，直接 setFullScreen 可能会因为还没渲染完而失效
    // 所以先确保它是最大化的，或者直接 setSize 撑满屏幕
    await windowManager.maximize();

    // 如果你想要的是“真·全屏”（遮住任务栏），则调用：
    // await windowManager.setFullScreen(true);

    // 最后显示并聚焦
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}
// ... 其余代码保持不变 ...

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeskPet',
      debugShowCheckedModeBanner: false,
      home: const DeskPet(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      // 核心修复：禁用混合模式，让透明像素真正穿透到桌面
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).removeViewPadding(removeTop: true, removeBottom: true),
          child: child!,
        );
      },
    );
  }
}

class DeskPet extends StatefulWidget {
  const DeskPet({super.key});

  @override
  State<DeskPet> createState() => _DeskPetState();
}

class _DeskPetState extends State<DeskPet> {
  double x = 100;
  double y = 200;

  double speed = 1.0;
  int direction = 1;

  double jumpOffset = 0;
  int jumpDirection = 1;

  int walkFrameCount = 0;
  int maxWalkFrames = 100;

  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      setState(() {
        x += direction * speed;

        jumpOffset += 0.2 * jumpDirection;
        if (jumpOffset > 4) jumpDirection = -1;
        if (jumpOffset < 0) jumpDirection = 1;

        double screenWidth = MediaQuery.of(context).size.width;
        if (x < 0) {
          direction = 1;
        } else if (x > screenWidth - 100) {
          direction = -1;
        }

        walkFrameCount++;
        if (walkFrameCount >= maxWalkFrames) {
          walkFrameCount = 0;
          maxWalkFrames = 120 + Random().nextInt(180);

          double r = Random().nextDouble();
          if (r < 0.3) {
            direction = 1;
          } else if (r < 0.6) {
            direction = -1;
          } else {
            direction = 0;
          }

          speed = 0.9 + Random().nextDouble() * 0.3;
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            left: x,
            top: y + jumpOffset,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  x += details.delta.dx;
                  y += details.delta.dy;
                });
              },
              child: Image.asset(
                "assets/img.png",
                width: 100, 
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false, 
                colorBlendMode: BlendMode.srcOver, 
              ),
            ),
          ),
        ],
      ),
    );
  }
}
