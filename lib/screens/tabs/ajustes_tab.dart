import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_db_service.dart';
import '../../services/supabase_service.dart';
import '../../services/biometric_service.dart';
import '../../services/light_sensor_service.dart';

class AjustesTab extends StatefulWidget {
  const AjustesTab({super.key});
  @override
  State<AjustesTab> createState() => _AjustesTabState();
}

class _AjustesTabState extends State<AjustesTab> {
  bool _modoLectura = true;
  bool _bloqueoApp = false;
  bool _brilloAdaptable = true;
  Color _accentColor = CupertinoColors.activeBlue;

  String _cacheSize = 'Calculando...';

  @override
  void initState() {
    super.initState();
    _actualizarTamanoCache();
  }

  void _actualizarTamanoCache() {
    setState(() {
      try {
        _cacheSize = LocalDbService.obtenerTamanoCache();
      } catch (e) {
        _cacheSize = '0 MB';
      }
    });
  }

  void _toggleBiometria(bool val) async {
    HapticFeedback.mediumImpact();
    if (val) {
      final autenticado = await BiometricService.authenticate();
      if (mounted) setState(() => _bloqueoApp = autenticado);
    } else {
      if (mounted) setState(() => _bloqueoApp = false);
    }
  }

  void _toggleBrilloAdaptable(bool val) {
    HapticFeedback.lightImpact();
    setState(() => _brilloAdaptable = val);
    if (val) {
      LightSensorService().startListening();
    } else {
      LightSensorService().stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 140.0,
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 25, sigmaY: 25), // Regla 1: Glassmorphism
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Ajustes',
                      style: TextStyle(
                        fontSize: 34, // Regla 2: Large Titles
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 140.0),
              sliver: SliverList.list(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(20), // Regla 3: Squarcles
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            CupertinoIcons.person_solid,
                            size: 36,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mi Cuenta',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: Theme.of(context).primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                SupabaseService
                                        .client.auth.currentUser?.email ??
                                    'Usuario Invitado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 36),
                  _buildSectionHeader('SEGURIDAD Y PRIVACIDAD')
                      .animate()
                      .fade(delay: 100.ms),
                  _buildSettingsCard(context, [
                    _CupertinoSwitchTile(
                      titulo: 'Bloqueo de App (Face ID)',
                      icono: CupertinoIcons.lock_shield_fill,
                      colorFondoIcono: CupertinoColors.systemGreen,
                      valor: _bloqueoApp,
                      onChanged: _toggleBiometria,
                    ),
                  ]).animate().fade(delay: 150.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 32),
                  _buildSectionHeader('APARIENCIA')
                      .animate()
                      .fade(delay: 200.ms),
                  _buildSettingsCard(context, [
                    _CupertinoSwitchTile(
                      titulo: 'Modo Oscuro',
                      icono: CupertinoIcons.moon_fill,
                      colorFondoIcono: CupertinoColors.systemIndigo,
                      valor: themeProvider.isDarkMode,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        themeProvider.toggleTheme(val);
                      },
                    ),
                    _buildDivider(context),
                    _CupertinoSwitchTile(
                      titulo: 'Brillo Adaptable',
                      icono: CupertinoIcons.brightness_solid,
                      colorFondoIcono: CupertinoColors.systemYellow,
                      valor: _brilloAdaptable,
                      onChanged: _toggleBrilloAdaptable,
                    ),
                    _buildDivider(context),
                    _CupertinoSwitchTile(
                      titulo: 'Modo Lectura',
                      icono: CupertinoIcons.book_fill,
                      colorFondoIcono: CupertinoColors.systemOrange,
                      valor: _modoLectura,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _modoLectura = val);
                      },
                    ),
                    _buildDivider(context),
                    _buildColorModifier(),
                  ]).animate().fade(delay: 250.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 32),
                  _buildSectionHeader('ALMACENAMIENTO Y DATOS')
                      .animate()
                      .fade(delay: 300.ms),
                  _buildSettingsCard(context, [
                    _ActionTile(
                      titulo: 'Espacio Ocupado',
                      icono: CupertinoIcons.device_phone_portrait,
                      colorIcono: CupertinoColors.systemBlue,
                      trailingText: _cacheSize,
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                    ),
                    _buildDivider(context),
                    _ActionTile(
                      titulo: 'Borrar Caché Local',
                      icono: CupertinoIcons.trash_fill,
                      colorIcono: CupertinoColors.systemRed,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await LocalDbService.limpiarCache();
                        _actualizarTamanoCache();
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Caché eliminada 🧹'),
                              backgroundColor: Theme.of(context).cardColor,
                            ),
                          );
                      },
                    ),
                  ]).animate().fade(delay: 350.ms).slideY(begin: 0.05, end: 0),
                ],
              ),
            ),
          ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  Widget _buildColorModifier() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.paintbrush_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Color de Acento',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  letterSpacing: -0.3),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoColors.activeBlue,
                CupertinoColors.systemPurple,
                CupertinoColors.systemRed,
                CupertinoColors.systemGreen,
              ].map((color) {
                final isSelected = _accentColor == color;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _accentColor = color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 8),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: isSelected ? 2 : 0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CupertinoSwitchTile extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorFondoIcono;
  final bool valor;
  final Function(bool) onChanged;

  const _CupertinoSwitchTile({
    required this.titulo,
    required this.icono,
    required this.colorFondoIcono,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorFondoIcono,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  letterSpacing: -0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CupertinoSwitch(
            value: valor,
            activeColor: CupertinoColors.activeGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final String? trailingText;
  final VoidCallback onTap;
  const _ActionTile({
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorIcono,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    letterSpacing: -0.3),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null)
                  Flexible(
                    child: Text(
                      trailingText!,
                      style: const TextStyle(
                          color: CupertinoColors.systemGrey, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (trailingText != null) const SizedBox(width: 4),
                Icon(CupertinoIcons.chevron_forward,
                    color: Colors.grey.withOpacity(0.5), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
