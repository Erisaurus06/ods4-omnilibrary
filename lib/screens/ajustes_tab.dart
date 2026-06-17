import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';

void _mostrarVincularGoogleBooks(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books, size: 60, color: Colors.blue[400]),
            const SizedBox(height: 16),
            Text(
              'Vincular Google Play Books',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Al vincular tu cuenta, OmniLibrary podrá acceder a tus libros comprados y ePubs sincronizados usando la API oficial de Google Books OAuth 2.0.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Autenticar con Google'),
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Integración con Google temporalmente deshabilitada.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SeccionAjustes extends StatefulWidget {
  const SeccionAjustes({super.key});

  @override
  State<SeccionAjustes> createState() => _SeccionAjustesState();
}

class _SeccionAjustesState extends State<SeccionAjustes> {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 80,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
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
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        SupabaseService.client.auth.currentUser?.email ??
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
          _buildSectionHeader('CUENTA'),
          _buildSettingsCard(context, [
            _ActionTile(
              titulo: 'Sincronización en la Nube',
              icono: Icons.cloud_sync,
              colorIcono: Colors.indigo,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronización activada.')),
                );
              },
            ),
            _buildDivider(context),
            _ActionTile(
              titulo: 'Cerrar Sesión',
              icono: Icons.logout,
              colorIcono: Colors.redAccent,
              onTap: () => _confirmarCerrarSesion(context),
            ),
          ]),
          const SizedBox(height: 32),
          _buildSectionHeader('APARIENCIA'),
          _buildSettingsCard(context, [
            _SwitchTile(
              titulo: 'Modo Oscuro',
              subtitulo: 'Cambia el tema visual',
              icono: Icons.dark_mode_rounded,
              valor: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            _buildDivider(context),
            _SwitchTile(
              titulo: 'Modo Lectura',
              subtitulo: 'Optimiza el contraste y fuentes',
              icono: Icons.menu_book_rounded,
              valor: _modoLectura,
              onChanged: (val) => setState(() => _modoLectura = val),
            ),
          ]),
          const SizedBox(height: 32),
          _buildSectionHeader('INTEGRACIONES Y APIS'),
          _buildSettingsCard(context, [
            _ApiTile(
              titulo: 'Google Play Books',
              subtitulo: 'Sincroniza tu biblioteca',
              icono: Icons.library_books_rounded,
              conectado: false,
              onTap: () => _mostrarVincularGoogleBooks(context),
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
              onTap: () {},
            ),
            _buildDivider(context),
            _ActionTile(
              titulo: 'Borrar Caché Local',
              icono: Icons.delete_sweep_rounded,
              colorIcono: Colors.orange,
              onTap: () async {
                await LocalDbService.limpiarCache();
                _actualizarTamanoCache();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Caché eliminada correctamente 🧹'),
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
          _buildSectionHeader('ACERCA DE'),
          _buildSettingsCard(context, [
            _ActionTile(
              titulo: 'Versión de la App',
              icono: Icons.info_outline_rounded,
              colorIcono: Colors.blueGrey,
              trailingText: '1.0.0 (Estable)',
              onTap: () {},
            ),
            _buildDivider(context),
            _ActionTile(
              titulo: 'Términos y Privacidad',
              icono: Icons.shield_outlined,
              colorIcono: Colors.teal,
              onTap: () async {
                final uri = Uri.parse(
                  'https://www.google.com/policies/privacy/',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.inAppWebView);
                }
              },
            ),
          ]),
          const SizedBox(height: 120),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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

  void _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Salir',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await SupabaseService.client.auth.signOut();
    }
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

class _ApiTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool conectado;
  final VoidCallback? onTap;
  const _ApiTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.conectado,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: conectado ? primaryColor : Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 20,
        ),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(fontSize: 13, color: primaryColor.withOpacity(0.6)),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
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
