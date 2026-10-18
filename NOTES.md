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

### Git: deshacer un commit

Si hago un commit con errores o simplemente quiero quitarlo, hay dos herramientas. Cuál
uso depende de si ya he hecho push o no:

- **`git reset`**: mueve la rama hacia atrás y el commit desaparece del historial. Solo
  para commits que están en mi máquina.
- **`git revert`**: crea un commit nuevo que deshace los cambios del otro. No borra nada
  del historial. Para commits que ya están publicados.

La regla: **el historial local se puede reescribir; el publicado no.** Si reescribo algo
que otra persona ya ha descargado, su trabajo queda apoyado en commits que ya no existen.

`reset` tiene tres modos, según lo que hace con los cambios del commit que quito:

| Modo | Los cambios del commit |
|---|---|
| `--soft` | Se quedan en el staging |
| `--mixed` (por defecto) | Se quedan en mis ficheros, fuera del staging |
| `--hard` | Se borran: los ficheros quedan como en el commit al que vuelvo |

Ojo con `--hard`: también borra cualquier cambio que tuviera sin confirmar, sin preguntar.
Hacer `git status` antes.

### Git: recuperar un commit borrado

Si quito un commit por error con `reset`, se puede recuperar:

- `git reflog` enseña todos los sitios por los que ha pasado mi `HEAD`, también los
  commits que ya no están en ninguna rama.
- `git cherry-pick <hash>` copia ese commit a la rama en la que estoy.

Solo sirve para lo que llegó a estar en un commit. Los cambios que nunca confirmé y borré
con `--hard` no se pueden recuperar.

Me pasó: hice un commit de prueba con un cambio de `PLAN.md`, lo quité con `reset --hard`
y perdí ese cambio. Lo recuperé con `reflog` y `cherry-pick`.

### Git: cambiar el mensaje de un commit

`git commit --amend -m "Nuevo mensaje"`. Solo vale para el último commit.

No edita el commit: lo sustituye por uno nuevo con otro hash. Por eso es reescribir
historial y solo se hace antes del push. También mete en el commit lo que haya en el
staging, así que `git status` antes.

## 2026-10-18 — Diseño del modelo de datos

### El modelo

```
app_user      (id PK, email NOT NULL UNIQUE, password_hash NOT NULL, name NOT NULL)

expense_group (id PK, name NOT NULL, invite_code NOT NULL UNIQUE)

member        (id PK, name NOT NULL,
               user_id  FK → app_user      NULL permitido, ON DELETE SET NULL,
               group_id FK → expense_group NOT NULL,       ON DELETE CASCADE,
               UNIQUE (group_id, name), UNIQUE (group_id, user_id))

expense       (id PK,
               payer_id FK → member        NOT NULL,
               group_id FK → expense_group NOT NULL, ON DELETE CASCADE,
               amount numeric(7,2) NOT NULL CHECK (amount > 0),
               expense_day date NOT NULL, description NOT NULL)

share         (id PK,
               member_id  FK → member  NOT NULL,
               expense_id FK → expense NOT NULL, ON DELETE CASCADE,
               amount numeric(7,2) NOT NULL CHECK (amount > 0),
               UNIQUE (member_id, expense_id))
```

Todos los `id` son `bigint GENERATED ALWAYS AS IDENTITY`. Todas las FK son `bigint`.
Los textos son `text`.

Por qué es así:

- `app_user` es solo la cuenta. `member` es alguien dentro de un grupo, con cuenta o sin
  ella (invitado: `user_id` a `NULL`). Los gastos apuntan a `member`, no a `app_user`, para
  que los invitados puedan pagar y deber.
- El nombre vive en `member`, no en `app_user`, para que un invitado tenga nombre y para
  que siga ahí si se borra la cuenta.
- `share` es una fila por persona y gasto: "a este miembro le toca esta cantidad de este
  gasto". Permite repartos no equitativos.

### Conceptos

- **Clave primaria con identity**: la identidad de la fila. La genera PostgreSQL al
  insertar, con una secuencia (1, 2, 3...). Solo en la clave primaria.
- **Clave foránea**: una referencia a una fila de otra tabla. Es un `bigint` normal que
  decido yo al insertar ("este miembro va en el grupo 7"); PostgreSQL solo comprueba que
  ese id exista. Lleva `_id` en el nombre porque guarda un id, no el objeto entero.
- **La FK va en el lado del "muchos"**: un grupo tiene muchos miembros, así que
  `group_id` va en `member`.
- **Nombrar la FK por su papel**: `payer_id`, no `member_id`, porque dice qué hace ese
  miembro en el gasto.
- **Una FK puede ser nula**: sin `NOT NULL`, la referencia es opcional. Si tiene valor,
  ese valor tiene que existir.
- **`UNIQUE`** impide valores repetidos. Admite nulos, y en PostgreSQL dos `NULL` no
  cuentan como iguales. Puede abarcar varias columnas: entonces lo que no se repite es la
  combinación.
- **`numeric(precisión, escala)`**: precisión = dígitos en total, escala = cuántos van
  tras la coma. `numeric(7,2)` llega a 99.999,99. Si solo pongo un número, la escala es 0.
- **`CHECK`** comprueba una condición sobre la fila, por ejemplo que el importe sea
  positivo. Solo ve una fila a la vez.
- **`ON DELETE`** dice qué pasa con las filas que apuntan a otra cuando esa otra se borra:
  - `CASCADE`: se borran también.
  - `SET NULL`: la FK se pone a `NULL`.
  - `RESTRICT`: se impide el borrado, comprobando en el momento.
  - Sin nada (`NO ACTION`): se impide el borrado, pero comprobando al final de la
    operación. Lo uso en las FK a `member`: con `RESTRICT`, borrar un grupo podría fallar
    en mitad de la cascada.
- **No guardar lo que se puede calcular**: quité `member_count` porque se cuenta con una
  consulta. Guardarlo aparte crea dos verdades que pueden no coincidir.

### Lo que la base de datos no comprueba

Estas reglas implican varias filas o varias tablas, así que irán en el código Java:

- La suma de los `share` de un gasto es igual al `amount` del gasto.
- El `payer_id` de un gasto es un miembro del mismo grupo que el gasto.

### Errores que me costaron

- **Identity en las claves foráneas.** Lo puse en todas las FK. Cada fila nueva habría
  recibido el siguiente número de la secuencia, sin importar a qué grupo o miembro quería
  apuntar.
- **`UNIQUE` sobre una sola columna.** `name UNIQUE` en `member` hacía el nombre único en
  toda la app; `member_id UNIQUE` en `share` dejaba a cada miembro participar en un solo
  gasto. Lo que quería era único dentro de algo: `UNIQUE (group_id, name)`.
- **FK en la dirección equivocada.** Puse `expense_id` en `member`, que habría
  significado un gasto por miembro.
- **`numeric(2)`**: creía que eran dos decimales y era "dos dígitos en total", máximo 99.
- **Palabras reservadas.** `user` y `group` no se pueden usar como nombre de tabla en
  PostgreSQL.
