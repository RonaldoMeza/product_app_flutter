class Validators {
  static String? validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  static String? validatePrecio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es obligatorio';
    }
    final precio = double.tryParse(value.replaceAll(',', '.'));
    if (precio == null) {
      return 'Ingrese un precio válido';
    }
    if (precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    return null;
  }

  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El stock es obligatorio';
    }
    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Ingrese un stock válido';
    }
    if (stock < 0) {
      return 'El stock debe ser mayor o igual a 0';
    }
    return null;
  }

  static String? validateCategoria(Object? value) {
    if (value == null) {
      return 'Debe seleccionar una categoría';
    }
    if (value is int && value <= 0) {
      return 'Debe seleccionar una categoría';
    }
    return null;
  }
}
