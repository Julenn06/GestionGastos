# 📱 Gestión de Gastos - App de Finanzas Personales

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Aplicación profesional de finanzas personales e inversiones para Android**

Desarrollada con Flutter siguiendo las mejores prácticas de desarrollo móvil

</div>

---

## ✨ Características Principales

### 💰 Gestión de Gastos
- **Registro rápido** de gastos con acciones predefinidas
- **Categorización** completa con categorías y subcategorías
- **Historial** detallado con filtros por fecha y categoría
- **Notas** opcionales para cada gasto
- **Iconos** personalizables por categoría

### 📈 Gestión de Inversiones
- Registro de múltiples tipos: acciones, ETFs, fondos, criptomonedas
- Seguimiento del **valor actual** vs inversión inicial
- Cálculo automático de **ganancias/pérdidas**
- Visualización de **rendimiento** por tipo de inversión
- Balance total integrado con gastos

### 📊 Estadísticas Interactivas
- **Gráficos circulares** (pie charts) por categoría
- **Gráficos de barras** para tendencias temporales
- **Filtros** por periodo (día, semana, mes)
- Análisis de **promedio diario** de gastos
- Exportación de datos

### 🎮 Gamificación
- Sistema de **logros** desbloqueables
- **Rachas** (streaks) de uso diario
- Motivación visual con indicadores de progreso
- Notificaciones de logros conseguidos

### 🔒 Seguridad
- **Autenticación biométrica** (huella dactilar / Face ID)
- **PIN de seguridad** de 4 dígitos
- Almacenamiento seguro de datos sensibles
- Protección de datos offline

### 📤 Exportación de Datos
- Exportar a **CSV** para análisis en Excel
- Generar **reportes PDF** profesionales
- Compartir datos fácilmente
- Imprimir reportes directamente

### 🎨 UI/UX Premium
- **Material Design 3**
- **Modo oscuro** obligatorio (optimizado para OLED)
- Animaciones fluidas
- Diseño responsivo
- Paleta de colores profesional
- Tipografía Google Fonts (Inter)

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── core/                    # Núcleo de la aplicación
│   ├── constants/          # Constantes globales
│   └── theme/              # Temas y estilos
├── data/                   # Capa de datos
│   └── database.dart       # Base de datos Drift/SQLite
├── models/                 # Modelos de datos
│   ├── expense.dart
│   ├── investment.dart
│   ├── quick_action.dart
│   └── achievement.dart
├── services/               # Lógica de negocio
│   ├── expense_service.dart
│   ├── investment_service.dart
│   ├── quick_action_service.dart
│   ├── gamification_service.dart
│   ├── export_service.dart
│   └── security_service.dart
├── screens/                # Pantallas de la UI
│   ├── home/
│   ├── expenses/
│   ├── investments/
│   ├── statistics/
│   └── settings/
├── widgets/                # Widgets reutilizables
│   └── common/
└── main.dart              # Punto de entrada
```

### 🔧 Tecnologías Utilizadas

| Tecnología | Propósito |
|------------|-----------|
| **Flutter 3.10+** | Framework de desarrollo móvil |
| **Dart 3.0+** | Lenguaje de programación |
| **Drift** | Base de datos SQLite type-safe |
| **Provider** | Gestión de estado |
| **fl_chart** | Gráficos interactivos |
| **Google Fonts** | Tipografía profesional |
| **local_auth** | Autenticación biométrica |
| **flutter_secure_storage** | Almacenamiento seguro |
| **intl** | Internacionalización y formatos |
| **csv / pdf** | Exportación de datos |

---

## 🚀 Instalación y Configuración

### Requisitos Previos
- Flutter SDK 3.10 o superior
- Dart SDK 3.0 o superior
- Android Studio / VS Code
- Dispositivo Android o emulador

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd gestion_de_gastos
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Generar código de base de datos**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Ejecutar la aplicación**
```bash
flutter run
```

---

## 📖 Guía de Uso

### Registro de Gastos

#### Método 1: Acción Rápida
1. En la pantalla principal, selecciona una acción rápida predefinida (Café, Transporte, etc.)
2. El gasto se registra automáticamente con un solo toque

#### Método 2: Registro Manual
1. Presiona el botón **+** en la pantalla principal
2. Completa el formulario:
   - Monto del gasto
   - Categoría y subcategoría
   - Fecha
   - Nota opcional
3. Guarda el gasto

### Registro de Inversiones
1. Accede a **"Nueva Inversión"** desde la pantalla principal
2. Completa:
   - Tipo de inversión
   - Nombre o símbolo
   - Plataforma/broker
   - Monto invertido
   - Valor actual
3. Guarda la inversión

### Ver Estadísticas
1. Navega a la pestaña **"Estadísticas"**
2. Visualiza:
   - Gráfico circular de gastos por categoría
   - Desglose detallado
   - Porcentajes por categoría

### Exportar Datos
1. Ve a **"Ajustes"**
2. Selecciona:
   - **CSV**: Para análisis en Excel
   - **PDF**: Para reportes profesionales
3. Comparte o guarda el archivo

---

## 🎯 Características Futuras Planificadas

- [ ] Sincronización en la nube
- [ ] Presupuestos mensuales con alertas
- [ ] Recordatorios de pagos recurrentes
- [ ] Integración con APIs de bancos
- [ ] Actualización automática de precios de inversiones
- [ ] Múltiples divisas
- [ ] Modo claro (opcional)
- [ ] Widget para pantalla de inicio
- [ ] Escaneo de recibos con OCR

---

## 👨‍💻 Desarrollo

### Estructura de Código
- **Código limpio** y bien comentado
- **Principios SOLID**
- **Separación de responsabilidades**
- **Widgets reutilizables**
- **Type-safe** con null safety de Dart

### Patrones Utilizados
- **Repository Pattern** para acceso a datos
- **Provider Pattern** para gestión de estado
- **Service Layer** para lógica de negocio
- **Singleton** para servicios globales

---

## 📝 Licencia

Este proyecto está bajo la Licencia MIT.

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📧 Contacto

**Desarrollador**: Desarrollador Senior con 20 años de experiencia  
**Tecnologías**: Flutter, Dart, Mobile Development  
**Especialización**: Finanzas Personales, UX/UI Premium

---

<div align="center">

**Hecho con ❤️ usando Flutter**

</div>

