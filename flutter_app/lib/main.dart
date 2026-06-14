import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final storage = await AppStorage.create();
  final apiClient = ApiClient(storage: storage);
  final authController = AuthController(apiClient: apiClient, storage: storage);
  final cartController = CartController(storage: storage);
  await Future.wait([authController.restore(), cartController.restore()]);
  runApp(
    FoodApp(
      apiClient: apiClient,
      authController: authController,
      cartController: cartController,
    ),
  );
}

class FoodApp extends StatelessWidget {
  const FoodApp({
    super.key,
    required this.apiClient,
    required this.authController,
    required this.cartController,
  });

  final ApiClient apiClient;
  final AuthController authController;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: cartController),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          final router = createRouter(auth);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'FoodApp Flutter',
            theme: AppTheme.theme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' || location == '/register';
      final isProtected = location == '/checkout' || location == '/orders';
      final isAdmin = location.startsWith('/admin');

      if (auth.initializing) {
        return location == '/loading' ? null : '/loading';
      }

      if (location == '/loading') {
        return auth.user != null
            ? auth.isAdmin
                ? '/admin'
                : '/menu'
            : '/';
      }

      if (isAuthPage && auth.user != null) {
        return auth.isAdmin ? '/admin' : '/menu';
      }

      if (isProtected && auth.user == null) {
        return '/login';
      }

      if (isAdmin) {
        if (auth.user == null) return '/login';
        if (!auth.isAdmin) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const LoadingPage(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const StoreShell(child: HomePage()),
      ),
      GoRoute(
        path: '/menu',
        builder: (_, state) => StoreShell(
          child: MenuPage(
            initialSearch: state.uri.queryParameters['search'] ?? '',
            initialCategoryId: state.uri.queryParameters['category'],
            initialPage: int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1,
          ),
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => StoreShell(
          child: ProductDetailPage(productId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const StoreShell(child: CartPage()),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const StoreShell(child: CheckoutPage()),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const StoreShell(child: OrdersPage()),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const StoreShell(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const StoreShell(child: RegisterPage()),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminShell(child: AdminDashboardPage()),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (_, __) => const AdminShell(child: AdminProductsPage()),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (_, __) => const AdminShell(child: AdminCategoriesPage()),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (_, __) => const AdminShell(child: AdminOrdersPage()),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const AdminShell(child: AdminUsersPage()),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, __) => const AdminShell(child: AdminReportsPage()),
      ),
    ],
  );
}

class AppTheme {
  static const bgPrimary = Color(0xFF0A0A0F);
  static const bgSecondary = Color(0xFF12121A);
  static const bgCard = Color(0xCC161620);
  static const textPrimary = Color(0xFFF5F0EB);
  static const textSecondary = Color(0xFFA8A0B4);
  static const textMuted = Color(0xFF6B6380);
  static const gold = Color(0xFFD4A574);
  static const goldLight = Color(0xFFE8C18E);
  static const rose = Color(0xFFC9A89B);
  static const green = Color(0xFF6BCB77);
  static const blue = Color(0xFF6FA3EF);
  static const purple = Color(0xFFB38BFA);
  static const yellow = Color(0xFFF0D78C);
  static const red = Color(0xFFE8646D);
  static const border = Color(0x1AD4A574);

  static final theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: goldLight,
      surface: bgSecondary,
      error: red,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSecondary,
      hintStyle: const TextStyle(color: textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold),
      ),
    ),
  );
}

class AppConfig {
  static const apiOrigin = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get apiBase => '$apiOrigin/api';
}

class AppStorage {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage._(prefs);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}

class ApiClient {
  ApiClient({required AppStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBase,
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );
  }

  final AppStorage _storage;
  late final Dio _dio;

  Options _authOptions({bool multipart = false}) {
    final token = _storage.getString('token');
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (!multipart) 'Content-Type': 'application/json',
      },
    );
  }

  Future<JsonMap> post(String path, dynamic data, {bool multipart = false}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: _authOptions(multipart: multipart),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<JsonMap> patch(String path, dynamic data) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      path,
      data: data,
      options: _authOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<JsonMap> getMap(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      options: _authOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<List<dynamic>>(
      path,
      queryParameters: queryParameters,
      options: _authOptions(),
    );
    return response.data ?? <dynamic>[];
  }

  Future<void> delete(String path) async {
    await _dio.delete<void>(path, options: _authOptions());
  }
}

class AuthController extends ChangeNotifier {
  AuthController({required ApiClient apiClient, required AppStorage storage})
      : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final AppStorage _storage;

  UserModel? user;
  bool initializing = true;

  bool get isAdmin => user?.role == 'admin';

  Future<void> restore() async {
    final rawUser = _storage.getString('user');
    if (rawUser != null && rawUser.isNotEmpty) {
      user = UserModel.fromJson(jsonDecode(rawUser) as JsonMap);
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post('/login', {
      'email': email,
      'password': password,
    });
    await _persistAuth(data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await _apiClient.post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    await _persistAuth(data);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout', {});
    } catch (_) {}
    user = null;
    await _storage.remove('token');
    await _storage.remove('user');
    notifyListeners();
  }

  Future<void> _persistAuth(JsonMap data) async {
    final token = data['token']?.toString() ?? '';
    final authUser = UserModel.fromJson(asMap(data['user']));
    user = authUser;
    await _storage.setString('token', token);
    await _storage.setString('user', jsonEncode(authUser.toJson()));
    notifyListeners();
  }
}

class CartController extends ChangeNotifier {
  CartController({required AppStorage storage}) : _storage = storage;

  final AppStorage _storage;
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> restore() async {
    final raw = _storage.getString('cart');
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(list.map((item) => CartItem.fromJson(asMap(item))));
    }
    notifyListeners();
  }

  void add(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + quantity);
    } else {
      _items.add(CartItem(productId: product.id, product: product, quantity: quantity));
    }
    _save();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      _save();
    }
  }

  void remove(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    _save();
  }

  void clear() {
    _items.clear();
    _save();
  }

  void _save() {
    unawaited(_storage.setString('cart', jsonEncode(_items.map((e) => e.toJson()).toList())));
    notifyListeners();
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      ),
    );
  }
}

