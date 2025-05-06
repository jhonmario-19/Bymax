import 'package:flutter/material.dart';

class FamilyOptions extends StatelessWidget {
  final bool createNewFamily;
  final TextEditingController newFamilyNameController;
  final List<Map<String, dynamic>> families;
  final String? selectedFamilyId;
  final bool isLoadingFamilies;
  final VoidCallback onCreateNewFamily;
  final VoidCallback onAssignExistingFamily;
  final Function(String?) onFamilySelected;

  const FamilyOptions({
    super.key,
    required this.createNewFamily,
    required this.newFamilyNameController,
    required this.families,
    required this.selectedFamilyId,
    required this.isLoadingFamilies,
    required this.onCreateNewFamily,
    required this.onAssignExistingFamily,
    required this.onFamilySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFamilyOption(
              icon: Icons.group,
              label: 'Asignar a familia existente',
              isSelected: !createNewFamily,
              onTap: onAssignExistingFamily,
            ),
            const SizedBox(width: 12),
            _buildFamilyOption(
              icon: Icons.group_add,
              label: 'Crear nueva familia',
              isSelected: createNewFamily,
              onTap: onCreateNewFamily,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (createNewFamily)
          _buildTextField(
            controller: newFamilyNameController,
            label: 'Nombre de la nueva familia',
            icon: Icons.add_home,
          )
        else if (isLoadingFamilies)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF03d069)),
          )
        else if (families.isEmpty)
          const Center(
            child: Text('No hay familias disponibles. Cree una nueva.'),
          )
        else
          DropdownButtonFormField<String>(
            value: selectedFamilyId,
            decoration: const InputDecoration(
              border: InputBorder.none,
              labelText: 'Seleccionar familia',
              prefixIcon: Icon(Icons.family_restroom, color: Color(0xFF03d069)),
            ),
            items:
                families.map((family) {
                  return DropdownMenuItem<String>(
                    value: family['id'],
                    child: Text(family['nombre']),
                  );
                }).toList(),
            onChanged: onFamilySelected,
          ),
      ],
    );
  }

  Widget _buildFamilyOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF03d069).withOpacity(0.2)
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(color: const Color(0xFF03d069), width: 2)
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF03d069) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF03d069) : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
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
