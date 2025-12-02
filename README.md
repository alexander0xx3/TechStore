# TechStore 📱💻

Bienvenido a **TechStore**, una aplicación de comercio electrónico completa desarrollada con **Flutter** y **Firebase**. Esta aplicación ofrece una experiencia de compra fluida para usuarios y un panel de administración robusto para gestionar el negocio.

## ✨ Características Principales

### 👤 Aplicación de Usuario
-   **Autenticación**: Registro e inicio de sesión con Email/Contraseña y Google Sign-In.
-   **Catálogo de Productos**: Exploración de productos por categorías con imágenes optimizadas.
-   **Carrito de Compras**: Gestión de productos, cálculo de totales y proceso de checkout.
-   **Lista de Deseos**: Guardado de productos favoritos.
-   **Gestión de Pedidos**: Historial de pedidos y seguimiento de estado en tiempo real.
-   **Direcciones**: Gestión de direcciones de envío con integración de Google Maps.
-   **Perfil de Usuario**: Gestión de información personal y foto de perfil.
-   **Soporte**: Sistema de tickets de soporte y chat.
-   **Modo Oscuro/Claro**: Tema adaptable a las preferencias del usuario.

### 🛠️ Panel de Administración
-   **Dashboard**: Vista general de métricas clave.
-   **Gestión de Productos**: Crear, editar y eliminar productos.
-   **Gestión de Pedidos**: Ver y actualizar el estado de los pedidos (con notificaciones automáticas al usuario).
-   **Gestión de Usuarios**: Ver lista de usuarios y gestionar roles (asignar/remover permisos de administrador).
-   **Soporte**: Atender tickets de soporte de los usuarios.

## 🚀 Tecnologías Utilizadas

-   **Frontend**: [Flutter](https://flutter.dev/) (Dart)
-   **Backend**: [Firebase](https://firebase.google.com/)
    -   **Authentication**: Gestión de usuarios.
    -   **Firestore**: Base de datos NoSQL en tiempo real.
    -   **Storage**: Almacenamiento de imágenes (perfiles, productos).
-   **Notificaciones**: `flutter_local_notifications` para alertas en tiempo real.
-   **Mapas**: `google_maps_flutter`, `geolocator`, `geocoding`.
-   **Estado**: `Provider` para la gestión del estado (ej. Tema, Carrito).
-   **Web Support**: Proxy `wsrv.nl` para evitar problemas de CORS con imágenes de Google Drive.

## 📂 Estructura del Proyecto

```
lib/
├── admin/              # Pantallas y lógica del panel de administración
├── providers/          # State management (ThemeProvider, etc.)
├── services/           # Servicios (Notificaciones, etc.)
├── widgets/            # Widgets reutilizables
├── main.dart           # Punto de entrada
├── PantallaPrincipal.dart # Home del usuario
├── pantalla_login.dart # Login
├── ...                 # Otras pantallas (Carrito, Perfil, Pedidos, etc.)
```

## ⚙️ Configuración e Instalación

1.  **Requisitos Previos**:
    -   Flutter SDK instalado.
    -   Cuenta de Firebase configurada.

2.  **Clonar el Repositorio**:
    ```bash
    git clone https://github.com/alexander0xx3/TechStore.git
    cd TechStore
    ```

3.  **Instalar Dependencias**:
    ```bash
    flutter pub get
    ```

4.  **Configuración de Firebase**:
    -   Asegúrate de tener el archivo `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) en sus respectivas carpetas.
    -   Configura las reglas de Firestore y Storage según sea necesario.

5.  **Ejecutar la App**:
    ```bash
    flutter run
    ```

## 📱 Notas Adicionales

-   **Web**: Para ejecutar en web y ver las imágenes de Google Drive correctamente, la app utiliza un proxy. Asegúrate de usar `flutter run -d chrome`.
-   **Notificaciones**: Las notificaciones locales están configuradas para móviles. En web, el servicio se degrada elegantemente para evitar errores.

---
© 2025 TechStore Admin