class StoreShell extends StatelessWidget {
  const StoreShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final location = GoRouterState.of(context).uri.path;
    final isLanding = location == '/' && auth.user == null;
    final isMobile = MediaQuery.sizeOf(context).width < 860;
    return Scaffold(
      endDrawer: isMobile
          ? Drawer(
              backgroundColor: AppTheme.bgSecondary,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('FoodApp', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.gold)),
                  const SizedBox(height: 24),
                  ListTile(title: const Text('Cart'), trailing: Text('${cart.totalItems}'), onTap: () => context.go('/cart')),
                  if (auth.user != null) ...[
                    ListTile(title: const Text('Home'), onTap: () => context.go('/')),
                    ListTile(title: const Text('Menu'), onTap: () => context.go('/menu')),
                    ListTile(title: const Text('My Orders'), onTap: () => context.go('/orders')),
                    if (auth.isAdmin) ListTile(title: const Text('Admin'), onTap: () => context.go('/admin')),
                    ListTile(
                      title: const Text('Logout'),
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ] else ...[
                    ListTile(title: const Text('Sign In'), onTap: () => context.go('/login')),
                    ListTile(title: const Text('Get Started'), onTap: () => context.go('/register')),
                  ],
                ],
              ),
            )
          : null,
      bottomNavigationBar: const SafeArea(
        top: false,
        child: FooterSection(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.3,
            colors: [
              Color(0x33121620),
              AppTheme.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 86),
                child: child,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _StoreNavbar(
                  isLanding: isLanding,
                  isLoggedIn: auth.user != null,
                  isAdmin: auth.isAdmin,
                  userName: auth.user?.name ?? '',
                  cartItems: cart.totalItems,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreNavbar extends StatelessWidget {
  const _StoreNavbar({
    required this.isLanding,
    required this.isLoggedIn,
    required this.isAdmin,
    required this.userName,
    required this.cartItems,
  });

  final bool isLanding;
  final bool isLoggedIn;
  final bool isAdmin;
  final String userName;
  final int cartItems;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 860;
    final background = isLanding ? Colors.transparent : AppTheme.bgPrimary.withValues(alpha: 0.05);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: background,
            border: Border(bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.45))),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                child: Text(
                  'FoodApp',
                  style: GoogleFonts.outfit(
                    color: AppTheme.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (!isMobile && isLoggedIn) ...[
                _navLink(context, 'Home', '/'),
                _navLink(context, 'Menu', '/menu'),
                _navLink(context, 'My Orders', '/orders'),
                if (isAdmin) _navLink(context, 'Admin', '/admin'),
                const SizedBox(width: 20),
              ],
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => showCartPreviewDialog(context),
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textSecondary),
                  ),
                  if (cartItems > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: AppTheme.gold,
                        child: Text(
                          '$cartItems',
                          style: const TextStyle(
                            color: AppTheme.bgPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              if (isLoggedIn && !isMobile)
                PopupMenuButton<String>(
                  color: AppTheme.bgSecondary,
                  onSelected: (value) async {
                    if (value == 'orders') context.go('/orders');
                    if (value == 'logout') {
                      await context.read<AuthController>().logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'orders', child: Text('My Orders')),
                    PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(userName, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              else if (!isLoggedIn && !isMobile)
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => context.go('/register'),
                      style: filledGoldButtonStyle(),
                      child: const Text('Get Started'),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(BuildContext context, String label, String route) {
    final active = GoRouterState.of(context).uri.path == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => context.go(route),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.gold : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        children: const [
          Text('FoodApp', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
          Text(
            '© 2026 FoodApp. Crafted with passion for fine dining.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TopNoticeOverlay extends StatefulWidget {
  const _TopNoticeOverlay({
    required this.message,
    required this.icon,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_TopNoticeOverlay> createState() => _TopNoticeOverlayState();
}

class _TopNoticeOverlayState extends State<_TopNoticeOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 18,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: SlideTransition(
              position: _offsetAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: AppTheme.gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: widget.onAction,
                          child: Text(widget.actionLabel!, style: const TextStyle(color: AppTheme.gold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  bool loading = true;
  List<Product> recommended = const [];
  List<Category> categories = const [];
  MenuStats stats = const MenuStats(menuCount: 0, totalOrders: 0, averageRating: 0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final api = context.read<ApiClient>();
    try {
      final results = await Future.wait([
        api.getList('/products/recommended'),
        api.getList('/categories'),
        _loadMenuStats(api),
      ]);
      if (!mounted) return;
      setState(() {
        recommended = (results[0] as List<dynamic>).map((e) => Product.fromJson(asMap(e))).toList();
        categories = (results[1] as List<dynamic>).map((e) => Category.fromJson(asMap(e))).toList();
        stats = results[2] as MenuStats;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<MenuStats> _loadMenuStats(ApiClient api) async {
    final firstPage = await api.getMap('/products', queryParameters: {'page': 1});
    final totalMenus = asInt(firstPage['total'], fallback: asList(firstPage['data']).length);
    final lastPage = asInt(firstPage['last_page'], fallback: 1);

    final allProducts = <Product>[
      ...asList(firstPage['data']).map((e) => Product.fromJson(asMap(e))),
    ];

    for (var currentPage = 2; currentPage <= lastPage; currentPage++) {
      final nextPage = await api.getMap('/products', queryParameters: {'page': currentPage});
      allProducts.addAll(asList(nextPage['data']).map((e) => Product.fromJson(asMap(e))));
    }

    final totalOrders = allProducts.fold<int>(0, (sum, item) => sum + item.orderCount);
    final averageRating = allProducts.isEmpty
        ? 0.0
        : allProducts.fold<double>(0, (sum, item) => sum + item.avgRating) / allProducts.length;

    return MenuStats(
      menuCount: totalMenus,
      totalOrders: totalOrders,
      averageRating: averageRating,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                    child: Column(
                      children: [
                        const PillLabel(text: 'Premium Food Ordering'),
                        const SizedBox(height: 24),
                        Text(
                          'Exquisite Flavors,\nDelivered Fresh',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: responsiveValue(context, desktop: 56, tablet: 44, mobile: 34),
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: const Text(
                            'Discover our curated menu of artisan dishes, crafted with the finest ingredients and delivered straight to your table.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, height: 1.8, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 540,
                          child: TextField(
                            controller: searchController,
                            onSubmitted: (_) => _goToSearch(),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                              hintText: 'Search our curated menu...',
                              suffixIcon: IconButton(
                                onPressed: _goToSearch,
                                icon: const Icon(Icons.arrow_forward, color: AppTheme.gold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 26,
                          runSpacing: 12,
                          children: [
                            HeroStat(number: '${stats.menuCount}', label: 'Menu Items'),
                            HeroStat(number: '${stats.totalOrders}+', label: 'Orders Served'),
                            HeroStat(number: stats.averageRating.toStringAsFixed(1), label: 'Avg Rating'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _featureGrid(),
                  const SizedBox(height: 40),
                  SectionHeader(
                    title: 'Browse Categories',
                    actionLabel: 'See All',
                    onTap: () => context.go('/menu'),
                  ),
                  const SizedBox(height: 18),
                  _categoryGrid(),
                  const SizedBox(height: 40),
                  SectionHeader(
                    title: "Chef's Selection",
                    actionLabel: 'View Full Menu',
                    onTap: () => context.go('/menu'),
                  ),
                  const SizedBox(height: 18),
                  ProductGrid(products: recommended.take(8).toList()),
                  if (context.watch<AuthController>().user == null) ...[
                    const SizedBox(height: 44),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
                      child: Column(
                        children: [
                          Text(
                            'Ready to Order?',
                            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Create an account and start exploring our exquisite menu today.',
                            style: TextStyle(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            alignment: WrapAlignment.center,
                            children: [
                              FilledButton(
                                onPressed: () => context.go('/register'),
                                style: filledGoldButtonStyle(),
                                child: const Text('Get Started'),
                              ),
                              OutlinedButton(
                                onPressed: () => context.go('/menu'),
                                child: const Text('Browse Menu'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid() {
    const features = [
      ('Fast Delivery', 'Fresh food delivered in under 30 minutes, straight from our kitchen.', Icons.schedule),
      ('Top Quality', 'Premium ingredients sourced from trusted local partners.', Icons.star_outline),
      ('Secure Payment', 'Pay safely with Cash or QRIS, your choice, your comfort.', Icons.verified_user_outlined),
      ('Easy Ordering', 'Browse, select, and checkout in just a few taps.', Icons.check_circle_outline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 980
            ? 4
            : constraints.maxWidth > 700
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.25,
          ),
          itemBuilder: (_, index) {
            final feature = features[index];
            return GlassPanel(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.gold.withValues(alpha: 0.12),
                    child: Icon(feature.$3, color: AppTheme.gold),
                  ),
                  const SizedBox(height: 16),
                  Text(feature.$1, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    feature.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted, height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _categoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final targetCardWidth = availableWidth < 640 ? availableWidth : 220.0;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: categories.map((category) {
            final cardWidth = availableWidth < 640
                ? availableWidth
                : math.min(targetCardWidth, (availableWidth - 32) / 2);
            return SizedBox(
              width: cardWidth,
              child: InkWell(
                onTap: () => context.go('/menu?category=${category.id}'),
                child: GlassPanel(
                  child: SizedBox(
                    height: 108,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text('${category.productsCount} items', style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _goToSearch() {
    final search = searchController.text.trim();
    if (search.isNotEmpty) {
      context.go('/menu?search=${Uri.encodeQueryComponent(search)}');
    }
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    required this.initialSearch,
    required this.initialCategoryId,
    required this.initialPage,
  });

  final String initialSearch;
  final String? initialCategoryId;
  final int initialPage;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final TextEditingController searchController;
  List<Product> products = const [];
  List<Category> categories = const [];
  bool loading = true;
  int page = 1;
  int lastPage = 1;
  String activeCategory = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: widget.initialSearch);
    searchController.addListener(_onSearchChanged);
    activeCategory = widget.initialCategoryId ?? '';
    page = widget.initialPage;
    unawaited(loadCategories());
    unawaited(loadProducts());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MenuPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSearch != widget.initialSearch ||
        oldWidget.initialCategoryId != widget.initialCategoryId ||
        oldWidget.initialPage != widget.initialPage) {
      searchController.text = widget.initialSearch;
      activeCategory = widget.initialCategoryId ?? '';
      page = widget.initialPage;
      unawaited(loadProducts());
    }
  }

  Future<void> loadCategories() async {
    final api = context.read<ApiClient>();
    final response = await api.getList('/categories');
    if (!mounted) return;
    setState(() => categories = response.map((e) => Category.fromJson(asMap(e))).toList());
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    try {
      final api = context.read<ApiClient>();
      final response = await api.getMap('/products', queryParameters: {
        'page': page,
        if (searchController.text.trim().isNotEmpty) 'search': searchController.text.trim(),
        if (activeCategory.isNotEmpty) 'category_id': activeCategory,
      });
      if (!mounted) return;
      setState(() {
        products = asList(response['data']).map((e) => Product.fromJson(asMap(e))).toList();
        lastPage = asInt(response['last_page'], fallback: 1);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  void _submitSearch() {
    _applyFilters();
  }

  void _applyFilters() {
    final search = searchController.text.trim();
    final query = <String, String>{};
    if (search.isNotEmpty) query['search'] = search;
    if (activeCategory.isNotEmpty) query['category'] = activeCategory;
    context.go(Uri(path: '/menu', queryParameters: query).toString());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Our Menu', style: GoogleFonts.outfit(fontSize: 38, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                onSubmitted: (_) => _submitSearch(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                  hintText: 'Search menu...',
                  suffixIcon: IconButton(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.arrow_forward, color: AppTheme.gold),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: activeCategory.isEmpty,
                    onSelected: (_) {
                      setState(() => activeCategory = '');
                      _applyFilters();
                    },
                  ),
                  ...categories.map(
                    (category) => FilterChip(
                      label: Text(category.name),
                      selected: activeCategory == category.id.toString(),
                      onSelected: (_) {
                        final next = activeCategory == category.id.toString() ? '' : category.id.toString();
                        setState(() => activeCategory = next);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (loading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.gold)))
              else if (products.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No products found',
                  subtitle: 'Try a different search or category',
                )
              else ...[
                ProductGrid(products: products),
                if (lastPage > 1) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: page <= 1
                            ? null
                            : () => context.go(Uri(
                                  path: '/menu',
                                  queryParameters: {
                                    if (searchController.text.trim().isNotEmpty) 'search': searchController.text.trim(),
                                    if (activeCategory.isNotEmpty) 'category': activeCategory,
                                    'page': '${page - 1}',
                                  },
                                ).toString()),
                        child: const Text('Previous'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Page $page of $lastPage', style: const TextStyle(color: AppTheme.textSecondary)),
                      ),
                      OutlinedButton(
                        onPressed: page >= lastPage
                            ? null
                            : () => context.go(Uri(
                                  path: '/menu',
                                  queryParameters: {
                                    if (searchController.text.trim().isNotEmpty) 'search': searchController.text.trim(),
                                    if (activeCategory.isNotEmpty) 'category': activeCategory,
                                    'page': '${page + 1}',
                                  },
                                ).toString()),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 820
                ? 3
                : constraints.maxWidth > 560
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: .72,
          ),
          itemBuilder: (_, index) => ProductCard(product: products[index]),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/products/${product.id}'),
      borderRadius: BorderRadius.circular(20),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox.expand(child: ProductImage(product: product)),
                  ),
                  if (product.orderCount > 50)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.gold, AppTheme.goldLight]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Best Seller',
                          style: TextStyle(color: AppTheme.bgPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category?.name ?? '-', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(product.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.55),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 18),
                      const SizedBox(width: 6),
                      Text(product.avgRating.toStringAsFixed(1)),
                      const Spacer(),
                      Text('${product.orderCount} orders', style: const TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatCurrency(product.price),
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.gold),
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          context.read<CartController>().add(product);
                          showAddToCartSnackBar(context, '${product.name} added to cart');
                        },
                        style: filledGoldButtonStyle(minSize: const Size(44, 44)),
                        child: const Icon(Icons.add, color: AppTheme.bgPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? product;
  bool loading = true;
  int quantity = 1;
  int rating = 5;
  final reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await context.read<ApiClient>().getMap('/products/${widget.productId}');
      if (!mounted) return;
      setState(() {
        product = Product.fromJson(response);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> submitReview() async {
    final auth = context.read<AuthController>();
    if (auth.user == null) {
      context.go('/login');
      return;
    }
    try {
      await context.read<ApiClient>().post('/products/${product!.id}/reviews', {
        'rating': rating,
        'comment': reviewController.text.trim(),
      });
      reviewController.clear();
      showAppSnackBar(context, 'Review submitted');
      await load();
    } catch (error) {
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    if (product == null) return const Center(child: EmptyState(icon: Icons.inventory_2_outlined, title: 'Product not found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final vertical = constraints.maxWidth < 860;
                  return Flex(
                    direction: vertical ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GlassPanel(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(aspectRatio: 1, child: ProductImage(product: product!)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24, height: 24),
                      Expanded(
                        child: GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product!.category?.name ?? '-', style: const TextStyle(color: AppTheme.gold)),
                              const SizedBox(height: 8),
                              Text(product!.name, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              Text(product!.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.8)),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 10,
                                children: [
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.star, size: 18, color: AppTheme.gold),
                                    const SizedBox(width: 6),
                                    Text('${product!.avgRating.toStringAsFixed(1)} (${product!.reviews.length} reviews)'),
                                  ]),
                                  Text('${product!.orderCount} orders', style: const TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                formatCurrency(product!.price),
                                style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w700, color: AppTheme.gold),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  QuantityControl(
                                    value: quantity,
                                    onMinus: () => setState(() => quantity = math.max(1, quantity - 1)),
                                    onPlus: () => setState(() => quantity += 1),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        context.read<CartController>().add(product!, quantity: quantity);
                                        showAddToCartSnackBar(context, '$quantity x ${product!.name} added to cart');
                                      },
                                      style: filledGoldButtonStyle(minHeight: 56),
                                      icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.bgPrimary),
                                      label: Text(
                                        'Add to Cart - ${formatCurrency(product!.price * quantity)}',
                                        style: const TextStyle(color: AppTheme.bgPrimary, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reviews', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
                    if (context.watch<AuthController>().user != null) ...[
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        children: List.generate(
                          5,
                          (index) => IconButton(
                            onPressed: () => setState(() => rating = index + 1),
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_outline,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reviewController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(hintText: 'Write your review...'),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: submitReview,
                        style: filledGoldButtonStyle(),
                        child: const Text('Submit Review', style: TextStyle(color: AppTheme.bgPrimary)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (product!.reviews.isEmpty)
                      const Text('No reviews yet. Be the first to review!', style: TextStyle(color: AppTheme.textMuted))
                    else
                      ...product!.reviews.map(
                        (review) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(review.user?.name ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(
                                      review.rating,
                                      (_) => const Icon(Icons.star, size: 16, color: AppTheme.gold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review.comment, style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();
    if (cart.items.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          subtitle: 'Browse our menu and add some delicious items!',
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 980;
              return Flex(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping Cart (${cart.totalItems} items)',
                          style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 18),
                        ...cart.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GlassPanel(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 92,
                                    height: 92,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: ProductImage(product: item.product),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text(formatCurrency(item.product.price), style: const TextStyle(color: AppTheme.gold)),
                                      ],
                                    ),
                                  ),
                                  QuantityControl(
                                    value: item.quantity,
                                    onMinus: () => cart.updateQuantity(item.productId, item.quantity - 1),
                                    onPlus: () => cart.updateQuantity(item.productId, item.quantity + 1),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  IconButton(
                                    onPressed: () => cart.remove(item.productId),
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24, height: 24),
                  SizedBox(
                    width: vertical ? double.infinity : 340,
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Summary', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          SummaryRow(label: 'Subtotal (${cart.totalItems} items)', value: formatCurrency(cart.totalPrice)),
                          const SizedBox(height: 12),
                          SummaryRow(label: 'Total', value: formatCurrency(cart.totalPrice), emphasize: true),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                if (auth.user == null) {
                                  showAppSnackBar(context, 'Please sign in first to continue payment');
                                  context.go('/login');
                                  return;
                                }
                                context.go('/checkout');
                              },
                              style: filledGoldButtonStyle(minHeight: 52),
                              icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.bgPrimary),
                              label: const Text('Proceed to Checkout', style: TextStyle(color: AppTheme.bgPrimary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String paymentMethod = 'cash';
  String orderType = 'take_away';
  bool loading = false;
  OrderModel? order;
  PickedUpload? deliveryPhoto;
  final notesController = TextEditingController();
  final deliveryAddressController = TextEditingController();
  final tableController = TextEditingController();

  Future<void> pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      deliveryPhoto = PickedUpload(name: file!.name, bytes: file.bytes!);
    });
  }

  Future<void> placeOrder() async {
    final cart = context.read<CartController>();
    final auth = context.read<AuthController>();
    if (auth.user == null) {
      context.go('/login');
      return;
    }
    if (orderType == 'delivery' && deliveryAddressController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Delivery address is required');
      return;
    }
    if (orderType == 'dine_in' && tableController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Table number is required');
      return;
    }

    setState(() => loading = true);
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('payment_method', paymentMethod));
      formData.fields.add(MapEntry('order_type', orderType));
      if (notesController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('notes', notesController.text.trim()));
      }
      if (orderType == 'delivery') {
        formData.fields.add(MapEntry('delivery_address', deliveryAddressController.text.trim()));
        if (deliveryPhoto != null) {
          formData.files.add(MapEntry(
            'delivery_photo',
            MultipartFile.fromBytes(deliveryPhoto!.bytes, filename: deliveryPhoto!.name),
          ));
        }
      }
      if (orderType == 'dine_in') {
        formData.fields.add(MapEntry('table_number', tableController.text.trim()));
      }
      for (var i = 0; i < cart.items.length; i++) {
        final item = cart.items[i];
        formData.fields.add(MapEntry('items[$i][product_id]', '${item.productId}'));
        formData.fields.add(MapEntry('items[$i][quantity]', '${item.quantity}'));
      }

      final response = await context.read<ApiClient>().post('/orders', formData, multipart: true);
      cart.clear();
      if (!mounted) return;
      setState(() {
        order = OrderModel.fromJson(response);
        loading = false;
      });
      showAppSnackBar(context, 'Order placed successfully');
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    if (auth.user == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }
    if (order != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: GlassPanel(
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 72, color: AppTheme.green),
                  const SizedBox(height: 16),
                  Text('Order Placed Successfully!', style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(order!.orderNumber, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  if (order!.payment?.method == 'qris' && order!.payment?.status == 'pending')
                    Column(
                      children: [
                        const Text('Scan QRIS to Pay'),
                        const SizedBox(height: 16),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: QrImageView(data: order!.payment!.qrisCode ?? '', size: 200),
                        ),
                        const SizedBox(height: 12),
                        Text(formatCurrency(order!.payment!.amount), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text('Pay at Counter'),
                        const SizedBox(height: 8),
                        Text(formatCurrency(order!.payment?.amount ?? order!.totalAmount), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => context.go('/orders'),
                    style: filledGoldButtonStyle(),
                    child: const Text('View My Orders', style: TextStyle(color: AppTheme.bgPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (cart.items.isEmpty) {
      return const Center(child: EmptyState(icon: Icons.shopping_cart_outlined, title: 'Your cart is empty'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 980;
              return Flex(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Checkout', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order Items', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              ...cart.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text('${item.product.name} x${item.quantity}')),
                                      Text(formatCurrency(item.subtotal), style: const TextStyle(color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Method', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.payments_outlined)),
                                  ButtonSegment(value: 'qris', label: Text('QRIS'), icon: Icon(Icons.qr_code)),
                                ],
                                selected: {paymentMethod},
                                onSelectionChanged: (value) => setState(() => paymentMethod = value.first),
                              ),
                              const SizedBox(height: 10),
                              const Text('Cash pays at counter, QRIS shows a scannable code after checkout.', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order Type', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Takeaway'),
                                    selected: orderType == 'take_away',
                                    onSelected: (_) => setState(() => orderType = 'take_away'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Dine-in'),
                                    selected: orderType == 'dine_in',
                                    onSelected: (_) => setState(() => orderType = 'dine_in'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Delivery'),
                                    selected: orderType == 'delivery',
                                    onSelected: (_) => setState(() => orderType = 'delivery'),
                                  ),
                                ],
                              ),
                              if (orderType == 'dine_in') ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: tableController,
                                  decoration: const InputDecoration(labelText: 'Table Number'),
                                ),
                              ],
                              if (orderType == 'delivery') ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: deliveryAddressController,
                                  minLines: 3,
                                  maxLines: 4,
                                  decoration: const InputDecoration(labelText: 'Full Address'),
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: pickPhoto,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(deliveryPhoto?.name ?? 'Upload Drop-off Photo'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              TextField(
                                controller: notesController,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(hintText: 'Any special requests?'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24, height: 24),
                  SizedBox(
                    width: vertical ? double.infinity : 340,
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Summary', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          SummaryRow(label: 'Subtotal', value: formatCurrency(cart.totalPrice)),
                          const SizedBox(height: 12),
                          SummaryRow(label: 'Total', value: formatCurrency(cart.totalPrice), emphasize: true),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: loading ? null : placeOrder,
                              style: filledGoldButtonStyle(minHeight: 52),
                              child: Text(
                                loading ? 'Placing Order...' : 'Place Order',
                                style: const TextStyle(color: AppTheme.bgPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool loading = true;
  List<OrderModel> orders = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await context.read<ApiClient>().getMap('/orders');
      if (!mounted) return;
      setState(() {
        orders = asList(response['data']).map((e) => OrderModel.fromJson(asMap(e))).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> simulateQris(int orderId) async {
    try {
      await context.read<ApiClient>().post('/payments/$orderId/simulate-qris', {});
      showAppSnackBar(context, 'QRIS payment confirmed');
      await load();
    } catch (error) {
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Orders', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              if (orders.isEmpty)
                const EmptyState(icon: Icons.inventory_2_outlined, title: 'No orders yet', subtitle: 'Place your first order now!')
              else
                ...orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.orderNumber, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                                  Text(DateFormat('d MMMM y', 'id_ID').format(order.createdAt), style: const TextStyle(color: AppTheme.textMuted)),
                                ],
                              ),
                              const Spacer(),
                              StatusBadge(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OrderTypeDetails(order: order),
                          const SizedBox(height: 16),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text('${item.product?.name ?? 'Product'} x${item.quantity}')),
                                  Text(formatCurrency(item.subtotal), style: const TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                          const Divider(color: AppTheme.border),
                          Row(
                            children: [
                              PaymentBadge(payment: order.payment),
                              const Spacer(),
                              Text(
                                formatCurrency(order.totalAmount),
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.gold),
                              ),
                            ],
                          ),
                          if (order.payment?.method == 'qris' && order.payment?.status == 'pending') ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 20,
                              runSpacing: 16,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(10),
                                  child: QrImageView(data: order.payment!.qrisCode ?? '', size: 120),
                                ),
                                OutlinedButton(
                                  onPressed: () => simulateQris(order.id),
                                  child: const Text('Simulate QRIS Payment'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  void useDemoCredential(String email, String password) {
    setState(() {
      emailController.text = email;
      passwordController.text = password;
    });
    showAppSnackBar(context, 'Demo credentials filled');
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await context.read<AuthController>().login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      if (!mounted) return;
      final auth = context.read<AuthController>();
      context.go(auth.isAdmin ? '/admin' : '/menu');
      showAppSnackBar(context, 'Welcome back, ${auth.user?.name ?? ''}');
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
      return;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: GlassPanel(
            child: Column(
              children: [
                Text('Welcome Back', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Sign in to your FoodApp experience', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 24),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    style: filledGoldButtonStyle(minHeight: 52),
                    child: Text(loading ? 'Signing in...' : 'Sign In', style: const TextStyle(color: AppTheme.bgPrimary)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Sign Up"),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  child: DemoCredentialsCard(onUseCredential: useDemoCredential),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await context.read<AuthController>().register(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
            passwordConfirmation: confirmController.text,
          );
      if (!mounted) return;
      context.go('/menu');
      showAppSnackBar(context, 'Welcome, ${context.read<AuthController>().user?.name ?? ''}');
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
      return;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: GlassPanel(
            child: Column(
              children: [
                Text('Create Account', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Join the FoodApp community', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 24),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 14),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 14),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 14),
                TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    style: filledGoldButtonStyle(minHeight: 52),
                    child: Text(loading ? 'Creating Account...' : 'Create Account', style: const TextStyle(color: AppTheme.bgPrimary)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const items = [
    AdminNavItem('Dashboard', '/admin', Icons.pie_chart_outline),
    AdminNavItem('Products', '/admin/products', Icons.grid_view_outlined),
    AdminNavItem('Categories', '/admin/categories', Icons.sell_outlined),
    AdminNavItem('Orders', '/admin/orders', Icons.shopping_bag_outlined),
    AdminNavItem('Users', '/admin/users', Icons.people_outline),
    AdminNavItem('Reports', '/admin/reports', Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mobile = MediaQuery.sizeOf(context).width < 900;
    final drawer = Drawer(
      backgroundColor: AppTheme.bgSecondary,
      child: Column(
        children: [
          const DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text('FoodApp Admin', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.gold)),
            ),
          ),
          ...items.map((item) => ListTile(
                leading: Icon(item.icon, color: location == item.route ? AppTheme.gold : AppTheme.textSecondary),
                title: Text(item.label),
                onTap: () => context.go(item.route),
              )),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Back to Store'),
            onTap: () => context.go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.red),
            title: const Text('Logout'),
            onTap: () async {
              await context.read<AuthController>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    return Scaffold(
      drawer: mobile ? drawer : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!mobile)
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  border: Border(right: BorderSide(color: AppTheme.border)),
                ),
                child: drawer.child,
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary.withValues(alpha: 0.88),
                      border: Border(bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      children: [
                        if (mobile)
                          Builder(
                            builder: (context) => IconButton(
                              onPressed: () => Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
                            ),
                          ),
                        Text('Admin Panel', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(context.watch<AuthController>().user?.name ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool loading = true;
  DashboardData? data;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await context.read<ApiClient>().getMap('/admin/dashboard');
      if (!mounted) return;
      setState(() {
        data = DashboardData.fromJson(response);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    if (data == null) return const Center(child: EmptyState(icon: Icons.warning_amber_outlined, title: 'Dashboard unavailable'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStatCard(title: 'Total Revenue', value: formatCurrency(data!.totalRevenue), color: AppTheme.gold, icon: Icons.payments_outlined),
              AdminStatCard(title: 'Total Orders', value: '${data!.totalOrders}', color: AppTheme.blue, icon: Icons.shopping_bag_outlined),
              AdminStatCard(title: 'Products', value: '${data!.totalProducts}', color: AppTheme.green, icon: Icons.grid_view_outlined),
              AdminStatCard(title: 'Customers', value: '${data!.totalCustomers}', color: AppTheme.purple, icon: Icons.people_outline),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 980;
              return Flex(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Orders by Status', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 18),
                          ...data!.ordersByStatus.map((status) {
                            final ratio = data!.totalOrders == 0 ? 0.0 : status.count / data!.totalOrders;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(status.label),
                                      const Spacer(),
                                      Text('${status.count}', style: const TextStyle(color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: ratio.clamp(0, 1),
                                    minHeight: 10,
                                    color: status.color,
                                    backgroundColor: AppTheme.bgPrimary,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16, height: 16),
                  Expanded(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Popular Products', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 18),
                          ...data!.popularProducts.map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(product.name)),
                                  Text('${product.orderCount} orders', style: const TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Orders', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                AdminTable(
                  columns: const ['Order', 'Customer', 'Amount', 'Status', 'Payment'],
                  rows: data!.recentOrders
                      .map(
                        (order) => [
                          order.orderNumber,
                          order.user?.name ?? '-',
                          formatCurrency(order.totalAmount),
                          order.status,
                          '${order.payment?.method.toUpperCase() ?? '-'} - ${order.payment?.status ?? '-'}',
                        ],
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool loading = true;
  List<Product> products = const [];
  List<Category> categories = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        context.read<ApiClient>().getMap('/admin/products'),
        context.read<ApiClient>().getList('/categories'),
      ]);
      if (!mounted) return;
      setState(() {
        products = asList((results[0] as JsonMap)['data']).map((e) => Product.fromJson(asMap(e))).toList();
        categories = (results[1] as List<dynamic>).map((e) => Category.fromJson(asMap(e))).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await context.read<ApiClient>().delete('/admin/products/$id');
      showAppSnackBar(context, 'Product deleted');
      await load();
    } catch (error) {
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> openForm([Product? product]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ProductFormDialog(product: product, categories: categories),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Products', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800))),
              FilledButton.icon(
                onPressed: () => openForm(),
                style: filledGoldButtonStyle(),
                icon: const Icon(Icons.add, color: AppTheme.bgPrimary),
                label: const Text('Add Product', style: TextStyle(color: AppTheme.bgPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: AdminTable(
              columns: const ['Name', 'Category', 'Price', 'Orders', 'Rating', 'Available', 'Actions'],
              rows: products
                  .map((product) => [
                        product.name,
                        product.category?.name ?? '-',
                        formatCurrency(product.price),
                        '${product.orderCount}',
                        product.avgRating.toStringAsFixed(1),
                        product.isAvailable ? 'Yes' : 'No',
                        '',
                      ])
                  .toList(),
              actionBuilder: (index) => Row(
                children: [
                  IconButton(
                    onPressed: () => openForm(products[index]),
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.blue),
                  ),
                  IconButton(
                    onPressed: () => deleteProduct(products[index].id),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  bool loading = true;
  List<Category> categories = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await context.read<ApiClient>().getList('/admin/categories');
      if (!mounted) return;
      setState(() {
        categories = response.map((e) => Category.fromJson(asMap(e))).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await context.read<ApiClient>().delete('/admin/categories/$id');
      showAppSnackBar(context, 'Category deleted');
      await load();
    } catch (error) {
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> openForm([Category? category]) async {
    await showDialog<void>(context: context, builder: (_) => CategoryFormDialog(category: category));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Categories', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800))),
              FilledButton.icon(
                onPressed: () => openForm(),
                style: filledGoldButtonStyle(),
                icon: const Icon(Icons.add, color: AppTheme.bgPrimary),
                label: const Text('Add Category', style: TextStyle(color: AppTheme.bgPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: AdminTable(
              columns: const ['Name', 'Slug', 'Products', 'Actions'],
              rows: categories.map((c) => [c.name, c.slug, '${c.productsCount}', '']).toList(),
              actionBuilder: (index) => Row(
                children: [
                  IconButton(
                    onPressed: () => openForm(categories[index]),
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.blue),
                  ),
                  IconButton(
                    onPressed: () => deleteCategory(categories[index].id),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  bool loading = true;
  String filter = '';
  List<OrderModel> orders = const [];
  final statuses = const ['pending', 'confirmed', 'preparing', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await context.read<ApiClient>().getMap('/admin/orders', queryParameters: {
        if (filter.isNotEmpty) 'status': filter,
      });
      if (!mounted) return;
      setState(() {
        orders = asList(response['data']).map((e) => OrderModel.fromJson(asMap(e))).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> updateStatus(OrderModel order, String status) async {
    try {
      await context.read<ApiClient>().patch('/admin/orders/${order.id}/status', {'status': status});
      showAppSnackBar(context, 'Order updated to $status');
      await load();
    } catch (error) {
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Orders', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800))),
              DropdownButton<String>(
                value: filter.isEmpty ? null : filter,
                hint: const Text('All Status'),
                dropdownColor: AppTheme.bgSecondary,
                items: statuses
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    filter = value ?? '';
                    loading = true;
                  });
                  unawaited(load());
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order #')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Items')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: orders
                    .map(
                      (order) => DataRow(
                        cells: [
                          DataCell(Text(order.orderNumber)),
                          DataCell(Text(order.user?.name ?? '-')),
                          DataCell(Text(order.orderTypeLabel)),
                          DataCell(Text('${order.items.length} items')),
                          DataCell(Text(formatCurrency(order.totalAmount))),
                          DataCell(Text('${order.payment?.method.toUpperCase() ?? '-'} / ${order.payment?.status ?? '-'}')),
                          DataCell(StatusBadge(status: order.status)),
                          DataCell(
                            DropdownButton<String>(
                              value: order.status,
                              dropdownColor: AppTheme.bgSecondary,
                              items: statuses
                                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) updateStatus(order, value);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  bool loading = true;
  List<UserModel> users = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await context.read<ApiClient>().getMap('/admin/users');
      if (!mounted) return;
      setState(() {
        users = asList(response['data']).map((e) => UserModel.fromJson(asMap(e))).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await context.read<ApiClient>().delete('/admin/users/$id');
      showAppSnackBar(context, 'User deleted');
      await load();
    } catch (error) {
      showAppSnackBar(context, friendlyError(error));
    }
  }

  Future<void> openForm([UserModel? user]) async {
    await showDialog<void>(context: context, builder: (_) => UserFormDialog(user: user));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Users', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800))),
              FilledButton.icon(
                onPressed: () => openForm(),
                style: filledGoldButtonStyle(),
                icon: const Icon(Icons.add, color: AppTheme.bgPrimary),
                label: const Text('Add User', style: TextStyle(color: AppTheme.bgPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: AdminTable(
              columns: const ['Name', 'Email', 'Role', 'Orders', 'Actions'],
              rows: users.map((u) => [u.name, u.email, u.role, '${u.ordersCount}', '']).toList(),
              actionBuilder: (index) => Row(
                children: [
                  IconButton(
                    onPressed: () => openForm(users[index]),
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.blue),
                  ),
                  IconButton(
                    onPressed: () => deleteUser(users[index].id),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  bool loading = true;
  int days = 30;
  SalesReport? sales;
  List<Product> popular = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        context.read<ApiClient>().getMap('/admin/reports/sales', queryParameters: {'days': days}),
        context.read<ApiClient>().getList('/admin/reports/popular'),
      ]);
      if (!mounted) return;
      setState(() {
        sales = SalesReport.fromJson(results[0] as JsonMap);
        popular = (results[1] as List<dynamic>).map((e) => Product.fromJson(asMap(e))).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Reports', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800))),
              DropdownButton<int>(
                value: days,
                dropdownColor: AppTheme.bgSecondary,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                  DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                  DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    days = value;
                    loading = true;
                  });
                  unawaited(load());
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStatCard(title: 'Revenue ($days days)', value: formatCurrency(sales?.totalRevenue ?? 0), color: AppTheme.gold, icon: Icons.payments_outlined),
              AdminStatCard(title: 'Orders ($days days)', value: '${sales?.totalOrders ?? 0}', color: AppTheme.blue, icon: Icons.shopping_bag_outlined),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 980;
              return Flex(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Sales', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          ...sales!.points.map(
                            (point) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(point.date)),
                                  Text(formatCurrency(point.total), style: const TextStyle(color: AppTheme.gold)),
                                  const SizedBox(width: 16),
                                  Text('${point.count} orders', style: const TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16, height: 16),
                  Expanded(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Most Popular Items', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          ...popular.map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(product.name)),
                                  Text('${product.orderItemsCount} orders', style: const TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({super.key, this.product, required this.categories});

  final Product? product;
  final List<Category> categories;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late bool isAvailable;
  int? categoryId;
  PickedUpload? image;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?.name ?? '');
    descriptionController = TextEditingController(text: widget.product?.description ?? '');
    priceController = TextEditingController(text: widget.product?.price.toStringAsFixed(0) ?? '');
    categoryId = widget.product?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    isAvailable = widget.product?.isAvailable ?? true;
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => image = PickedUpload(name: file!.name, bytes: file.bytes!));
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final form = FormData();
      form.fields.add(MapEntry('name', nameController.text.trim()));
      form.fields.add(MapEntry('description', descriptionController.text.trim()));
      form.fields.add(MapEntry('price', priceController.text.trim()));
      form.fields.add(MapEntry('category_id', '$categoryId'));
      form.fields.add(MapEntry('is_available', isAvailable ? '1' : '0'));
      if (image != null) {
        form.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(image!.bytes, filename: image!.name),
        ));
      }
      final api = context.read<ApiClient>();
      if (widget.product == null) {
        await api.post('/admin/products', form, multipart: true);
      } else {
        form.fields.add(const MapEntry('_method', 'PUT'));
        await api.post('/admin/products/${widget.product!.id}', form, multipart: true);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, widget.product == null ? 'Product created' : 'Product updated');
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSecondary,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product == null ? 'New Product' : 'Edit Product', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  dropdownColor: AppTheme.bgSecondary,
                  items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (value) => setState(() => categoryId = value),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (IDR)')),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isAvailable,
                  onChanged: (value) => setState(() => isAvailable = value),
                  title: const Text('Available'),
                ),
                OutlinedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(image?.name ?? 'Upload Image'),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: saving ? null : save,
                      style: filledGoldButtonStyle(),
                      child: Text(saving ? 'Saving...' : 'Save', style: const TextStyle(color: AppTheme.bgPrimary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key, this.category});

  final Category? category;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController nameController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final form = FormData.fromMap({'name': nameController.text.trim()});
      final api = context.read<ApiClient>();
      if (widget.category == null) {
        await api.post('/admin/categories', form, multipart: true);
      } else {
        form.fields.add(const MapEntry('_method', 'PUT'));
        await api.post('/admin/categories/${widget.category!.id}', form, multipart: true);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, widget.category == null ? 'Category created' : 'Category updated');
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category == null ? 'New Category' : 'Edit Category', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: saving ? null : save,
                  style: filledGoldButtonStyle(),
                  child: Text(saving ? 'Saving...' : 'Save', style: const TextStyle(color: AppTheme.bgPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});

  final UserModel? user;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  final passwordController = TextEditingController();
  String role = 'customer';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user?.name ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    role = widget.user?.role ?? 'customer';
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final payload = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': role,
        if (passwordController.text.isNotEmpty || widget.user == null) 'password': passwordController.text,
      };
      final api = context.read<ApiClient>();
      if (widget.user == null) {
        await api.post('/admin/users', payload);
      } else {
        await api.patch('/admin/users/${widget.user!.id}', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, widget.user == null ? 'User created' : 'User updated');
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      showAppSnackBar(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSecondary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user == null ? 'New User' : 'Edit User', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: widget.user == null ? 'Password' : 'Password (leave blank to keep)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                dropdownColor: AppTheme.bgSecondary,
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => role = value ?? 'customer'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: saving ? null : save,
                    style: filledGoldButtonStyle(),
                    child: Text(saving ? 'Saving...' : 'Save', style: const TextStyle(color: AppTheme.bgPrimary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.actionBuilder,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final Widget Function(int index)? actionBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
        rows: List.generate(
          rows.length,
          (index) => DataRow(
            cells: List.generate(
              rows[index].length,
              (cellIndex) {
                if (cellIndex == rows[index].length - 1 && actionBuilder != null) {
                  return DataCell(actionBuilder!(index));
                }
                return DataCell(Text(rows[index][cellIndex]));
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width > 1200 ? 290.0 : 260.0;
    return SizedBox(
      width: width,
      child: GlassPanel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 56, color: AppTheme.gold),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class PillLabel extends StatelessWidget {
  const PillLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.gold,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class HeroStat extends StatelessWidget {
  const HeroStat({super.key, required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.gold),
        ),
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700))),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.gold)
        : const TextStyle(color: AppTheme.textSecondary);
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return _fallbackArtwork();
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          final networkPath = product.networkImagePath;
          if (networkPath.isNotEmpty) {
            return Image.network(
              networkPath,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => _fallbackArtwork(),
            );
          }
          return _fallbackArtwork();
        },
      );
    }
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => _fallbackArtwork(),
    );
  }

  Widget _fallbackArtwork() {
    final icon = switch (product.category?.slug) {
      'beverages' => Icons.local_cafe_outlined,
      'desserts' => Icons.icecream_outlined,
      'snacks' => Icons.fastfood_outlined,
      'specials' => Icons.workspace_premium_outlined,
      _ => Icons.restaurant_menu_outlined,
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1D1B28),
            Color(0xFF12121A),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 52, color: AppTheme.textMuted),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending' => AppTheme.yellow,
      'confirmed' => AppTheme.blue,
      'preparing' => AppTheme.purple,
      'completed' => AppTheme.green,
      'cancelled' => AppTheme.red,
      _ => AppTheme.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class PaymentBadge extends StatelessWidget {
  const PaymentBadge({super.key, required this.payment});

  final PaymentModel? payment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(8)),
          child: Text(payment?.method.toUpperCase() ?? '-', style: const TextStyle(fontSize: 12)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (payment?.status == 'paid' ? AppTheme.green : AppTheme.yellow).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(payment?.status ?? '-', style: TextStyle(color: payment?.status == 'paid' ? AppTheme.green : AppTheme.yellow)),
        ),
      ],
    );
  }
}

class OrderTypeDetails extends StatelessWidget {
  const OrderTypeDetails({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${order.orderTypeLabel}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (order.orderType == 'dine_in') Text('Table Number: ${order.tableNumber ?? '-'}'),
          if (order.orderType == 'delivery') ...[
            Text('Delivery Address: ${order.deliveryAddress ?? '-'}'),
            if (order.deliveryPhotoUrl != null)
              SelectableText(order.deliveryPhotoUrl!, style: const TextStyle(color: AppTheme.blue)),
          ],
        ],
      ),
    );
  }
}

class AdminNavItem {
  const AdminNavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

ButtonStyle filledGoldButtonStyle({Size? minSize, double minHeight = 48}) {
  return FilledButton.styleFrom(
    minimumSize: minSize ?? Size(0, minHeight),
    backgroundColor: AppTheme.gold,
    foregroundColor: AppTheme.bgPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

String formatCurrency(num value) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(value);
}

double responsiveValue(BuildContext context, {required double desktop, required double tablet, required double mobile}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 640) return mobile;
  if (width < 1024) return tablet;
  return desktop;
}

void showAppSnackBar(BuildContext context, String message) {
  showTopNotice(
    context,
    message: message,
    icon: Icons.info_outline,
  );
}

void showAddToCartSnackBar(BuildContext context, String message) {
  showTopNotice(
    context,
    message: message,
    icon: Icons.shopping_bag_outlined,
    actionLabel: 'View Cart',
    onAction: () => context.go('/cart'),
  );
}

void showTopNotice(
  BuildContext context, {
  required String message,
  required IconData icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _TopNoticeOverlay(
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: () {
        entry.remove();
        onAction?.call();
      },
      onDismissed: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

Future<void> showCartPreviewDialog(BuildContext context) async {
  final auth = context.read<AuthController>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppTheme.bgSecondary,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<CartController>(
              builder: (context, cartState, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Your Cart', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (cartState.items.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Your cart is empty. Add some delicious items first.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ] else ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: SingleChildScrollView(
                          child: Column(
                            children: cartState.items
                                .map(
                                  (item) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgPrimary.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 58,
                                            height: 58,
                                            child: ProductImage(product: item.product),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.quantity} x ${formatCurrency(item.product.price)}',
                                                style: const TextStyle(color: AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          formatCurrency(item.subtotal),
                                          style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SummaryRow(label: 'Subtotal (${cartState.totalItems} items)', value: formatCurrency(cartState.totalPrice)),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            context.go('/cart');
                          },
                          child: const Text('Open Cart'),
                        ),
                        FilledButton(
                          onPressed: cartState.items.isEmpty
                              ? null
                              : () {
                                  Navigator.of(dialogContext).pop();
                                  if (auth.user == null) {
                                    showAppSnackBar(context, 'Please sign in first to continue payment');
                                    context.go('/login');
                                    return;
                                  }
                                  context.go('/checkout');
                                },
                          style: filledGoldButtonStyle(),
                          child: Text(
                            auth.user == null ? 'Login to Checkout' : 'Checkout',
                            style: const TextStyle(color: AppTheme.bgPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

String friendlyError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (data is Map && data['errors'] is Map) {
      final values = (data['errors'] as Map).values.toList();
      final firstError = values.isNotEmpty ? values.first : null;
      if (firstError is List && firstError.isNotEmpty) return firstError.first.toString();
    }
  }
  return 'Something went wrong. Please try again.';
}

JsonMap asMap(dynamic value) => (value as Map).map((key, value) => MapEntry(key.toString(), value));
List<dynamic> asList(dynamic value) => value is List ? value : <dynamic>[];
int asInt(dynamic value, {int fallback = 0}) => value is int ? value : int.tryParse('$value') ?? fallback;
double asDouble(dynamic value, {double fallback = 0}) => value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
bool asBool(dynamic value) => value == true || value == 1 || value == '1';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.ordersCount = 0,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final int ordersCount;

  factory UserModel.fromJson(JsonMap json) => UserModel(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'customer',
        ordersCount: asInt(json['orders_count']),
      );

  JsonMap toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'orders_count': ordersCount,
      };
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.productsCount,
  });

  final int id;
  final String name;
  final String slug;
  final int productsCount;

  factory Category.fromJson(JsonMap json) => Category(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        productsCount: asInt(json['products_count']),
      );
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.avgRating,
    required this.orderCount,
    required this.categoryId,
    this.category,
    this.reviews = const [],
    this.isAvailable = true,
    this.orderItemsCount = 0,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final double avgRating;
  final int orderCount;
  final int categoryId;
  final Category? category;
  final List<ReviewModel> reviews;
  final bool isAvailable;
  final int orderItemsCount;

  factory Product.fromJson(JsonMap json) => Product(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: asDouble(json['price']),
        image: json['image']?.toString() ?? '',
        avgRating: asDouble(json['avg_rating'], fallback: 0),
        orderCount: asInt(json['order_count']),
        categoryId: asInt(json['category_id']),
        category: json['category'] is Map ? Category.fromJson(asMap(json['category'])) : null,
        reviews: asList(json['reviews']).map((e) => ReviewModel.fromJson(asMap(e))).toList(),
        isAvailable: json['is_available'] == null ? true : asBool(json['is_available']),
        orderItemsCount: asInt(json['order_items_count']),
      );

  String? get imagePath {
    if (image.isEmpty) return null;
    if (image.startsWith('/images/')) {
      final fileName = image.split('/').last;
      return 'assets/images/$fileName';
    }
    if (image.startsWith('http')) return image;
    if (image.startsWith('/')) return '${AppConfig.apiOrigin}$image';
    return 'assets/catalog/$image';
  }

  String get networkImagePath {
    if (image.isEmpty) return '';
    if (image.startsWith('http')) return image;
    if (image.startsWith('/')) return '${AppConfig.apiOrigin}$image';
    return '${AppConfig.apiOrigin}/storage/$image';
  }
}

class ReviewModel {
  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    this.user,
  });

  final int id;
  final int rating;
  final String comment;
  final UserModel? user;

  factory ReviewModel.fromJson(JsonMap json) => ReviewModel(
        id: asInt(json['id']),
        rating: asInt(json['rating']),
        comment: json['comment']?.toString() ?? '',
        user: json['user'] is Map ? UserModel.fromJson(asMap(json['user'])) : null,
      );
}

class CartItem {
  CartItem({required this.productId, required this.product, required this.quantity});

  final int productId;
  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(productId: productId, product: product, quantity: quantity ?? this.quantity);

  JsonMap toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'product': {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'image': product.image,
          'avg_rating': product.avgRating,
          'order_count': product.orderCount,
          'category_id': product.categoryId,
          'category': product.category == null
              ? null
              : {
                  'id': product.category!.id,
                  'name': product.category!.name,
                  'slug': product.category!.slug,
                  'products_count': product.category!.productsCount,
                },
        },
      };

  factory CartItem.fromJson(JsonMap json) => CartItem(
        productId: asInt(json['product_id']),
        quantity: asInt(json['quantity']),
        product: Product.fromJson(asMap(json['product'])),
      );
}

class OrderItemModel {
  OrderItemModel({
    required this.id,
    required this.quantity,
    required this.subtotal,
    this.product,
  });

  final int id;
  final int quantity;
  final double subtotal;
  final Product? product;

  factory OrderItemModel.fromJson(JsonMap json) => OrderItemModel(
        id: asInt(json['id']),
        quantity: asInt(json['quantity']),
        subtotal: asDouble(json['subtotal']),
        product: json['product'] is Map ? Product.fromJson(asMap(json['product'])) : null,
      );
}

class PaymentModel {
  PaymentModel({
    required this.method,
    required this.status,
    required this.amount,
    this.qrisCode,
  });

  final String method;
  final String status;
  final double amount;
  final String? qrisCode;

  factory PaymentModel.fromJson(JsonMap json) => PaymentModel(
        method: json['method']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        amount: asDouble(json['amount']),
        qrisCode: json['qris_code']?.toString(),
      );
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.orderType,
    required this.items,
    required this.createdAt,
    this.payment,
    this.user,
    this.tableNumber,
    this.deliveryAddress,
    this.deliveryPhoto,
  });

  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String orderType;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final PaymentModel? payment;
  final UserModel? user;
  final String? tableNumber;
  final String? deliveryAddress;
  final String? deliveryPhoto;

  factory OrderModel.fromJson(JsonMap json) => OrderModel(
        id: asInt(json['id']),
        orderNumber: json['order_number']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        totalAmount: asDouble(json['total_amount']),
        orderType: json['order_type']?.toString() ?? 'take_away',
        items: asList(json['items']).map((e) => OrderItemModel.fromJson(asMap(e))).toList(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        payment: json['payment'] is Map ? PaymentModel.fromJson(asMap(json['payment'])) : null,
        user: json['user'] is Map ? UserModel.fromJson(asMap(json['user'])) : null,
        tableNumber: json['table_number']?.toString(),
        deliveryAddress: json['delivery_address']?.toString(),
        deliveryPhoto: json['delivery_photo']?.toString(),
      );

  String get orderTypeLabel => switch (orderType) {
        'dine_in' => 'Dine-in',
        'delivery' => 'Delivery',
        _ => 'Takeaway',
      };

  String? get deliveryPhotoUrl {
    if (deliveryPhoto == null || deliveryPhoto!.isEmpty) return null;
    if (deliveryPhoto!.startsWith('http')) return deliveryPhoto;
    return '${AppConfig.apiOrigin}/storage/$deliveryPhoto';
  }
}

class DashboardData {
  DashboardData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    required this.totalCustomers,
    required this.recentOrders,
    required this.popularProducts,
    required this.ordersByStatus,
  });

  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final int totalCustomers;
  final List<OrderModel> recentOrders;
  final List<Product> popularProducts;
  final List<StatusCount> ordersByStatus;

  factory DashboardData.fromJson(JsonMap json) => DashboardData(
        totalRevenue: asDouble(json['total_revenue']),
        totalOrders: asInt(json['total_orders']),
        totalProducts: asInt(json['total_products']),
        totalCustomers: asInt(json['total_customers']),
        recentOrders: asList(json['recent_orders']).map((e) => OrderModel.fromJson(asMap(e))).toList(),
        popularProducts: asList(json['popular_products']).map((e) => Product.fromJson(asMap(e))).toList(),
        ordersByStatus: asList(json['orders_by_status']).map((e) => StatusCount.fromJson(asMap(e))).toList(),
      );
}

class StatusCount {
  StatusCount({required this.label, required this.count});

  final String label;
  final int count;

  factory StatusCount.fromJson(JsonMap json) => StatusCount(
        label: json['status']?.toString() ?? '',
        count: asInt(json['count']),
      );

  Color get color => switch (label) {
        'pending' => AppTheme.yellow,
        'confirmed' => AppTheme.blue,
        'preparing' => AppTheme.purple,
        'completed' => AppTheme.green,
        'cancelled' => AppTheme.red,
        _ => AppTheme.textSecondary,
      };
}

class SalesReport {
  SalesReport({required this.totalRevenue, required this.totalOrders, required this.points});

  final double totalRevenue;
  final int totalOrders;
  final List<SalesPoint> points;

  factory SalesReport.fromJson(JsonMap json) => SalesReport(
        totalRevenue: asDouble(json['total_revenue']),
        totalOrders: asInt(json['total_orders']),
        points: asList(json['sales']).map((e) => SalesPoint.fromJson(asMap(e))).toList(),
      );
}

class SalesPoint {
  SalesPoint({required this.date, required this.total, required this.count});

  final String date;
  final double total;
  final int count;

  factory SalesPoint.fromJson(JsonMap json) => SalesPoint(
        date: json['date']?.toString() ?? '',
        total: asDouble(json['total']),
        count: asInt(json['count']),
      );
}

class PickedUpload {
  PickedUpload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class MenuStats {
  const MenuStats({
    required this.menuCount,
    required this.totalOrders,
    required this.averageRating,
  });

  final int menuCount;
  final int totalOrders;
  final double averageRating;
}

class DemoCredentialsCard extends StatelessWidget {
  const DemoCredentialsCard({super.key, this.onUseCredential});

  final void Function(String email, String password)? onUseCredential;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Demo:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        DemoCredentialTile(
          label: 'Admin',
          email: 'admin@foodapp.com',
          password: 'password',
          onUse: onUseCredential,
        ),
        const SizedBox(height: 10),
        DemoCredentialTile(
          label: 'Customer',
          email: 'john@example.com',
          password: 'password',
          onUse: onUseCredential,
        ),
      ],
    );
  }
}

class DemoCredentialTile extends StatelessWidget {
  const DemoCredentialTile({
    super.key,
    required this.label,
    required this.email,
    required this.password,
    this.onUse,
  });

  final String label;
  final String email;
  final String password;
  final void Function(String email, String password)? onUse;

  @override
  Widget build(BuildContext context) {
    final combined = '$email / $password';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(combined, style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onUse == null ? null : () => onUse!(email, password),
                icon: const Icon(Icons.flash_on_outlined, size: 16),
                label: const Text('Use'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: combined));
                  if (context.mounted) {
                    showAppSnackBar(context, '$label demo copied');
                  }
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
