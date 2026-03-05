# Contributing to Elyf Group App

This project follows a professional Git branching strategy based on a simplified GitFlow model to ensure stability and continuous delivery.

## Git Branching Strategy

### Core Branches

1.  **`main`**: The stable production branch. Code here is always ready for release.
2.  **`develop`**: The integration branch for ongoing development. All features are merged here before being prepared for a release.

### Supporting Branches

## Branch Naming Policy

We use **kebab-case** for all branch names.

*   **`feature/pos-payment`** (Example: `feature/sale-module`)
*   **`hotfix/login-crash`** (Example: `hotfix/payment-bug`)
*   **`release/v1.0.0`**

## Development Workflow

### 1. Working on Features
1.  Create a feature branch from `develop`:
    ```bash
    git checkout develop
    git pull origin develop
    git checkout -b feature/my-cool-feature
    ```
2.  Develop and test your changes locally:
    ```bash
    flutter analyze
    flutter test
    ```
3.  Open a Pull Request (PR) into `develop`.
4.  Once reviewed and CI passes, merge into `develop`.

### 2. Preparing a Release
1.  Create a release branch from `develop`:
    ```bash
    git checkout -b release/v1.0.0
    ```
2.  Perform final bug fixes and version bumps in `pubspec.yaml`.
3.  Merge into `main` and `develop`.
4.  Tag the release on `main` (the tag must match the `versionName` in `pubspec.yaml`):
    ```bash
    git checkout main
    git tag -a v1.0.0 -m "Release v1.0.0"
    ```

### 3. Fixing Production Issues (Hotfixes)
1.  Create a hotfix branch from `main`:
    ```bash
    git checkout main
    git checkout -b hotfix/critical-bug-fix
    ```
2.  Fix the issue.
3.  Merge into both `main` and `develop`.

## Merge & Deployment Flow

To ensure a high level of quality, follow this merge flow:

1.  **Feature Merge**: `feature/*` → `develop`
    *   Triggered by a Pull Request.
    *   Requires code review and passing CI tests.
2.  **Release/Hotfix Merge**: `develop` (or `hotfix/*`) → `main`
    *   Only for stable, tested code.
    *   Triggers the production build and deployment process (CI/CD).

## Monitoring

After deployment, monitor the application's health using:
*   **Firebase Crashlytics**: To detect and track runtime crashes.
*   **Firebase Performance**: To monitor app responsiveness and network latency.

## CI/CD Workflow

Our GitHub Actions workflow automatically:
*   Runs analysis and tests on all `feature/*` branches.
*   Runs full tests and builds the app on `develop`.
*   Prepares release artifacts on `main`.
