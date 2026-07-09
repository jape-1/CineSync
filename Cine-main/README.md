# 🎬 CineSync

App móvil de reserva de asientos de cine en tiempo real, construida con Flutter.

CineSync permite a los usuarios explorar la cartelera, ver detalles de películas, seleccionar butacas en un mapa interactivo con actualizaciones en vivo, agregar dulcería y completar la compra en un flujo pulido y responsivo.

## ✨ Características

- **Cartelera dinámica** con banner destacado, grid de películas y carrusel de estrenos.
- **Detalle de película** con selector de fechas y horarios por sala (Standard, IMAX, 4DX).
- **Selección de asientos en tiempo real** con indicadores visuales para asientos disponibles, ocupados, reservados por otros usuarios y VIP.
- **Timer de bloqueo temporal** durante la selección (5 minutos).
- **Dulcería opcional** con carrito interactivo y stepper de cantidad.
- **Ticket digital con QR** y código de acceso único.
- **Historial de tickets** con filtros por estado (activos, usados, cancelados).
- **Pantalla de validación** para el personal del cine.
- **Diseño oscuro** con acentos rojos, tipografía Space Grotesk + Manrope + JetBrains Mono.

## 🛠️ Stack técnico

- **Framework:** Flutter 3.44+
- **Lenguaje:** Dart
- **Navegación:** Navigator con rutas nombradas
- **Estado:** setState nativo (sin dependencias de gestión de estado externa)
- **Tipografías:** google_fonts

## 📁 Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada y rutas
├── theme/
│   ├── app_colors.dart          # Paleta de colores
│   └── app_text_styles.dart     # Estilos de texto
├── widgets/                     # Widgets reutilizables
│   ├── cs_logo.dart
│   ├── cs_button.dart
│   ├── icon_btn.dart
│   ├── top_bar.dart
│   ├── bottom_tabs.dart
│   ├── input_field.dart
│   ├── poster.dart
│   ├── backdrop.dart
│   └── _stripes_painter.dart
└── screens/                     # Pantallas de la app
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart
    ├── movie_detail_screen.dart
    ├── seat_selection_screen.dart
    ├── snacks_screen.dart
    ├── confirmation_screen.dart
    ├── ticket_screen.dart
    ├── my_tickets_screen.dart
    └── validation_screen.dart
```

## 🚀 Cómo correr el proyecto

### Requisitos previos

- Flutter SDK 3.44 o superior
- Android Studio (con Android SDK y un emulador configurado)
- Un editor: VS Code (recomendado) o Android Studio

### Pasos

1. Clona el repositorio:
   ```bash
   git clone https://github.com/TU_USUARIO/cinesync.git
   cd cinesync
   ```

2. Instala las dependencias:
   ```bash
   flutter pub get
   ```

3. Verifica que Flutter detecta tu dispositivo:
   ```bash
   flutter devices
   ```

4. Corre la app:
   ```bash
   flutter run
   ```

## 🗺️ Flujo de navegación

```
Splash (3s auto)
   ↓
Login ← ← ← ← ← ← ← ← ← ← ← ← ┐
   ├─→ Home                    │
   └─→ Register ─── Continuar ─┘ (vuelve al Login con aviso)

Home → Movie Detail → Seat Selection → Snacks → Confirmation → Ticket (QR)
                                                                    ↓
                                                               back → Home
                                                               
Home → tab Tickets → Mis Tickets ─→ Ticket (QR)
```

## 🎨 Diseño

El diseño está basado en un mockup original en React con estética oscura y flujo pensado para uso móvil intensivo. Los colores están definidos en OKLCH (convertidos a hex para Dart) y las tipografías priorizan legibilidad en pantallas pequeñas.

## 🔮 Roadmap

- [ ] Backend en AWS (API Gateway + Lambda + DynamoDB)
- [ ] Autenticación con Cognito
- [ ] QRs escaneables reales con `qr_flutter`
- [ ] WebSocket para actualizaciones en vivo de asientos
- [ ] Notificaciones push
- [ ] Modo claro / dark mode toggle

## 📝 Licencia

Proyecto académico. Todos los derechos reservados.

---

Hecho con ❤️ y Flutter.