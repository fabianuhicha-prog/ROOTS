# ROOTS & ROUTES Coffee · Market — Web comercial V3

Sitio web comercial estático (**no es DalyAccounting ni su código base**). Repositorio público `fabianuhicha-prog/ROOTS` con área de integración `staging`.

## Estado real
- Código y 5 sucursales preparados para pruebas; **publicación en Namecheap pendiente de verificar**.
- La web utiliza HTML/CSS/JavaScript, un catálogo de 1.361 productos y una carta digital de 49 opciones.
- Contenido de `site/` es la única carpeta que se despliega. Imágenes `.webp` optimizadas respecto al ZIP original.
- Ubicaciones, precios, derechos de uso de imágenes de terceros y contacto requieren confirmación comercial.
- Se conserva `noindex` durante staging para evitar indexación prematura.
- `productos.json` es un inventario público de referencia; la página usa también un catálogo embebido en `index.html`, de modo que actualizar el JSON solo no cambia lo mostrado.

## Pruebas
```bash
python3 scripts/validar_web.py
```
Necesita Python 3 y Node.js para comprobar sintaxis JS. GitHub Actions valida cada push a `staging` y `main`.

## Publicación Namecheap (sin tocar DalyAccounting)
El despliegue no se dispara automáticamente. El workflow `deploy-roots-staging.yml` se ejecuta manualmente, solo desde `staging`, después de configurar un directorio independiente y SSH propio en cPanel/GitHub.

Objetivo propuesto **sujeto a verificar**: `https://admroots.dalyfinanzas.com`, DocumentRoot `/home/dalypxmu/admroots_pruebas`. La publicación no crea el subdominio ni modifica DNS. Para activar el despliegue, verificar previamente que la carpeta sea exclusiva de ROOTS y colocar el marcador `.roots-web-deploy-approved`. Leer `docs/NAMECHEAP.md`.

Nunca utilizar `pruebas.dalyfinanzas.com`, las carpetas del ERP o las credenciales de DalyAccounting.
