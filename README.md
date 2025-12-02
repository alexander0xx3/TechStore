# 📱 TechStore - E-Commerce Flutter App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

**TechStore** es una solución completa de comercio electrónico multiplataforma (Android, iOS, Web) desarrollada con **Flutter**. Combina una interfaz de usuario moderna y fluida con un backend robusto en **Firebase**, ofreciendo una experiencia de compra premium y un panel de administración integral para la gestión del negocio.

---

## 📑 Tabla de Contenidos

- [Características](#-características)
  - [App de Usuario](#-app-de-usuario)
  - [Panel de Administración](#-panel-de-administración)
- [Galería](#-galería)
- [Arquitectura y Tecnologías](#-arquitectura-y-tecnologías)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Instalación y Configuración](#-instalación-y-configuración)
  - [Requisitos Previos](#requisitos-previos)
  - [Pasos de Instalación](#pasos-de-instalación)
  - [Configuración de Firebase](#configuración-de-firebase)
  - [Configuración de Google Maps](#configuración-de-google-maps)
- [Dependencias Clave](#-dependencias-clave)
- [Solución de Problemas](#-solución-de-problemas)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## ✨ Características

### 👤 App de Usuario

Diseñada para maximizar la conversión y la retención de usuarios.

*   **Autenticación Segura**:
    *   Login social con **Google**.
    *   Registro tradicional con correo y contraseña.
    *   Recuperación de contraseña.
    *   Persistencia de sesión.
*   **Experiencia de Compra**:
    *   **Home Dinámico**: Carrusel de ofertas y categorías destacadas.
    *   **Catálogo Avanzado**: Filtrado por categorías, búsqueda en tiempo real.
    *   **Detalle de Producto**: Imágenes de alta calidad, descripción, precio y stock.
    *   **Carrito Inteligente**: Cálculos automáticos, gestión de cantidades.
    *   **Lista de Deseos (Wishlist)**: Guarda productos para después.
*   **Gestión de Pedidos**:
    *   Checkout fluido.
    *   Historial completo de compras.
    *   **Rastreo en Tiempo Real**: Estados de pedido (Pendiente, Enviado, Entregado) con actualizaciones en vivo.
    *   **Notificaciones Locales**: Alertas automáticas cuando cambia el estado de un pedido.
*   **Perfil y Configuración**:
    *   Gestión de avatar (cámara/galería).
    *   Libreta de direcciones con geolocalización (**Google Maps**).
    *   **Tema Adaptable**: Soporte completo para **Modo Oscuro** y Claro.
*   **Soporte al Cliente**:
    *   Sistema de tickets integrado.
    *   Historial de consultas.

### �️ Panel de Administración

Herramientas poderosas para gestionar tu negocio desde el móvil.

*   **Dashboard Analítico**: Métricas clave (Ventas, Usuarios, Pedidos) en tiempo real.
*   **Gestión de Inventario**:
    *   CRUD completo de productos.
    *   Subida de imágenes a Firebase Storage.
    *   Control de stock y precios.
*   **Control de Pedidos**:
    *   Visualización detallada de órdenes.
    *   Cambio de estados (Aprobación, Envío, Entrega).
    *   Filtros por estado y fecha.
*   **Gestión de Usuarios**:
    *   Directorio de clientes.
    *   Gestión de roles (Promover a Admin / Revocar).
    *   Visualización de perfiles.
*   **Centro de Soporte**:
    *   Bandeja de entrada de tickets.
    *   Respuestas a usuarios.

---

## 📸 Galería

| Login | Home | Carrito | Perfil |
|:---:|:---:|:---:|:---:|
| ![Login](/assets/screenshots/login.png) | ![Home](/assets/screenshots/home.png) | ![Cart](/assets/screenshots/cart.png) | ![Profile](/assets/screenshots/profile.png) |

| Admin Dashboard | Gestión Productos | Pedidos | Modo Oscuro |
|:---:|:---:|:---:|:---:|
| ![Dashboard](/assets/screenshots/admin_dash.png) | ![Products](/assets/screenshots/admin_prod.png) | ![Orders](/assets/screenshots/admin_orders.png) | ![Dark](/assets/screenshots/dark_mode.png) |

*(Nota: Reemplaza las rutas con tus capturas de pantalla reales)*

---

## 🏗️ Arquitectura y Tecnologías

El proyecto sigue una arquitectura limpia y modular, utilizando **Provider** para la gestión de estado.

*   **Frontend**: [Flutter](https://flutter.dev/) (Dart 3.0+)
*   **Backend**: [Firebase](https://firebase.google.com/) (Serverless)
*   **Base de Datos**: Cloud Firestore (NoSQL)
*   **Almacenamiento**: Firebase Storage
*   **Autenticación**: Firebase Auth

### Patrones de Diseño
*   **Provider Pattern**: Para la inyección de dependencias y gestión de estado reactivo (`ThemeProvider`, `CartProvider`).
*   **Repository Pattern**: (Implícito) Separación de la lógica de datos (Firebase) de la UI.
*   **Services**: Módulos dedicados para funcionalidades específicas (`NotificationService`).

---

## 📂 Estructura del Proyecto

```bash
lib/
├── admin/                  # Módulo de Administración
│   ├── admin_dashboard.dart
│   ├── admin_productos.dart
│   ├── admin_pedidos.dart
│   └── ...
├── providers/              # Gestión de Estado
│   └── theme_provider.dart # Lógica de temas (Dark/Light)
├── services/               # Servicios Externos
│   └── notification_service.dart # Manejo de notificaciones locales
├── widgets/                # Componentes Reutilizables UI
│   ├── animated_navbar.dart
│   └── ...
├── main.dart               # Punto de entrada y configuración de rutas
├── PantallaPrincipal.dart  # Layout principal (BottomNav)
├── pantalla_login.dart     # Autenticación
├── pantalla_carrito.dart   # Lógica de compra
├── pantalla_perfil.dart    # Gestión de usuario
└── ...
```

---

## ⚙️ Instalación y Configuración

### Requisitos Previos
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión estable más reciente).
*   [Git](https://git-scm.com/).
*   Un editor de código (VS Code o Android Studio).
*   Cuenta de Google para Firebase.

### Pasos de Instalación

1.  **Clonar el repositorio**:
    ```bash
    git clone https://github.com/alexander0xx3/TechStore.git
    cd TechStore
    ```

2.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```

3.  **Configuración de Firebase**:
    *   Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
    *   **Android**: Descarga `google-services.json` y colócalo en `android/app/`.
    *   **iOS**: Descarga `GoogleService-Info.plist` y colócalo en `ios/Runner/`.
    *   Habilita **Authentication** (Email/Password, Google).
    *   Crea una base de datos en **Firestore** y habilita **Storage**.

4.  **Configuración de Google Maps (Opcional)**:
    *   Obtén una API Key en Google Cloud Console.
    *   Agrégala en `android/app/src/main/AndroidManifest.xml` y `ios/Runner/AppDelegate.swift`.

5.  **Ejecutar la aplicación**:
    ```bash
    # Para modo debug
    flutter run

    # Para web (usando renderizador HTML para compatibilidad de imágenes)
    flutter run -d chrome --web-renderer html
    ```

---

## � Dependencias Clave

| Paquete | Versión | Propósito |
|:--- |:--- |:--- |
| `firebase_core` | ^4.2.0 | Inicialización de Firebase. |
| `cloud_firestore` | ^6.0.3 | Base de datos en tiempo real. |
| `firebase_auth` | ^6.1.1 | Autenticación de usuarios. |
| `provider` | ^6.1.1 | Gestión de estado. |
| `flutter_local_notifications` | ^17.0.0 | Notificaciones push locales. |
| `google_maps_flutter` | ^2.6.1 | Mapas interactivos. |
| `image_picker` | ^1.2.0 | Selección de imágenes. |
| `cached_network_image` | ^3.4.1 | Caché de imágenes para rendimiento. |
| `flutter_staggered_animations`| ^1.1.1 | Animaciones fluidas en listas. |

---

## 🔧 Solución de Problemas

### Error de CORS en Web (Imágenes)
Si las imágenes de Google Drive no cargan en la versión Web, es debido a políticas de CORS.
*   **Solución**: La app implementa automáticamente un proxy (`wsrv.nl`) en la clase `_fixGoogleDriveUrl`. Asegúrate de no eliminar esta función en `admin_pedidos.dart` y `pantalla_pedidos.dart`.

### Error de Build en Android (Desugaring)
Si obtienes un error relacionado con `flutter_local_notifications` y `core library desugaring`:
*   **Solución**: Ya está configurado en `android/app/build.gradle`. Verifica que `isCoreLibraryDesugaringEnabled = true` esté presente en `compileOptions`.

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1.  Haz un Fork del proyecto.
2.  Crea tu rama de funcionalidad (`git checkout -b feature/AmazingFeature`).
3.  Haz Commit de tus cambios (`git commit -m 'Add some AmazingFeature'`).
4.  Haz Push a la rama (`git push origin feature/AmazingFeature`).
5.  Abre un Pull Request.

---

## 📄 Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para más información.

---

<div align="center">
  <p>Desarrollado con ❤️ por el equipo de TechStore</p>
  <p>© 2025 TechStore Admin</p>
</div>
