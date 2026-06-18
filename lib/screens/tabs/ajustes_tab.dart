import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_db_service.dart';
import '../../services/supabase_service.dart';

class AjustesTab extends StatefulWidget {
  const AjustesTab({super.key});
  @override
  State<AjustesTab> createState() => _AjustesTabState();
}

class _AjustesTabState extends State<AjustesTab> {
  bool _modoLectura = true;
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
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
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
                      borderRadius: BorderRadius.circular(16),
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: Theme.of(context).scaffoldBackgroundColor,
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
                                  fontWeight: FontWeight.w800,
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
                  ),
                  const SizedBox(height: 36),
                  _buildSectionHeader('APARIENCIA'),
                  _buildSettingsCard(context, [
                    _SwitchTile(
                      titulo: 'Modo Oscuro',
                      subtitulo: 'Cambia el tema visual',
                      icono: Icons.dark_mode_rounded,
                      valor: themeProvider.isDarkMode,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        themeProvider.toggleTheme(val);
                      },
                    ),
                    _buildDivider(context),
                    _SwitchTile(
                      titulo: 'Modo Lectura',
                      subtitulo: 'Optimiza el contraste y fuentes',
                      icono: Icons.menu_book_rounded,
                      valor: _modoLectura,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _modoLectura = val);
                      },
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader('ALMACENAMIENTO Y DATOS'),
                  _buildSettingsCard(context, [
                    _ActionTile(
                      titulo: 'Espacio Ocupado',
                      icono: Icons.storage_rounded,
                      colorIcono: Colors.green,
                      trailingText: _cacheSize,
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                    ),
                    _buildDivider(context),
                    _ActionTile(
                      titulo: 'Borrar Caché Local',
                      icono: Icons.delete_sweep_rounded,
                      colorIcono: CupertinoColors.destructiveRed,
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
                  ]),
                ],
              ),
            ),
          ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
      indent: 56,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool valor;
  final Function(bool) onChanged;
  const _SwitchTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeColor: Theme.of(context).primaryColor,
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).primaryColor.withOpacity(0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      secondary: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 20,
        ),
      ),
      value: valor,
      onChanged: onChanged,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorIcono,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: Colors.white, size: 20),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Flexible(
              child: Text(
                trailingText!,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (trailingText != null) const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
        ],
      ),
      onTap: onTap,
    );
  }
}
