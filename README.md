# CIARA — Flutter Mobile Research Prototype

**Flutter · Dart · Android · iOS project structure**

## Overview

This repository contains a Flutter application developed in the context of a university research project focused on **digital-device usage and cyberaddiction**.

The code includes onboarding and consent screens, preferences, app-usage-related dependencies, local storage, notification-related dependencies, and data-visualization packages. The presence of dependencies does not guarantee that every feature is working on every supported platform.

## Technical Scope

- Flutter UI implemented primarily in `lib/main.dart`.
- Packages for app usage statistics, permission handling, device applications, notifications, and charts.
- Android and iOS project folders, with Android-oriented usage-statistics functionality requiring platform permissions.
- HTTP integration code that must be checked for institutional endpoints and data handling before reuse.

## Academic Ownership & Privacy

**This is university-related research software, not a freely reusable portfolio sample.** Publication rights and authorization from the institution have not been verified. The repository is currently public, but that does **not** mean the code, research data, visual assets, or fonts are licensed for redistribution.

The project should not be promoted as a publicly reusable application until the university has confirmed publication rights and sensitive integrations have been reviewed. Do not enter real participant information when testing a local copy.

## Local Development (authorized users only)

1. Install a Flutter SDK compatible with `pubspec.yaml`.
2. Review any institutional service endpoints and permissions before running.
3. Run `flutter pub get`, then `flutter run` on a configured device or emulator.

Build and runtime behavior have **not** been independently validated for this repository.

## Portfolio Description

A public-facing technical case study can describe the author's contribution (Flutter development, client-server integration, and app architecture) **without exposing institutional source code or research data**.

**Status:** Academic project; publication and privacy review pending.
