import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../auth/presentation/sign_in_page.dart';
import '../../splash/presentation/splash_page.dart';
import '../../starred_repos/presentation/starred_repos_page.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: SplashPage, initial: true),
    AutoRoute(page: SignInPage, path: '/sign-in'),
    AutoRoute(page: StarredReposPage, path: '/starred'),
  ],
)
// extend the generated private router
class AppRouter extends _$AppRouter {}
