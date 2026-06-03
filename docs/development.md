# Development

---

**English** · [Español](#espa%C3%B1ol)

---

## English

### Quick start

```bash
# Enable pre-commit hooks (runs shellcheck + bats on every commit)
make hooks

# Manual lint
shellcheck -S warning -s bash privacity lib/*.sh

# Manual tests
bats tests/*.bats

# Syntax check
bash -n privacity lib/*.sh
```

### Test suite

24 tests across two files:

| File | Type | Area |
|---|---|---|
| `tests/flow.bats` | Integration | Help, status, speedtest, net.sh, speed.sh, CSV download |
| `tests/privacity.bats` | Unit | parse_servers, write_config, _stat_mtime, VERSION, get_external_ip |

Run all tests:

```bash
bats tests/*.bats
```

Run a specific test:

```bash
bats tests/privacity.bats -f "VERSION"
```

### Adding a test

1. Add test data to `tests/fixtures/` if needed
2. Add the `@test` block to the appropriate `.bats` file
3. Run `bats tests/*.bats` to verify
4. Run `shellcheck -S warning privacity lib/*.sh tests/*.bats`

### Code style

- **Shell**: Bash, compatible with `set -euo pipefail`
- **Guard**: Each lib file starts with `[[ -z "${_MODULE_LOADED:-}" ]] || return 0`
- **Functions**: snake_case, prefixed with `_` for private/helper functions
- **Variables**: UPPER for constants/globals, lower for locals
- **Error handling**: Use `die` for fatal errors, `|| true` for non-fatal
- **Logging**: `log` for success, `warn` for warnings, `error` for errors
- **Sudo**: Use `_sudo` helper instead of hardcoding `sudo`

### Pre-commit hook

The pre-commit hook (`.githooks/pre-commit`) runs:

1. `shellcheck -S warning privacity lib/*.sh`
2. `bats tests/*.bats`

If either fails, the commit is blocked. Skip with:

```bash
git commit --no-verify
```

### CI

GitHub Actions runs on every push and PR:

- **shellcheck**: `shellcheck -S warning privacity lib/*.sh`
- **bats**: `bats tests/*.bats`

See `.github/workflows/test.yml`.

### Standalone tools

These lib modules can be run directly for debugging:

```bash
# Network check
./lib/net.sh check
./lib/net.sh ip
./lib/net.sh ping

# Speed test
./lib/speed.sh
```

### Making a release

```bash
# Tag the current commit
git tag -a v1.1.0 -m "Description of changes"
git push origin v1.1.0
```

---

## Español

### Inicio rápido

```bash
# Activar ganchos pre-commit (ejecuta shellcheck + bats en cada commit)
make hooks

# Lint manual
shellcheck -S warning -s bash privacity lib/*.sh

# Pruebas manuales
bats tests/*.bats

# Verificación de sintaxis
bash -n privacity lib/*.sh
```

### Suite de pruebas

24 pruebas en dos archivos:

| Archivo | Tipo | Área |
|---|---|---|
| `tests/flow.bats` | Integración | Ayuda, estado, velocidad, net.sh, speed.sh, descarga CSV |
| `tests/privacity.bats` | Unitarias | parse_servers, write_config, _stat_mtime, VERSION, get_external_ip |

Ejecutar todas las pruebas:

```bash
bats tests/*.bats
```

Ejecutar una prueba específica:

```bash
bats tests/privacity.bats -f "VERSION"
```

### Agregar una prueba

1. Agregar datos de prueba a `tests/fixtures/` si es necesario
2. Agregar el bloque `@test` al archivo `.bats` correspondiente
3. Ejecutar `bats tests/*.bats` para verificar
4. Ejecutar `shellcheck -S warning privacity lib/*.sh tests/*.bats`

### Estilo de código

- **Shell**: Bash, compatible con `set -euo pipefail`
- **Guard**: Cada archivo lib comienza con `[[ -z "${_MODULE_LOADED:-}" ]] || return 0`
- **Funciones**: snake_case, prefijo `_` para funciones privadas/auxiliares
- **Variables**: MAYÚSCULAS para constantes/globales, minúsculas para locales
- **Manejo de errores**: Usar `die` para errores fatales, `|| true` para no fatales
- **Logging**: `log` para éxito, `warn` para advertencias, `error` para errores
- **Sudo**: Usar `_sudo` en lugar de escribir `sudo` directamente

### Gancho pre-commit

El gancho pre-commit (`.githooks/pre-commit`) ejecuta:

1. `shellcheck -S warning privacity lib/*.sh`
2. `bats tests/*.bats`

Si alguno falla, el commit se bloquea. Omitir con:

```bash
git commit --no-verify
```

### CI

GitHub Actions se ejecuta en cada push y PR:

- **shellcheck**: `shellcheck -S warning privacity lib/*.sh`
- **bats**: `bats tests/*.bats`

Ver `.github/workflows/test.yml`.

### Herramientas independientes

Estos módulos lib se pueden ejecutar directamente para depuración:

```bash
# Verificación de red
./lib/net.sh check
./lib/net.sh ip
./lib/net.sh ping

# Prueba de velocidad
./lib/speed.sh
```

### Crear un lanzamiento

```bash
# Etiquetar el commit actual
git tag -a v1.1.0 -m "Descripción de los cambios"
git push origin v1.1.0
```
