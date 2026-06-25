# Documentación del Proyecto ProductApp

## Índice

1. [Descripción General](#1-descripción-general)
2. [Arquitectura del Proyecto](#2-arquitectura-del-proyecto)
3. [Dependencias Utilizadas](#3-dependencias-utilizadas)
4. [Estructura de Archivos](#4-estructura-de-archivos)
5. [Modelos de Datos (Models)](#5-modelos-de-datos-models)
6. [Base de Datos SQLite (DBHelper)](#6-base-de-datos-sqlite-dbhelper)
7. [Consumo de API (ApiService)](#7-consumo-de-api-apiservice)
8. [Repositorios (Repositories)](#8-repositorios-repositories)
9. [Pantallas (Screens)](#9-pantallas-screens)
10. [Widgets Reutilizables](#10-widgets-reutilizables)
11. [Validaciones](#11-validaciones)
12. [Flujo Completo de la Aplicación](#12-flujo-completo-de-la-aplicación)
13. [Flujo de Sincronización API → SQLite](#13-flujo-de-sincronización-api--sqlite)
14. [Mecanismo Anti-Duplicados](#14-mecanismo-anti-duplicados)
15. [Preguntas Frecuentes para la Presentación](#15-preguntas-frecuentes-para-la-presentación)

---

## 1. Descripción General

**ProductApp** es una aplicación móvil desarrollada en **Flutter** (Dart) que funciona como un **gestor de inventario**. Permite:

- Administrar **productos** y **categorías** de forma local con SQLite.
- **Importar datos** desde una API pública (DummyJSON).
- **Sincronizar** datos de la API con la base de datos local evitando duplicados.
- **CRUD completo** (Crear, Leer, Actualizar, Eliminar) sobre productos y categorías.
- **Buscar y filtrar** productos por nombre y categoría.
- Visualizar un **dashboard** con estadísticas del inventario.

### Relación entre entidades

```
Categoría (1) ────── tiene ────── (N) Productos
```

Una categoría puede tener muchos productos. Cada producto pertenece a una sola categoría.

---

## 2. Arquitectura del Proyecto

El proyecto sigue una arquitectura en **capas**:

```
lib/
├── main.dart                     → Punto de entrada
├── models/                       → Modelos de datos (Dart POJO)
├── database/                     → Gestión de SQLite (conexión, schema, migraciones)
├── services/                     → Servicios externos (API HTTP)
├── repositories/                 → Capa de acceso a datos (CRUD + lógica de sync)
├── screens/                      → Pantallas de la UI
├── widgets/                      → Componentes visuales reutilizables
└── utils/                        → Utilidades (validaciones)
```

### Flujo de dependencias

```
UI (Screens) → Repositories → DBHelper → SQLite
                            ↘ ApiService → DummyJSON API
```

Las **pantallas** nunca acceden directamente a la base de datos ni a la API. Siempre se comunican a través de los **repositorios**, que contienen toda la lógica de negocio.

---

## 3. Dependencias Utilizadas

### `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.4.1              # SQLite para Flutter
  path: ^1.9.0                  # Manipulación de rutas de archivos
  path_provider: ^2.1.5        # Obtener directorios del sistema
  http: ^1.2.0                 # Cliente HTTP para llamadas API
```

| Dependencia         | ¿Para qué sirve?                                                    |
|---------------------|----------------------------------------------------------------------|
| **sqflite**         | Base de datos SQLite local en dispositivos móviles                  |
| **path**            | Unir rutas de archivos (ej: unir directorio con nombre del archivo DB) |
| **path_provider**   | Obtener el directorio de documentos de la aplicación para guardar la DB |
| **http**            | Realizar peticiones HTTP GET a la API de DummyJSON                  |
| **cupertino_icons** | Iconos estilo iOS (opcional, para Material Icons adicionales)       |

---

## 4. Estructura de Archivos

### 4.1 `lib/main.dart` — Punto de entrada

**¿Qué hace?**
- Inicializa Flutter con `WidgetsFlutterBinding.ensureInitialized()`.
- Configura el manejo global de errores.
- Define el tema Material 3 de la aplicación.
- Muestra el `AppInitializer` que decide si ir a la pantalla de sincronización o al home.

**Flujo de inicio:**
1. Se llama a `DBHelper.instance.database` para abrir/crear la base de datos.
2. Se consultan las categorías existentes con `CategoriaRepository().getAll()`.
3. Si **no hay datos** → muestra `SyncScreen(firstTime: true)` para invitar al usuario a importar.
4. Si **ya hay datos** → muestra `HomeScreen` directamente.

**Fragmento clave:**
```dart
Future<void> _init() async {
  await DBHelper.instance.database;
  final categorias = await CategoriaRepository().getAll();
  if (categorias.isNotEmpty) {
    // Ir al Home
  } else {
    // Ir a SyncScreen
  }
}
```

### 4.2 `lib/models/categoria.dart` — Modelo Categoría

**¿Qué contiene?**
```dart
class Categoria {
  int? id;              // ID autogenerado por SQLite (AUTOINCREMENT)
  String nombre;        // Nombre de la categoría
  String? descripcion;  // Descripción opcional
  String? color;        // Color hexadecimal (ej: "#2196F3")
  String? remoteId;     // ID remoto desde la API (slug de DummyJSON)
  String? source;       // Origen: "dummyjson" o "local"
  String? syncedAt;     // Fecha ISO de última sincronización
}
```

**Métodos:**
- `toMap()` → Convierte el objeto a `Map<String, dynamic>` para insertar en SQLite.
- `Categoria.fromMap(map)` → Constructor factory que crea un `Categoria` desde un mapa de SQLite.

### 4.3 `lib/models/producto.dart` — Modelo Producto

**¿Qué contiene?**
```dart
class Producto {
  int? id;               // ID autogenerado por SQLite
  String nombre;         // Nombre del producto
  String? descripcion;   // Descripción
  double precio;         // Precio
  int stock;             // Cantidad en stock
  String? imagenUrl;     // URL de la imagen del producto
  int categoriaId;       // FK → categorias.id
  String fechaCreacion;  // Fecha ISO de creación
  String? remoteId;      // ID remoto desde la API
  String? source;        // Origen: "dummyjson" o "local"
  String? syncedAt;      // Fecha de última sincronización
  int isLocalEdited;     // 0 = no editado, 1 = editado localmente

  // Campos JOIN (no se guardan en DB, vienen de la consulta)
  String? categoriaNombre;
  String? categoriaColor;
}
```

**Propiedad calculada:**
```dart
String get stockLabel {
  if (stock <= 0) return 'Agotado';
  if (stock <= 10) return 'Bajo stock';
  return 'Disponible';
}
```

### 4.4 `lib/database/db_helper.dart` — Gestor de Base de Datos

**¿Qué hace?**
- Patrón **Singleton**: `DBHelper.instance` para tener una única instancia.
- Abre la base de datos `product_app.db` en el directorio de documentos.
- Maneja la **creación inicial** de tablas (`onCreate`) y **migraciones** (`onUpgrade`).

**Schema de la base de datos (versión 2):**

```sql
CREATE TABLE categorias (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  color TEXT,
  remoteId TEXT,
  source TEXT,
  syncedAt TEXT
);

CREATE TABLE productos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio REAL NOT NULL,
  stock INTEGER NOT NULL,
  imagenUrl TEXT,
  categoriaId INTEGER NOT NULL,
  fechaCreacion TEXT NOT NULL,
  remoteId TEXT,
  source TEXT,
  syncedAt TEXT,
  isLocalEdited INTEGER DEFAULT 0,
  FOREIGN KEY (categoriaId) REFERENCES categorias(id) ON DELETE CASCADE
);
```

**Migración (v1 → v2):**
Cuando se actualiza desde una versión anterior (sin los campos nuevos), se ejecutan `ALTER TABLE` para agregar las columnas `remoteId`, `source`, `syncedAt` e `isLocalEdited`.

**Métodos:**
- `database` (getter) → Obtiene la instancia de la base de datos, creándola si es necesario.
- `close()` → Cierra la conexión.

### 4.5 `lib/services/api_service.dart` — Servicio de API

**¿Qué hace?**
- Se conecta a la API pública **DummyJSON** (`https://dummyjson.com`).
- Obtiene productos y categorías en formato JSON.
- Convierte las respuestas a `List<Map<String, dynamic>>`.

**Endpoints consumidos:**

| Método | Endpoint                                  | ¿Qué devuelve?                           |
|--------|-------------------------------------------|------------------------------------------|
| GET    | `https://dummyjson.com/products?limit=100` | Lista de 100 productos con su categoría  |
| GET    | `https://dummyjson.com/products/categories` | Lista de categorías con slug y nombre    |

**Estructura de la respuesta de productos (DummyJSON):**
```json
{
  "products": [
    {
      "id": 1,
      "title": "iPhone 9",
      "description": "An apple mobile which is nothing like apple",
      "price": 549,
      "stock": 94,
      "category": "smartphones",
      "thumbnail": "https://cdn.dummyjson.com/..."
    }
  ]
}
```

**Estructura de la respuesta de categorías (DummyJSON):**
```json
[
  { "slug": "beauty", "name": "Beauty", "url": "..." },
  { "slug": "fragrances", "name": "Fragrances", "url": "..." }
]
```

**Manejo de errores:**
- Si la respuesta HTTP no es 200, lanza una `ApiException` con el código de error.
- Si no hay conexión a internet, el catch en `SyncScreen` captura el error y lo muestra al usuario.

**Fragmento clave:**
```dart
Future<List<Map<String, dynamic>>> fetchProducts({int limit = 100}) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/products?limit=$limit'),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['products']);
  }
  throw ApiException('Error al obtener productos: ${response.statusCode}');
}
```

### 4.6 `lib/repositories/categoria_repository.dart` — Repositorio de Categorías

**¿Qué hace?**
- Capa intermedia entre las pantallas y la base de datos.
- Implementa operaciones CRUD completas.
- Contiene la lógica de **sincronización** con la API.

**Métodos:**

| Método                          | ¿Qué hace?                                                     |
|---------------------------------|----------------------------------------------------------------|
| `getAll()`                      | Obtiene todas las categorías ordenadas por nombre              |
| `getById(id)`                   | Obtiene una categoría por su ID                                |
| `insert(categoria)`             | Inserta una nueva categoría                                    |
| `update(categoria)`             | Actualiza una categoría existente                              |
| `delete(id)`                    | Elimina una categoría y sus productos asociados                |
| `hasProducts(id)`               | Verifica si una categoría tiene productos asociados            |
| `getRemoteIdMapping()`          | Obtiene un mapa {remoteId → localId} de categorías importadas |
| `syncFromApi(apiCategories)`    | Sincroniza categorías desde la API hacia SQLite                |
| `getLastSyncAt()`               | Obtiene la fecha de la última sincronización                   |
| `countImported()`               | Cuenta cuántas categorías fueron importadas desde API          |

**Lógica de `syncFromApi`:**
1. Para cada categoría de la API, verifica si ya existe en SQLite buscando por `remoteId` y `source = 'dummyjson'`.
2. Si **no existe** → la inserta con `source = 'dummyjson'` y `syncedAt = ahora`.
3. Si **ya existe** → actualiza su nombre y `syncedAt` (no duplica).

### 4.7 `lib/repositories/producto_repository.dart` — Repositorio de Productos

**¿Qué hace?**
- CRUD completo de productos.
- Todas las consultas de lista usan **INNER JOIN** con categorías para obtener `categoriaNombre` y `categoriaColor`.
- Contiene la lógica de sincronización con protección de ediciones locales.

**Métodos:**

| Método                                   | ¿Qué hace?                                                       |
|------------------------------------------|------------------------------------------------------------------|
| `getAll()`                               | Obtiene todos los productos con JOIN a categorías                |
| `getById(id)`                            | Obtiene un producto por su ID con JOIN                           |
| `insert(producto)`                       | Inserta un nuevo producto                                        |
| `update(producto)`                       | Actualiza un producto, marcando `isLocalEdited = 1` si es API    |
| `delete(id)`                             | Elimina un producto                                              |
| `search(query)`                          | Busca productos por nombre o descripción (LIKE)                  |
| `getByCategoria(categoriaId)`            | Filtra productos por categoría                                   |
| `getBajoStock(threshold)`                | Productos con stock menor o igual al umbral                      |
| `getTotal()`                             | Cuenta total de productos                                        |
| `getValorTotalInventario()`              | Suma de (precio × stock) de todos los productos                  |
| `syncFromApi(apiProducts, categoryMap)`  | Sincroniza productos desde la API                                |
| `getLastSyncAt()`                        | Última sincronización                                            |
| `countImported()`                        | Cuenta productos importados desde API                            |

**JOIN usado en `getAll()`:**
```sql
SELECT p.*, c.nombre as categoriaNombre, c.color as categoriaColor
FROM productos p
INNER JOIN categorias c ON p.categoriaId = c.id
ORDER BY p.fechaCreacion DESC
```

**Lógica de `update`:**
```dart
Future<int> update(Producto producto) async {
  final data = producto.toMap();
  if (producto.source == 'dummyjson') {
    data['isLocalEdited'] = 1;  // Marcar como editado localmente
  }
  // ... ejecutar UPDATE en SQLite
}
```

**Lógica de `syncFromApi`:**
1. Para cada producto de la API, obtiene su `remoteId` y su `category` (slug).
2. Busca el `categoriaId` local usando el mapa `categoryMapping` {slug → id}.
3. Verifica si el producto ya existe en SQLite buscando por `remoteId` + `source = 'dummyjson'`.
4. Si **no existe** → lo inserta con todos los datos de la API.
5. Si **existe y `isLocalEdited == 0`** → actualiza sus datos (precio, stock, nombre, etc.).
6. Si **existe y `isLocalEdited == 1`** → **NO lo sobrescribe** (respeta la edición local).

### 4.8 `lib/screens/home_screen.dart` — Pantalla Principal (Dashboard)

**¿Qué hace?**
- Contiene un **NavigationBar** con 3 pestañas: Dashboard, Productos, Categorías.
- El Dashboard muestra:
  - **Si no hay datos**: Una tarjeta con icono de descarga y botón "Sincronizar desde API".
  - **Si hay datos**: Grid de 4 tarjetas (Productos, Categorías, Bajo stock, Valor inventario) + SyncStatusCard.
- Botón de sincronizar en el AppBar y enlace de texto "Sincronizar".
- `RefreshIndicator` para recargar datos deslizando hacia abajo.

**¿De dónde saca los datos?**
```dart
final categorias = await _categoriaRepo.getAll();
final totalP = await _productoRepo.getTotal();
final bajo = await _productoRepo.getBajoStock();
final valor = await _productoRepo.getValorTotalInventario();
final lastSync = await _categoriaRepo.getLastSyncAt();
```

### 4.9 `lib/screens/sync_screen.dart` — Pantalla de Sincronización

**¿Qué hace?**
- Muestra el estado actual de la sincronización (SyncStatusCard).
- Botón "Sincronizar desde API" que ejecuta todo el flujo de importación.
- Muestra loading mientras se consume la API.
- Muestra resultados: cuántas categorías y productos nuevos se importaron.
- Muestra errores si falla la conexión o la API.
- Si es `firstTime = true`, después de sincronizar muestra un botón "Ir al inicio".

**Flujo de sincronización (`_sync`):**
```dart
final apiCategories = await _api.fetchCategories();           // 1. Obtener categorías de API
final catsInserted = await _categoriaRepo.syncFromApi(apiCategories); // 2. Guardar en SQLite

final categoryMapping = await _categoriaRepo.getRemoteIdMapping(); // 3. Mapear slugs → IDs locales
final apiProducts = await _api.fetchProducts(limit: 100);     // 4. Obtener productos de API
final prodsInserted = await _productoRepo.syncFromApi(        // 5. Guardar en SQLite
  apiProducts, categoryMapping,
);
```

### 4.10 `lib/screens/producto_list_screen.dart` — Lista de Productos

**¿Qué hace?**
- Muestra todos los productos en una lista con scroll.
- **SearchBar** para buscar por nombre.
- **Filtro por categoría** usando chips horizontales.
- **Filtro de bajo stock** (activable desde el dashboard).
- Cada producto se muestra con `ProductoCard`.
- Botón flotante "+" para crear nuevo producto.
- Confirmación antes de eliminar (AlertDialog).

### 4.11 `lib/screens/producto_form_screen.dart` — Formulario de Producto

**¿Qué hace?**
- Formulario para crear o editar un producto.
- Campos: Nombre, Descripción, Precio, Stock, Categoría (dropdown), URL de imagen.
- Validaciones con la clase `Validators`.
- Vista previa de la imagen si se ingresa una URL.
- Al guardar, si el producto es de API (`source = 'dummyjson'`), se respeta su `remoteId` y `source`.
- Al editar un producto de API, el repositorio marca `isLocalEdited = 1`.

### 4.12 `lib/screens/categoria_list_screen.dart` — Lista de Categorías

**¿Qué hace?**
- Lista todas las categorías con su color y descripción.
- Muestra un icono de nube (`cloud_done_outlined`) en las categorías importadas desde API.
- Al eliminar, primero verifica si tiene productos asociados:
  - Si tiene productos → muestra **SnackBar** indicando que debe eliminarlos o reasignarlos primero.
  - Si no tiene productos → muestra confirmación y elimina.

### 4.13 `lib/screens/categoria_form_screen.dart` — Formulario de Categoría

**¿Qué hace?**
- Formulario para crear o editar una categoría.
- Campos: Nombre, Descripción, Color (selector de 16 colores circulares).
- Al guardar, respeta los campos de sincronización si ya existían.

### 4.14 `lib/widgets/producto_card.dart` — Tarjeta de Producto

**¿Qué hace?**
- Muestra la imagen del producto (o placeholder si no hay imagen o falla la carga).
- Nombre, categoría (con color), precio, stock.
- Botones de editar y eliminar.
- El color del texto de stock cambia según el nivel: verde (disponible), naranja (bajo), rojo (agotado).

**Manejo de imágenes:**
```dart
Image.network(
  producto.imagenUrl!,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => _imagePlaceholder(),
  loadingBuilder: (_, child, progress) =>
      progress == null ? child : _imagePlaceholder(),
)
```
Si la URL es inválida o la imagen no carga, muestra un placeholder con icono.

### 4.15 `lib/widgets/dashboard_card.dart` — Tarjeta del Dashboard

**¿Qué hace?**
- Tarjeta animada (fade + slide) con icono, valor numérico y título.
- Usa gradientes de color basados en el color pasado como parámetro.
- Animación de entrada al iniciar la pantalla (500ms).

### 4.16 `lib/widgets/sync_status_card.dart` — Tarjeta de Estado de Sincronización

**¿Qué hace?**
- Muestra:
  - **Última sincronización**: fecha formateada en DD/MM/AAAA HH:MM o "Nunca".
  - **Categorías importadas**: cantidad.
  - **Productos importados**: cantidad.
- Se usa tanto en el Dashboard como en la SyncScreen.

### 4.17 `lib/utils/validators.dart` — Validaciones

**¿Qué hace?**
- Funciones estáticas para validar formularios:

| Método               | ¿Qué valida?                                    |
|----------------------|--------------------------------------------------|
| `validateNombre`     | No vacío, mínimo 2 caracteres                    |
| `validatePrecio`     | No vacío, número válido, mayor a 0               |
| `validateStock`      | No vacío, entero válido, mayor o igual a 0       |
| `validateCategoria`  | No sea null (debe seleccionar una categoría)     |

---

## 5. Modelos de Datos (Models)

Los modelos son clases Dart simples (POJOs) que representan las entidades del negocio.

**Características:**
- **`toMap()`** → Convierte el objeto a un `Map<String, dynamic>` que SQLite puede entender para INSERT/UPDATE.
- **`fromMap(map)`** → Constructor factory que crea el objeto desde un `Map` devuelto por SQLite.
- Los campos `categoriaNombre` y `categoriaColor` en Producto no se guardan en la tabla `productos`, sino que vienen del JOIN con la tabla `categorias`.
- Los campos `remoteId`, `source`, `syncedAt` e `isLocalEdited` son específicos para el sistema de sincronización.

---

## 6. Base de Datos SQLite (DBHelper)

### ¿Qué es SQLite?
SQLite es un motor de base de datos **relacional** embebido, **sin servidor**, que almacena toda la información en un único archivo `.db`. Es la base de datos más utilizada en aplicaciones móviles.

### ¿Cómo se usa en ProductApp?

**Conexión:**
```dart
final db = await DBHelper.instance.database;
```

Esto obtiene la instancia Singleton de `DBHelper`, que abre o crea el archivo `product_app.db` en el directorio de documentos de la aplicación.

**Operaciones:**
- **Insertar**: `db.insert('categorias', categoria.toMap())`
- **Consultar**: `db.query('categorias', orderBy: 'nombre ASC')`
- **Consultas SQL**: `db.rawQuery('SELECT ... JOIN ... WHERE ...')`
- **Actualizar**: `db.update('productos', data, where: 'id = ?', whereArgs: [id])`
- **Eliminar**: `db.delete('productos', where: 'id = ?', whereArgs: [id])`

### ¿Por qué se usa SQLite y no otra base de datos?
1. **No necesita servidor** — Todo está en un archivo local.
2. **Rápido** — Las consultas son prácticamente instantáneas en datos pequeños.
3. **Offline** — La aplicación funciona sin internet una vez que los datos están cargados.
4. **Integración con Flutter** — El paquete `sqflite` es el estándar para Flutter.

### Migraciones
Cuando se agregan nuevas columnas (como en la versión 2), se usa `onUpgrade` para ejecutar `ALTER TABLE` sin perder los datos existentes.

---

## 7. Consumo de API (ApiService)

### ¿Qué API se consume?
Se consume **DummyJSON** (`https://dummyjson.com`), una API pública gratuita que proporciona datos de prueba en formato JSON.

### ¿Cómo se hace la llamada?
```dart
final response = await http.get(Uri.parse('$_baseUrl/products?limit=$limit'));
```

1. Se usa el paquete `http` de Dart.
2. Se hace una petición HTTP GET al endpoint.
3. Se verifica que el código de respuesta sea 200 (OK).
4. Se decodifica el JSON con `json.decode(response.body)`.
5. Se extrae la lista de productos del campo `products`.
6. Se devuelve como `List<Map<String, dynamic>>`.

### ¿Dónde se llama a la API?
La API se llama exclusivamente desde **`SyncScreen._sync()`**, que es el método que se ejecuta al presionar el botón "Sincronizar desde API".

### Manejo de errores de conexión
```dart
try {
  // llamadas a la API
} on ApiException catch (e) {
  // Error específico de la API (código HTTP no 200)
  setState(() => _error = e.message);
} catch (e) {
  // Error general (sin internet, timeout, etc.)
  setState(() => _error = 'Error de conexión: $e');
}
```

---

## 8. Repositorios (Repositories)

### ¿Qué son y para qué sirven?
Los repositorios son una **capa de abstracción** entre la UI y la base de datos. Contienen:

1. **Operaciones CRUD** (insertar, actualizar, eliminar, consultar).
2. **Lógica de negocio** (la sincronización con la API, la protección de ediciones locales).
3. **Consultas especializadas** (JOINs, búsquedas, filtros).

### Beneficios de usar repositorios:
- Las pantallas no conocen los detalles de SQLite.
- Si en el futuro se cambia SQLite por otra tecnología, solo se modifican los repositorios.
- La lógica de sincronización está centralizada y no dispersa en varias pantallas.
- Es más fácil hacer pruebas unitarias.

---

## 9. Pantallas (Screens)

Cada pantalla es un `StatefulWidget` de Flutter y se encarga de:

1. **Inicializar datos** en `initState()` llamando a los repositorios.
2. **Renderizar la UI** con los datos obtenidos.
3. **Responder a interacciones** (toques, navegación, etc.).
4. **Refrescar datos** después de operaciones de escritura.

**Navegación entre pantallas:**
- `HomeScreen` usa un `IndexedStack` con `NavigationBar` para cambiar entre 3 vistas.
- Las pantallas de formulario se abren con `Navigator.push` y esperan un resultado con `await`.
- `SyncScreen` en modo `firstTime` usa `pushAndRemoveUntil` para reemplazar toda la pila de navegación.

---

## 10. Widgets Reutilizables

| Widget              | ¿Dónde se usa?                        | ¿Qué hace?                            |
|---------------------|---------------------------------------|---------------------------------------|
| `ProductoCard`      | ProductoListScreen                    | Muestra un producto en la lista       |
| `DashboardCard`     | HomeScreen (Dashboard)                | Tarjeta con número e icono            |
| `SyncStatusCard`    | HomeScreen y SyncScreen               | Muestra estado de sincronización      |

---

## 11. Validaciones

**Validators** es una clase con métodos estáticos que se usan en los formularios:

```dart
TextFormField(
  validator: Validators.validateNombre,
  // ...
)
```

Reglas:
- **Nombre**: obligatorio, mínimo 2 caracteres.
- **Precio**: obligatorio, número decimal, mayor a 0.
- **Stock**: obligatorio, entero, mayor o igual a 0.
- **Categoría**: obligatorio, debe seleccionar una.

---

## 12. Flujo Completo de la Aplicación

```
1. APP INICIA
   │
   ├─ main() → AppInitializer
   │
   ├─ DBHelper abre/crea product_app.db (SQLite)
   │
   ├─ ¿Hay categorías en la BD?
   │   │
   │   ├─ NO → SyncScreen (firstTime)
   │   │         │
   │   │         └─ Usuario presiona "Sincronizar desde API"
   │   │               │
   │   │               ├─ ApiService.fetchCategories() → lista de categorías de DummyJSON
   │   │               ├─ CategoriaRepository.syncFromApi() → guarda en SQLite
   │   │               ├─ ApiService.fetchProducts() → lista de productos de DummyJSON
   │   │               └─ ProductoRepository.syncFromApi() → guarda en SQLite
   │   │                     │
   │   │                     └─ Usuario presiona "Ir al inicio"
   │   │                           │
   │   │                           └─ HomeScreen
   │   │
   │   └─ SÍ → HomeScreen
   │            │
   │            ├─ Pestaña Dashboard:
   │            │   ├─ Total productos, categorías, bajo stock, valor inventario
   │            │   ├─ SyncStatusCard (última sincronización, cantidades importadas)
   │            │   └─ Botón "Sincronizar" → SyncScreen
   │            │
   │            ├─ Pestaña Productos:
   │            │   ├─ Lista con búsqueda y filtro por categoría
   │            │   ├─ Tap → Editar producto
   │            │   ├─ Botón + → Nuevo producto
   │            │   └─ Eliminar con confirmación
   │            │
   │            └─ Pestaña Categorías:
   │                ├─ Lista con colores
   │                ├─ Tap → Editar categoría
   │                ├─ Botón + → Nueva categoría
   │                └─ Eliminar (solo si no tiene productos)
   │
   └── Los datos persisten en SQLite aunque se cierre la app
```

---

## 13. Flujo de Sincronización API → SQLite

### Paso a paso detallado:

1. **Usuario presiona "Sincronizar desde API"** en SyncScreen.
2. `SyncScreen._sync()` se ejecuta:

   **Paso 1 — Obtener categorías de la API:**
   ```dart
   final apiCategories = await _api.fetchCategories();
   // apiCategories = [{slug: "beauty", name: "Beauty"}, {slug: "smartphones", name: "Smartphones"}, ...]
   ```

   **Paso 2 — Guardar categorías en SQLite (sin duplicar):**
   ```dart
   final catsInserted = await _categoriaRepo.syncFromApi(apiCategories);
   // Para cada categoría de la API:
   //   ¿Existe ya en SQLite con mismo remoteId y source='dummyjson'?
   //     NO → INSERT con source='dummyjson', remoteId=slug, syncedAt=ahora
   //     SÍ → UPDATE nombre y syncedAt
   ```

   **Paso 3 — Obtener mapeo remoteId → localId:**
   ```dart
   final categoryMapping = await _categoriaRepo.getRemoteIdMapping();
   // categoryMapping = {"beauty": 1, "smartphones": 2, ...}
   ```

   **Paso 4 — Obtener productos de la API:**
   ```dart
   final apiProducts = await _api.fetchProducts(limit: 100);
   // apiProducts = [{id: 1, title: "iPhone 9", category: "smartphones", ...}, ...]
   ```

   **Paso 5 — Guardar productos en SQLite (sin duplicar y protegiendo ediciones):**
   ```dart
   final prodsInserted = await _productoRepo.syncFromApi(
     apiProducts, categoryMapping,
   );
   // Para cada producto de la API:
   //   Obtener categoriaId local desde categoryMapping usando category slug
   //   ¿Existe ya en SQLite con mismo remoteId y source='dummyjson'?
   //     NO → INSERT con todos los datos de la API
   //     SÍ → ¿isLocalEdited == 0? → UPDATE datos
   //           ¿isLocalEdited == 1? → NO hacer nada (respetar edición local)
   ```

3. **Se muestran los resultados** en la SyncScreen:
   - "Categorías importadas: X"
   - "Productos importados: Y"

### Diagrama de flujo:

```
SyncScreen._sync()
    │
    ├──► ApiService.fetchCategories()
    │       │
    │       └──► CategoriaRepository.syncFromApi()
    │               │
    │               ├── ¿remoteId + source existe? → SÍ → UPDATE
    │               └── ¿remoteId + source existe? → NO → INSERT
    │
    ├──► CategoriaRepository.getRemoteIdMapping()
    │       │
    │       └─── Devuelve {slug → localId}
    │
    ├──► ApiService.fetchProducts()
    │       │
    │       └──► ProductoRepository.syncFromApi()
    │               │
    │               ├── ¿remoteId + source existe?
    │               │   ├── NO → INSERT
    │               │   └── SÍ → ¿isLocalEdited?
    │               │       ├── 0 → UPDATE
    │               │       └── 1 → SKIP
    │
    └──► Mostrar resultados
```

---

## 14. Mecanismo Anti-Duplicados

### ¿Cómo se evita que al sincronizar varias veces se dupliquen los datos?

Se usan **3 campos clave** en cada tabla:

| Campo          | ¿Qué almacena?                               | Ejemplo                    |
|----------------|----------------------------------------------|----------------------------|
| `remoteId`     | El ID que viene de la API (slug o numérico)  | `"smartphones"` o `"1"`    |
| `source`       | El origen del registro                       | `"dummyjson"` o `"local"`  |
| `isLocalEdited`| Si el usuario editó manualmente (solo productos)| `0` o `1`                |

### Lógica de no duplicación:
```sql
SELECT * FROM productos WHERE remoteId = '1' AND source = 'dummyjson'
```

Si la consulta devuelve resultados, el producto **ya fue importado** y no se vuelve a insertar.

### Protección de ediciones locales:
Cuando un usuario edita un producto que vino de la API, el repositorio marca `isLocalEdited = 1`. En la siguiente sincronización, aunque el producto exista en la API, no se sobrescriben los cambios del usuario.

### Para categorías:
Las categorías solo se actualizan (nombre y descripción) pero nunca se duplican. No tienen `isLocalEdited` porque asumimos que las categorías de DummyJSON son estables.

---

## 15. Preguntas Frecuentes para la Presentación

### ¿Qué es SQLite?
SQLite es una base de datos relacional ligera que se almacena en un solo archivo. No necesita un servidor, lo que la hace ideal para aplicaciones móviles que funcionan offline.

### ¿Por qué usaste SQLite y no otra base de datos?
Porque es la base de datos embebida más popular en móviles, no requiere configuración de servidor, los datos persisten aunque la app se cierre, y Flutter tiene soporte nativo a través del paquete `sqflite`.

### ¿Qué API consumiste?
DummyJSON (`https://dummyjson.com`), una API pública gratuita que proporciona datos de prueba (productos, categorías, etc.).

### ¿Desde dónde se llama a la API?
Desde la pantalla `SyncScreen`, en el método `_sync()`, cuando el usuario presiona "Sincronizar desde API".

### ¿Cómo se guardan los datos de la API en SQLite?
1. Se obtienen los datos JSON desde la API.
2. Se mapean a `Map<String, dynamic>`.
3. Se verifica si ya existen en SQLite usando `remoteId` + `source`.
4. Si no existen, se insertan. Si existen y no fueron editados, se actualizan.

### ¿Cómo evitas duplicados al sincronizar varias veces?
Usamos una consulta que busca por `remoteId` y `source` antes de insertar. Si el registro ya existe, se actualiza en lugar de insertar uno nuevo.

### ¿Qué pasa si el usuario edita un producto importado y luego se vuelve a sincronizar?
El campo `isLocalEdited` se marca como `1` cuando el usuario edita. En la siguiente sincronización, los productos con `isLocalEdited = 1` no se sobrescriben.

### ¿Qué son los repositorios?
Son clases que actúan como intermediarios entre las pantallas y la base de datos. Centralizan las operaciones CRUD y la lógica de sincronización.

### ¿La app funciona sin internet?
Sí. La API solo se usa para la sincronización inicial o cuando el usuario decide importar datos nuevos. Una vez que los datos están en SQLite, la app los muestra desde la base de datos local sin necesidad de conexión.

### ¿Qué pasa si no hay internet al sincronizar?
La pantalla de sincronización captura el error y muestra un mensaje al usuario indicando que hubo un error de conexión.

### ¿Qué es el campo `source`?
Identifica el origen del registro. `"dummyjson"` para datos importados desde la API, `"local"` (o null) para datos creados manualmente por el usuario.

### ¿Cómo se relacionan productos y categorías en la base de datos?
Mediante una clave foránea (`FOREIGN KEY`). La tabla `productos` tiene el campo `categoriaId` que referencia al `id` de la tabla `categorias`. Las consultas usan `INNER JOIN` para obtener el nombre y color de la categoría junto con cada producto.

### ¿Qué Material Design usas?
Material 3 (Material You) con `useMaterial3: true` y `colorSchemeSeed: Colors.indigo` para la generación automática de colores.

### ¿Qué versión de Flutter usas?
La aplicación usa Dart SDK ^3.9.2 y Flutter con soporte para Material 3.
