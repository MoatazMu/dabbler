# Dabbler Flutter App

Dabbler is a Flutter application. This repository tracks the mobile codebase and uses two primary branches:

- **main**: The primary development branch that accumulates changes after review.
- **release/v1.0.0**: A release branch cut from `main` and kept aligned for production/Play Store builds.

Use `flutter pub get` to install dependencies before running the app, and keep secrets in a local `.env` file (see `.gitignore`).

## GitHub Pages (Flutter Web) deployment
The workflow `.github/workflows/deploy-web.yml` builds the Flutter web bundle with the correct base href for GitHub Pages (`/dabbler-app/`) and deploys it to the `gh-pages` branch. It runs on pushes to `main` or manually via **Run workflow**.

After the first successful run, enable GitHub Pages to serve from the **GitHub Actions** source (Settings → Pages → Build and deployment). The site will be available at `https://moatazmustapha.github.io/dabbler-app/`.
