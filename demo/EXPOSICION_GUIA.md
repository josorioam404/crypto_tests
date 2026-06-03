# Guía de Exposición: Requerimientos No Funcionales de Seguridad

Esta guía detalla los pasos exactos que el expositor debe seguir en vivo para demostrar al profesor que los dos requerimientos (SSL y Rate Limiting) están implementados y funcionan correctamente.

---

## 💥 Demostración 1: RNF 2 - Defensa contra DoS (Rate Limiting)

**Objetivo:** Mostrar visualmente en la terminal cómo un ataque tumba (o carga inmensamente) el servidor sin protección, y cómo es neutralizado inmediatamente cuando el Rate Limiting está encendido.

**Herramientas requeridas:**
*   Tener el script `demo_ddos.sh` (ubicado en esta carpeta).
*   Tener instalado Apache Benchmark (`sudo apt-get install apache2-utils` o `brew install httpd`).
*   Tener acceso al archivo `gateway/nginx.conf`.

### Paso a paso en vivo:
1. Abre tu IDE y muestra el archivo `adopti/gateway/nginx.conf`.
2. Dirígete a la sección `location /api/pets {` (aprox. línea 104).
3. **Comenta** las dos líneas de rate limiting para simular el servidor vulnerable:
   ```nginx
   # limit_req zone=api_general burst=20 nodelay;
   # limit_req_status 429;
   ```
4. Abre la terminal, aplica el cambio reiniciando el contenedor y lanza el script:
   ```bash
   docker restart Adopti_gateway
   cd adopti/crypto_tests/demo
   ./demo_ddos.sh
   ```
5. **Explica al profesor:** "Aquí estamos viendo un ataque directo con 500 peticiones concurrentes al endpoint de estadísticas de mascotas. Al no haber protección, nuestro microservicio en Python tiene que procesar y responder con HTTP 200 a cada conexión." El script mostrará 0 fallos.
6. **Activa la protección:** Vuelve al IDE y **descomenta** las dos líneas en el `gateway/nginx.conf`.
7. Presiona **ENTER** en la terminal donde está corriendo el script (esto volverá a disparar el ataque, pero NGINX ya tendrá los límites activos).
8. **Conclusión:** Muestra en la terminal cómo la salida ahora indica un alto número de `Non-2xx responses`. Explica que NGINX interceptó y descartó el ataque devolviendo un rápido error HTTP 429, protegiendo así al servidor interno de caerse.

---

## 🔒 Demostración 2: RNF 1 - SSL / HTTPS y mTLS

**Objetivo:** Capturar credenciales en texto plano (simulando una red sin cifrar) vs. mostrar cómo el tráfico viaja completamente ofuscado gracias a TLS 1.3.

**Herramientas requeridas:**
*   Wireshark instalado y ejecutándose como Administrador/Root.
*   Navegador web listo en `http://localhost/login`.

### Paso a paso en vivo:

#### Fase A: El Peligro del Texto Plano (Configuración temporal)
Dado que Adopti redirige forzosamente de HTTP a HTTPS, para demostrar la vulnerabilidad debes desactivar temporalmente el candado.
1. Abre `adopti/reverse-proxy/nginx.conf`.
2. Modifica el Bloque 1 (`listen 80;`) comentando el redirect y agregando el pase directo al frontend:
   ```nginx
   location / {
       # return 301 https://$host$request_uri;  <-- COMENTAR
       proxy_pass http://frontend:3000;         <-- AGREGAR
   }
   ```
3. Guarda y reinicia el contenedor: `docker restart Adopti_reverse_proxy`.
4. **En Wireshark:** Inicia la captura seleccionando la interfaz de loopback (`lo` o `loopback`). Usa el filtro: `http.request.method == "POST"`.
5. Ve a `http://localhost/login` (asegúrate de NO usar https://) e intenta hacer login con credenciales de prueba.
6. **Explica al profesor:** En Wireshark, abre el paquete capturado. Expande "Hypertext Transfer Protocol" o "JSON payload". Muéstrale cómo la contraseña se lee claramente en la red.

#### Fase B: Cifrado SSL/TLS Activado
1. Vuelve a dejar el `reverse-proxy/nginx.conf` seguro:
   ```nginx
   location / {
       return 301 https://$host$request_uri;
       # proxy_pass http://frontend:3000;
   }
   ```
2. Guarda y reinicia el contenedor: `docker restart Adopti_reverse_proxy`.
3. **En Wireshark:** Limpia la captura actual y cambia el filtro a: `tls.handshake.type || tcp.port == 443`.
4. Ve a `https://localhost/login` e intenta hacer login.
5. **Explica al profesor:** Muestra los paquetes "Application Data" que viajan por el puerto 443. Al inspeccionarlos, solo verás bytes cifrados ("Encrypted Application Data"). Explícale que ahora la red usa AES-256-GCM y que es matemáticamente inviable para un atacante en la red WiFi robar la contraseña de Firebase.
