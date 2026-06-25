# 📦 ProductApp — Gestor de Inventario

Aplicación móvil desarrollada en **Flutter** que combina almacenamiento local con **SQLite** y consumo de la **API pública DummyJSON** para gestionar productos y categorías de inventario.

---

## ✨ Funcionalidades

- **CRUD completo** de productos y categorías (Crear, Leer, Actualizar, Eliminar)
- **Importación desde API pública** (DummyJSON) con sincronización inteligente
- **Persistencia local** con SQLite — funciona sin internet después de la sincronización
- **Protección de ediciones locales** — los productos editados manualmente no se sobrescriben al resincronizar
- **Dashboard interactivo** con estadísticas del inventario
- **Búsqueda y filtros** por nombre y categoría
- **Detección de bajo stock** con umbral configurable
- **Validación de formularios** en tiempo real
- **Material Design 3** con tema dinámico

---

## 🧱 Arquitectura

```
lib/
├── main.dart                       # Punto de entrada y tema global
├── models/                         # Modelos de datos (POJO con toMap/fromMap)
│   ├── categoria.dart
│   └── producto.dart
├── database/                       # Gestión de SQLite
│   └── db_helper.dart              # Conexión, schema y migraciones
├── services/                       # Servicios externos
│   └── api_service.dart            # Cliente HTTP para DummyJSON
├── repositories/                   # Capa de acceso a datos + lógica de negocio
│   ├── categoria_repository.dart   # CRUD + sync de categorías
│   └── producto_repository.dart    # CRUD + sync de productos
├── screens/                        # Pantallas de la UI
│   ├── home_screen.dart            # Dashboard principal con navegación
│   ├── sync_screen.dart            # Pantalla de sincronización con API
│   ├── producto_list_screen.dart   # Lista de productos con búsqueda/filtros
│   ├── producto_form_screen.dart   # Formulario de producto
│   ├── categoria_list_screen.dart  # Lista de categorías
│   └── categoria_form_screen.dart  # Formulario de categoría
├── widgets/                        # Componentes reutilizables
│   ├── producto_card.dart          # Tarjeta de producto con imagen
│   ├── dashboard_card.dart         # Tarjeta con animación para el dashboard
│   └── sync_status_card.dart       # Estado de sincronización
└── utils/                          # Utilidades
    └── validators.dart             # Validaciones de formularios
```

---

## ⚙️ Tecnologías y Dependencias

| Paquete       | Versión | Propósito |
|---------------|---------|-----------|
| `sqflite`     | ^2.4.1  | Base de datos SQLite local |
| `path_provider` | ^2.1.5 | Obtener directorios del sistema |
| `path`        | ^1.9.0  | Manipulación de rutas de archivos |
| `http`        | ^1.2.0  | Cliente HTTP para consumo de API |
| `cupertino_icons` | ^1.0.8 | Iconos adicionales |

### Stack

- **Lenguaje:** Dart 3.9+
- **Framework:** Flutter con Material Design 3
- **Base de datos:** SQLite (vía `sqflite`)
- **API:** DummyJSON (pública y gratuita)
- **Patrón:** Arquitectura por capas (Models → Services → Repositories → Screens)

---

## 🚀 Instalación y Ejecución

### Requisitos

