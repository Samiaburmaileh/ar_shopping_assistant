import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Services
import 'services/auth_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/home/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/product/product_details_screen.dart';
import 'screens/ar_view/ar_view_screen.dart';
import 'screens/shopping_list/shopping_lists_screen.dart';
import 'screens/profile/profile_screen.dart';

// Blocs
import 'blocs/auth/auth_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'blocs/shopping_list/shopping_list_bloc.dart';
import 'blocs/ar/ar_bloc.dart';

// Theme and constants
import 'utils/constants.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: AuthService(),
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(),
        ),
        BlocProvider<ShoppingListBloc>(
          create: (context) => ShoppingListBloc(),
        ),
        BlocProvider<ArBloc>(
          create: (context) => ArBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AR Shopping Assistant',
        theme: _buildTheme(),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial) {
              return const SplashScreen();
            }
            if (state is AuthAuthenticated) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
        routes: _buildRoutes(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        background: AppColors.background,
        surface: AppColors.surface,
      ),
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/home': (context) => const HomeScreen(),
      '/login': (context) => const LoginScreen(),
      '/product_details': (context) => const ProductDetailsScreen(),
      '/ar_view': (context) => const ArViewScreen(),
      '/shopping_lists': (context) => const ShoppingListsScreen(),
      '/profile': (context) => const ProfileScreen(),
    };
  }
}