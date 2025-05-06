import 'package:flutter/material.dart';

class UserForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController birthDateController;
  final TextEditingController idNumberController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Function(String) onNameChanged;
  final VoidCallback onGenerateCredentials;
  final VoidCallback onSelectBirthDate;

  const UserForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.birthDateController,
    required this.idNumberController,
    required this.usernameController,
    required this.passwordController,
    required this.onNameChanged,
    required this.onGenerateCredentials,
    required this.onSelectBirthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: nameController,
          label: 'Nombre completo',
          icon: Icons.person,
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: emailController,
          label: 'Correo electrónico',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: phoneController,
          label: 'Teléfono',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: addressController,
          label: 'Dirección',
          icon: Icons.home,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: birthDateController,
          label: 'Fecha de nacimiento',
          icon: Icons.calendar_today,
          keyboardType: TextInputType.none,
          onTap: onSelectBirthDate,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: idNumberController,
          label: 'Número de identificación',
          icon: Icons.badge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: usernameController,
                label: 'Nombre de usuario',
                icon: Icons.person_outline,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF03d069)),
              onPressed: onGenerateCredentials,
              tooltip: 'Regenerar credenciales',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outline,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF03d069)),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