- Flutter SDK 3.9+ ([descargar](https://docs.flutter.dev/get-started/install))
- Dispositivo o emulador Android/iOS

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/RonaldoMeza/product_app_flutter.git
cd product_app_flutter

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo debug
flutter run
```

Para generar un APK de producción:

```bash
flutter build apk --release
```

---

## 🌐 Consumo de API

La aplicación consume la **API pública de DummyJSON** para importar datos iniciales.

### Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `https://dummyjson.com/products?limit=100` | Obtiene 100 productos |
| `GET` | `https://dummyjson.com/products/categories` | Obtiene todas las categorías |

### Flujo de Sincronización

```
Usuario → SyncScreen → ApiService.fetchCategories()
                     → CategoriaRepository.syncFromApi() → SQLite
                     → ApiService.fetchProducts()
                     → ProductoRepository.syncFromApi()  → SQLite
                     → Mostrar resultados
```

---

## 💾 Base de Datos SQLite

### Schema (versión 2)

```sql
-- Tabla de categorías
CREATE TABLE categorias (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre      TEXT NOT NULL,
  descripcion TEXT,
  color       TEXT,
  remoteId    TEXT,        -- ID del registro en la API (slug)
  source      TEXT,        -- Origen: 'dummyjson' | 'local'
  syncedAt    TEXT         -- Fecha ISO de última sincronización
);

-- Tabla de productos
CREATE TABLE productos (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre          TEXT NOT NULL,
  descripcion     TEXT,
  precio          REAL NOT NULL,
  stock           INTEGER NOT NULL,
  imagenUrl       TEXT,
  categoriaId     INTEGER NOT NULL,
  fechaCreacion   TEXT NOT NULL,
  remoteId        TEXT,            -- ID del registro en la API
  source          TEXT,            -- Origen: 'dummyjson' | 'local'
  syncedAt        TEXT,            -- Fecha ISO de última sincronización
  isLocalEdited   INTEGER DEFAULT 0, -- 1 si el usuario editó manualmente
  FOREIGN KEY (categoriaId) REFERENCES categorias(id) ON DELETE CASCADE
);
```

### Consulta JOIN utilizada

```sql
SELECT p.*, c.nombre AS categoriaNombre, c.color AS categoriaColor
FROM productos p
INNER JOIN categorias c ON p.categoriaId = c.id
ORDER BY p.fechaCreacion DESC;
```

---

## 🔄 Mecanismo Anti-Duplicados

Para evitar duplicados al sincronizar múltiples veces, cada registro importado almacena:

| Campo       | Descripción                              | Ejemplo                    |
|-------------|------------------------------------------|----------------------------|
| `remoteId`  | ID proporcionado por la API              | `"smartphones"` o `"1"`    |
| `source`    | Origen del registro                      | `"dummyjson"`              |

Antes de insertar, se verifica:

```sql
SELECT * FROM productos WHERE remoteId = ? AND source = 'dummyjson';
```

Si existe → se actualiza (si `isLocalEdited == 0`).  
Si no existe → se inserta.

---

## ✋ Protección de Ediciones Locales

Cuando un usuario edita un producto importado desde la API:

1. El repositorio marca `isLocalEdited = 1` al guardar los cambios.
2. En la siguiente sincronización, si `isLocalEdited == 1`, el producto **no se sobrescribe**.
3. Esto permite que el usuario tenga control total sobre sus modificaciones.

---

## 📱 Pantallas

| Pantalla | Descripción |
|----------|-------------|
| **Dashboard** | Resumen con total de productos, categorías, bajo stock y valor del inventario. Incluye estado de sincronización y botón para importar datos. |
| **Productos** | Lista con búsqueda en tiempo real y filtro por categoría. Cada producto muestra imagen, precio y nivel de stock. |
| **Categorías** | Lista con indicador visual de color. Las categorías importadas muestran un icono de nube. |
| **Sincronización** | Botón para importar desde API. Muestra progreso, resultados y errores de conexión. |
| **Formularios** | Creación y edición de productos y categorías con validaciones en tiempo real. |

---

## 🧪 Validaciones

| Campo      | Reglas                                        |
|------------|-----------------------------------------------|
| Nombre     | Obligatorio, mínimo 2 caracteres              |
| Precio     | Obligatorio, mayor a 0                        |
| Stock      | Obligatorio, mayor o igual a 0                |
| Categoría  | Obligatorio (selección requerida)             |
| URL imagen | Opcional, formato URL válido                  |

---

## 🛠️ Desarrollo

### Análisis de código

```bash
flutter analyze
```

### Limpiar proyecto

```bash
flutter clean
flutter pub get
```

### Generar documentación

Esta documentación se encuentra en los archivos `README.md` y `DOCUMENTACION.md`.

---

## 📄 Licencia

Este proyecto está bajo la licencia **MIT**. Consulte el archivo `LICENSE` para más información.

---

## 👨‍💻 Autor

Desarrollado como proyecto de aprendizaje sobre integración de **SQLite** y **consumo de APIs REST** en Flutter.

---

## 📬 Contacto

Si tienes preguntas o sugerencias, no dudes en abrir un issue en el repositorio.
