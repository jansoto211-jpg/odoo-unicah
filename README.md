# Despliegue de Odoo (ventas_unicah) en la nube gratuita

Kit sin probar en un servidor real: revise cada paso y anote lo que realmente le pase (sirve para la sección "Problemas" del PDF).

## 0. Elegir ruta según tenga o no tarjeta Visa/Mastercard

| Ruta | Necesita tarjeta | Qué es | Riesgo principal |
|---|---|---|---|
| A. Oracle Cloud Always Free (VM) | Sí (solo verificación) | VM Linux con Docker: Odoo + PostgreSQL en el mismo servidor | Falta de capacidad ARM al crear la VM; la cuota ARM pudo bajar a 2 OCPU / 12 GB |
| B. Render (plan Free) | No | Contenedor Docker + PostgreSQL gestionado | 512 MB de RAM (Odoo puede quedarse sin memoria al instalar); la base gratuita caduca a los 30 días; el servicio se duerme a los 15 min |

Verifique los límites en las páginas oficiales el día que despliegue: cambian seguido.

## Ruta A: Oracle Cloud + Docker Compose

1. Cree la cuenta en oracle.com/cloud/free y elija la región de origen con cuidado (no se puede cambiar).
2. Compute > Instances > Create: imagen Ubuntu 24.04, forma VM.Standard.A1.Flex (ARM) con 2 OCPU y 12 GB, IP pública, suba su llave SSH.
3. Red (VCN > Security List): abra TCP 80 y 443 de entrada (0.0.0.0/0).
4. Conéctese por SSH y abra el firewall interno de Ubuntu:
   ```
   sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
   sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
   sudo apt update && sudo apt install -y docker.io docker-compose-v2 git netfilter-persistent
   sudo netfilter-persistent save
   sudo usermod -aG docker $USER   # cierre y abra sesión
   ```
5. Clone su repositorio con este kit: `git clone https://github.com/USUARIO/REPO.git && cd REPO`
6. `cp .env.example .env` y edítelo: claves nuevas, y `DOMAIN` = su IP con guiones + `.sslip.io` (IP 129.146.10.20 -> `129-146-10-20.sslip.io`).
7. `docker compose up -d --build` y siga con `docker compose logs -f odoo` hasta ver que Odoo arrancó.
8. Abra `https://TU-DOMINIO` (Caddy obtiene el certificado solo).
9. Cuando la base ya esté inicializada, deje `ODOO_INIT=` vacío en `.env` y ejecute `docker compose up -d`.

## Ruta B: Render

1. Suba este kit a un repositorio de GitHub (sin `.env`).
2. En Render: New > PostgreSQL, plan Free. Copie la **Internal Database URL**.
3. New > Web Service > su repositorio, Runtime Docker, plan Free. Variables de entorno:
   - `DATABASE_URL` = la Internal Database URL
   - `ADMIN_PASSWD` = clave maestra larga
   - `ODOO_INIT` = `base,sale_management,ventas_unicah`
4. Si el despliegue muere por memoria (OOM) al instalar: inicialice la base en su PC y restáurela en Render con la **External Database URL**:
   ```
   pg_dump -Fc -h localhost -U odoo NOMBRE_BD > respaldo.dump
   pg_restore --no-owner --no-privileges -d "EXTERNAL_DATABASE_URL" respaldo.dump
   ```
   Después quite `ODOO_INIT`. Copie también el filestore si lo necesita.
5. Anote la fecha de creación de la base: caduca a los 30 días; avise al revisor o migre a una base gratuita sin caducidad (por ejemplo Neon) antes de entregar.

## Usuario administrador para la revisión (ambas rutas)

1. Entre como el usuario inicial y cambie su contraseña (nunca deje admin/admin).
2. Ajustes > Usuarios y compañías > Usuarios > Nuevo.
3. Nombre y correo del revisor; en Permisos de acceso: Administración = Ajustes, y Ventas = Administrador (necesario para el botón "Aprobar" de ventas_unicah).
4. Guarde, use "Enviar invitación" o asigne contraseña con "Acción > Cambiar contraseña", y pruebe iniciar sesión en una ventana privada.

## Verificación sugerida (capturas para el PDF)

- Pantalla de la plataforma con el servicio/base creados y su configuración (sin mostrar contraseñas).
- Variables de entorno con los valores sensibles ocultos.
- Logs con "modules loaded" / arranque correcto.
- Aplicaciones instaladas: Ventas y Ventas UNICAH.
- Campo "Canal preferido" en un contacto y pedido de más de 50 000 que exige aprobación.
- La URL pública con candado HTTPS.
