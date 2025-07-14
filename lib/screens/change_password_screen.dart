import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String username;
  final String email;

  const ChangePasswordScreen({
    Key? key,
    required this.username,
    required this.email,
  }) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final authService = AuthService();
      final result = await authService.changePassword(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        repeatPassword: _repeatPasswordController.text,
      );
      setState(() {
        _isLoading = false;
      });
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña cambiada exitosamente. Inicia sesión.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error desconocido';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool emailEditable = widget.email.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                enabled: emailEditable,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la nueva contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repeatPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repetir nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Repite la nueva contraseña';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleChangePassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Cambiar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 