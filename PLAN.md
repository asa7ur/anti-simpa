# Plan del proyecto: app de gastos compartidos

App tipo Tricount/Splitwise para repartir gastos entre grupos de personas.
Objetivo real: **aprender Spring (y el resto del stack) construyendo algo de principio a fin**,
no solo tener la app terminada.

## Stack

- Backend: Java 25 (LTS) + Spring Boot 4
- Base de datos: PostgreSQL (Oracle Free en Docker como alternativa para practicar Oracle)
- Migraciones: Flyway
- Tests: JUnit 5, Mockito, Testcontainers
- Frontend: Angular + TypeScript
- Despliegue: servidor propio en Hetzner (Docker, docker compose, Nginx, Let's Encrypt)
- CI/CD: GitHub Actions

> Importante: en el servidor de Hetzner también está desplegado mi TFG.
> Todo debe ir en contenedores aislados para no romperlo.

## Fases

Regla: no se pasa a la siguiente fase hasta que la anterior funciona y tiene tests.

### Fase 1: Base de la API
- [ ] Entidades: usuarios, grupos, gastos y participantes de cada gasto
- [ ] CRUD REST con Spring Boot + JPA
- [ ] DTOs separados de las entidades
- [ ] Validaciones con `@Valid` y manejo global de errores con `@ControllerAdvice`
- [ ] Migraciones de base de datos con Flyway
- [ ] Dinero siempre con `BigDecimal` (entender por qué no `double`)

### Fase 2: Tests
- [ ] Tests unitarios de services con JUnit + Mockito
- [ ] Tests de integración con Testcontainers (base de datos real)

### Fase 3: Seguridad
- [ ] Spring Security: registro y login con JWT
- [ ] Autorización: solo los miembros ven un grupo, solo el admin lo borra
- [ ] Entender la cadena de filtros de Spring Security

### Fase 4: Lógica de negocio
- [ ] Cálculo de balances por grupo
- [ ] Algoritmo de simplificación de deudas (mínimo de transferencias)
- [ ] Repartos no equitativos (porcentajes, importes)
- [ ] Uso correcto de `@Transactional` y control de concurrencia

### Fase 5: Frontend en Angular
- [ ] Login, lista de grupos, detalle de grupo con gastos y balances
- [ ] Interceptor HTTP para el JWT y guards en las rutas
- [ ] RxJS en serio (`pipe`, `switchMap`, manejo de errores)

### Fase 6: Despliegue en Hetzner
- [ ] Dockerizar backend y frontend, orquestar con docker compose
- [ ] Nginx como proxy inverso + HTTPS con Let's Encrypt
- [ ] CI/CD con GitHub Actions (push → tests → despliegue)

### Fase 7: Avanzado (elegir lo que apetezca)
- [ ] Multi-divisa con API externa de tipos de cambio (`RestClient`) + caché
- [ ] Tareas programadas con `@Scheduled` (recordatorios por email)
- [ ] Subida de fotos de tickets
- [ ] Paginación, filtros y búsqueda
- [ ] Observabilidad: Actuator, Prometheus, Grafana
- [ ] WebSockets para actualizaciones en tiempo real
- [ ] Eventos con RabbitMQ o Kafka

### Fase 8: Puente a Python y LLMs
- [ ] Microservicio en Python (FastAPI) que extraiga importe, fecha y comercio
      de la foto de un ticket usando un LLM
- [ ] Spring llama a ese servicio y rellena el gasto automáticamente

## Hábitos

- Git desde el primer día, commits pequeños con mensajes claros
- Cada tarea se define como un ticket (requisitos + criterios de aceptación) antes de programar
- Diario de aprendizaje en `NOTES.md`: qué aprendí y qué errores me costaron
