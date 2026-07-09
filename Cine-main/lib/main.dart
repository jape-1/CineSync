// CineSync — punto de entrada.
//
// Arma la inyección de dependencias (cliente HTTP, almacenamiento seguro,
// repositorios y cubits de sesión) y monta `go_router`, que redirige según el
// rol del JWT tras el login.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'core/network/api_client.dart';
import 'features/admin/data/admin_repository.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/checkout/data/checkout_repository.dart';
import 'features/checkout/presentation/checkout_cubit.dart';
import 'features/snacks/data/snacks_repository.dart';
import 'features/staff/data/staff_repository.dart';
import 'features/tickets/data/tickets_repository.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const CineSyncApp());
}

class CineSyncApp extends StatefulWidget {
  const CineSyncApp({super.key});

  @override
  State<CineSyncApp> createState() => _CineSyncAppState();
}

class _CineSyncAppState extends State<CineSyncApp> {
  late final TokenStorage _tokens;
  late final ApiClient _api;
  late final AuthRepository _authRepo;
  late final CatalogRepository _catalogRepo;
  late final SnacksRepository _snacksRepo;
  late final CheckoutRepository _checkoutRepo;
  late final TicketsRepository _ticketsRepo;
  late final StaffRepository _staffRepo;
  late final AdminRepository _adminRepo;

  late final AuthCubit _authCubit;
  late final CheckoutCubit _checkoutCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokens = TokenStorage();
    _api = ApiClient(_tokens);
    _authRepo = AuthRepository(_api, _tokens);
    _catalogRepo = CatalogRepository(_api);
    _snacksRepo = SnacksRepository(_api);
    _checkoutRepo = CheckoutRepository(_api);
    _ticketsRepo = TicketsRepository(_api);
    _staffRepo = StaffRepository(_api);
    _adminRepo = AdminRepository(_api);

    _authCubit = AuthCubit(_authRepo, _tokens)..bootstrap();
    _checkoutCubit = CheckoutCubit(_checkoutRepo);
    _router = buildRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    _checkoutCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _tokens),
        RepositoryProvider.value(value: _authRepo),
        RepositoryProvider.value(value: _catalogRepo),
        RepositoryProvider.value(value: _snacksRepo),
        RepositoryProvider.value(value: _checkoutRepo),
        RepositoryProvider.value(value: _ticketsRepo),
        RepositoryProvider.value(value: _staffRepo),
        RepositoryProvider.value(value: _adminRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider.value(value: _checkoutCubit),
        ],
        child: MaterialApp.router(
          title: 'CineSync',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.bg,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          routerConfig: _router,
        ),
      ),
    );
  }
}
