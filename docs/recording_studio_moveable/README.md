> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_moveable](https://github.com/bowerbird-app/RecordingStudio_moveable/tree/main/docs/recording_studio_moveable)
> *   **Last Updated:** July 29, 2026
>
> *Maintainers: Please update the date above when modifying this file.*

---

# RecordingStudioMoveable

Addon-owned move behavior and UI for RecordingStudio.

---

## ✅ What's Working

- ✓ Rails Engine mounted and operational
- ✓ PostgreSQL with UUID primary keys
- ✓ TailwindCSS styling (auto-rebuilds in development)
- ✓ Codespaces environment automatically sets up on build
- ✓ Install generator for host applications
- ✓ Migrations generator for database setup
- ✓ Service object pattern with Result monad

---

## 🚀 Quick Start

### GitHub Codespaces (Recommended)

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for setup to complete (~3-5 minutes)
3. Run:
   ```bash
   cd test/dummy
   bin/dev
   ```
4. Open port 3000 and visit `/recording_studio_moveable`

→ [Codespaces Setup Guide](CODESPACES.md)

### Local Development

1. Clone and install dependencies
2. Setup database and build Tailwind
3. Run `bin/dev`

→ [Local Development Guide](LOCAL_DEVELOPMENT.md)

---

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Renaming](RENAMING.md) | Notes on the historical rename away from the generic engine template. |
| [Installation](INSTALLING.md) | Step-by-step guide for installing this engine in a host Rails application. |
| [Upgrading](UPGRADING.md) | Breaking changes for RecordingStudio core V3 compatibility and the `Moveable.enabled(...)` API. |
| [Configuration](CONFIGURATION.md) | Details on configuring the gem, including move redirect modes and custom redirect resolution. |
| [Optional API Action](API.md) | Installing and configuring the optional RecordingStudioApi move action. |
| [Private Gems](PRIVATE_GEMS.md) | How to authenticate and access private gem dependencies in Codespaces, local, and production environments. |
| [Database Migrations](MIGRATIONS.md) | How to generate and manage database migrations for the engine. |
| [Service Objects](SERVICES.md) | Explanation of the Service Object pattern and Result monad used for business logic. |
| [Engine Hooks](HOOKS.md) | Guide to customizing engine behavior using lifecycle and service hooks. |
| [Asset Architecture](CSS_JS_ASSETS_ARCHITECTURE.md) | Details on TailwindCSS setup and asset pipeline integration. |
| [Security](SECURITY.md) | Security considerations. |
| [Changelog](../../CHANGELOG.md) | Version history. |

---

## 📁 Project Structure

```
recording_studio_moveable/
├── app/
│   ├── controllers/recording_studio_moveable/
│   └── views/recording_studio_moveable/
├── config/routes.rb
├── db/migrate/              # Engine migrations
├── lib/
│   ├── recording_studio_moveable.rb
│   ├── recording_studio_moveable/
│   │   ├── configuration.rb
│   │   ├── engine.rb
│   │   ├── version.rb
│   │   └── services/        # Service objects
│   │       ├── base_service.rb
│   │       └── example_service.rb
│   └── generators/
├── test/dummy/              # Test Rails app
├── docs/                    # Documentation
└── recording_studio_moveable.gemspec
```

---

## 📋 Tech Stack

| Component | Version |
|-----------|---------|
| Ruby | 3.3 |
| Rails | 8.1 |
| PostgreSQL | 16 |
| Redis | 7 |
| TailwindCSS | 4 |

---

## 📄 License

MIT – see [MIT-LICENSE](../../MIT-LICENSE)

---

This documentation tracks the current addon, not the original template.
