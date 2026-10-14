# Instalación Namecheap — ROOTS & ROUTES (independiente)

**No desplegado todavía.** Procedimiento para personal autorizado a cPanel.

1. Verifica en cPanel que `admroots.dalyfinanzas.com` pertenece al hosting correspondiente y que su DocumentRoot es `/home/dalypxmu/admroots_pruebas` (sin redirecciones ni enlaces simbólicos a DalyAccounting). Verifica DNS, HTTPS y espacio. **No** apuntes a carpetas existentes de otro sistema.
2. Crea el directorio independiente si no existe; inspecciona el contenido y haz respaldo externo verificado. El flujo falla si el directorio no existe, no pertenece a `dalypxmu` o no tiene un marcador de autorización.
3. Tras constatar que la carpeta es exclusiva de ROOTS, crea un archivo vacío `.roots-web-deploy-approved` dentro del DocumentRoot. Nunca lo incorpores al repositorio ni lo copies a carpetas ajenas.
4. Genera un nuevo par de claves SSH exclusivo para ROOTS, autorízalo en cPanel, configura permisos mínimos y verifica la huella SSH del host por un canal independiente. No compartas ni reutilices claves de DalyAccounting.
5. En GitHub, environment `roots-staging`, define estos secretos: `ROOTS_WEB_SSH_HOST`, `ROOTS_WEB_SSH_USER`, `ROOTS_WEB_SSH_PORT`, `ROOTS_WEB_SSH_PRIVATE_KEY`, `ROOTS_WEB_SSH_KNOWN_HOSTS`. El workflow acepta únicamente host `business70.web-hosting.com`, user `dalypxmu` y puerto `21098`. Verifica primero que siguen vigentes.
6. Espera el pase de CI. Desde GitHub Actions, ejecuta manualmente `Publicar ROOTS staging en Namecheap` seleccionando rama `staging` y confirmación `PUBLICAR_ROOTS_STAGING`. Se requiere aprobación del environment si se configura.
7. Verifica `https://admroots.dalyfinanzas.com` en navegador y móvil, HTTPS, imágenes, catálogo, carta, Google Maps, WhatsApp y todos los botones. Comprueba respaldos y restauración antes de uso permanente.
8. Para detener o revertir, conserva el archivo de respaldo `pre_*.tar.gz` indicado en el log del despliegue y restáuralo solo en la carpeta ROOTS bajo supervisión autorizada. La restauración no se realiza automáticamente.

**Pendientes comerciales conocidos**: WhatsApp de longitud inusual `5939998600036`, direcciones de sucursales provisionales, precios sujetos a confirmación, imágenes de productos enlazadas a terceros. Mantener `noindex` hasta verificar todos estos elementos.

No reinicies Passenger ni modifiques DNS, cPanel o la configuración Python de DalyAccounting. ROOTS es un sitio estático sin WSGI.
