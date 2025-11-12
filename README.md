# Lab 1 · Integración segura de una API REST (NewsAPI + Flutter)

## Descripción

Este proyecto es la solución al **Lab 1: Consumir una API REST con manejo de secretos**.

En lugar de usar OpenWeatherMap, se utiliza **NewsAPI** (el enunciado permite clima *o* noticias).  
La app está hecha en **Flutter** y consume la API de noticias de forma segura usando `.env` para la API key y mostrando una UI con manejo de errores y distintos estados.

---

## Objetivo del lab

> Integrar de manera segura una API REST (clima u noticias) con:
> - Manejo de secretos
> - Manejo de errores
> - Validación de entrada
> - Buenas prácticas (timeouts, sanitización, etc.)

En este proyecto se cumple:

- ✅ Consumo de **NewsAPI** (`GET /v2/everything`)
- ✅ Pantalla con estados: **vacío / cargando / error / datos**
- ✅ Manejo de secretos con **.env + flutter_dotenv**
- ✅ Manejo de errores HTTP (401, 429, otros), timeouts y errores de red
- ✅ Validación y sanitización de entrada/salida
- ✅ Buenas prácticas: retry exponencial y cache defensiva
- ✅ Pruebas en emulador y dispositivo físico (evidencia con capturas)

---

## Tecnologías y dependencias

- **Flutter**
- **Dart**
- **Paquetes:**
  - [`http`](https://pub.dev/packages/http)
  - [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv)

En `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  http: ^1.2.0
  flutter_dotenv: ^5.1.0
  cupertino_icons: ^1.0.8

flutter:
  uses-material-design: true
  assets:
    - .env
