# Diario de aprendizaje

## 2026-10-04 — Creación del proyecto y primer error de arranque

### Spring Initializr

- start.spring.io es la forma estándar de crear un proyecto. Los asistentes de los IDE llaman
  al mismo servicio.
- **Group**: dominio que controlo, al revés (`io.github.miusuario` si no tengo dominio).
- **Artifact**: nombre del proyecto, en minúsculas y con guiones. Es el nombre del `.jar`.
- **Package name**: group + artifact, pero sin guiones (Java no los permite en paquetes).
  Es el más molesto de cambiar después.
- Las dependencias solo son líneas en el `pom.xml`. Se pueden añadir a mano más tarde.
- SNAPSHOT y M2 son versiones en desarrollo. Se elige la que no lleva etiqueta.

### Autoconfiguración

Al arrancar, Spring Boot mira qué librerías hay en el classpath y crea objetos por mí
según lo que encuentra.

- Ve Spring Web → arranca un Tomcat en el puerto 8080.
- Ve Spring Data JPA → intenta crear un `DataSource`.

Consecuencia: una dependencia puede cambiar el comportamiento de la app solo por estar
presente, sin que yo escriba código. (Ejemplo que me espera: Spring Security protege
todos los endpoints en cuanto se añade.)

### DataSource

Es el objeto que da conexiones a la base de datos. En la práctica es un pool: conexiones
ya abiertas que se prestan y se devuelven. El que usa Spring Boot por defecto es HikariCP.

### Error: `Failed to configure a DataSource: 'url' attribute is not specified`

- **Causa**: tengo JPA en el proyecto pero no he configurado la URL de la base de datos.
- El `Reason` dice `Failed to determine a suitable driver class` y despista: el driver sí
  está en el `pom.xml`. Spring elige el driver por el principio de la URL
  (`jdbc:postgresql://...`), así que sin URL no sabe cuál usar.
- Las `Action` que sugiere (base de datos embebida, perfiles) son genéricas. No seguirlas
  a ciegas.

### Cómo leer un error de arranque de Spring

1. Empezar por el bloque final `APPLICATION FAILED TO START`: `Description`, `Reason`,
   `Action`. No siempre aparece.
2. La línea `WARN` larga es el error real. Es una cadena de "no pude crear A porque no
   pude crear B porque...". Se parte por cada `Error creating bean with name` y se lee
   **de derecha a izquierda**: lo último es la causa raíz.

En mi caso: `entityManagerFactory` ← `inMemoryDatabaseShutdownExecutor` ← `dataSource`
← no hay URL.

### Documento `compose.yaml`

Describe los contenedores Docker que quiero levantar, para no escribir un `docker run`
larguísimo cada vez. Yo lo uso para la base de datos, pero sirve para cualquier contenedor.

Qué contiene el mío:

1. **`image`**: el nombre de la imagen con su versión (`postgres:18.6-alpine`). Siempre
   una versión concreta; sin ella usa `latest` y puede cambiar sin avisar.
2. **`ports`**: `"puerto_de_mi_máquina:puerto_del_contenedor"`. El de la derecha no lo
   elijo yo: es donde escucha el programa de dentro (PostgreSQL: 5432). El de la
   izquierda sí puedo cambiarlo. No son entrada y salida: son dos puertas en dos
   máquinas distintas que Docker une.
3. **`environment`**: variables que recibe el contenedor (usuario, contraseña, nombre de
   la base de datos). Los nombres los decide la imagen. Los valores no los escribo en el
   archivo: pongo `${NOMBRE}` y Docker los saca del fichero `.env`.
4. **`volumes`**: un volumen donde se guardarán los datos de la base de datos, para no
   perderlos al borrar el contenedor. La ruta de dentro del contenedor depende de la
   imagen; si está mal no da error, simplemente no guarda nada.

Cosas que me costaron:

- Copié el ejemplo de Docker Hub y traía cosas que no necesitaba (Adminer, `restart`,
  `shm_size`). Regla: si no sé explicar una línea, la investigo o la quito.
- Cambiar el `compose.yaml` no cambia un contenedor que ya existe. Hay que volver a
  ejecutar `docker compose up -d`.
- `docker compose config` enseña el archivo con los `${...}` ya sustituidos.
- `compose.yaml` y `docker compose` (con espacio) son los nombres actuales;
  `docker-compose.yml` y `docker-compose` son los antiguos.

### Git: sacar un archivo del staging

El `.gitignore` solo afecta a archivos que git todavía no conoce. Si ya hice `git add`
de un archivo, sigue dentro aunque luego lo añada al `.gitignore`.

Para sacarlo: `git rm --cached archivo`. El `--cached` lo quita solo del staging; sin
él, borra el archivo del disco. Se añade -f en caso de que el fichero ya ha tenido cambios tras añadirlo.
