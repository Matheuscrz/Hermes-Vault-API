# 🪽 Hermes Vault API

> Um cofre digital corporativo de alta performance projetado para armazenamento seguro, compartilhamento granular e auditoria imutável de documentos sensíveis.

O **Hermes** é um sistema backend robusto construído para resolver desafios reais de I/O pesado, segurança rigorosa (Zero Trust) e rastreabilidade total. Este projeto aplica conceitos avançados de **Segurança, Escalabilidade e Observabilidade**, sendo estruturado sob os princípios de _Domain-Driven Design_ (DDD) com _Bounded Contexts_ bem definidos.

---

## 🚀 Principais Funcionalidades

- **Upload com Zero Trust:** Validação de _Magic Bytes_ (Apache Tika), quarentena e scan de antivírus assíncrono (ClamAV) antes da liberação do documento.
- **Compartilhamento Granular:** Prevenção contra IDOR (Insecure Direct Object Reference) usando UUIDs e verificação rigorosa de _ownership_ via ACL.
- **Auditoria Assíncrona:** Registro imutável de quem acessou, baixou ou compartilhou documentos, processado em background via filas com garantia de entrega.
- **Downloads via Presigned URLs:** Arquivos grandes são baixados diretamente do Storage (MinIO) para o cliente, poupando CPU e memória do servidor web.
- **Defesa de Borda:** Rate Limiting robusto, bloqueio progressivo contra ataques de força bruta e revogação imediata de tokens JWT via _Blacklist_.

---

## 🛠️ Stack Tecnológica

- **Core:** Java 21, Spring Boot 4.0.5, Gradle 8+
- **Banco de Dados:** PostgreSQL (com Flyway para Migrations)
- **Cache & Locks:** Redis (Redisson & Bucket4j)
- **Mensageria:** RabbitMQ (Durable Queues & DLQ)
- **Storage:** MinIO (S3-Compatible)
- **Segurança:** Spring Security, Argon2id, JJWT (HS256)
- **Observabilidade:** Micrometer, Prometheus, Loki, Promtail, Grafana Tempo (OpenTelemetry)
- **Infra Local:** Docker Compose, Mailpit (SMTP Local)
- **Containerização:** Dockerfile para backend e futura inclusão no `docker-compose` junto ao frontend.

---

## 🏗️ Arquitetura e Padrões Aplicados

### 1. Segurança (Security First)

- **Argon2id:** Hash de senhas _memory-hard_ para inviabilizar ataques de força bruta.
- **Autenticação Híbrida:** Access Tokens curtos em memória + Refresh Tokens armazenados via Hash no banco e integrados a uma _Blacklist_ em Redis para logout instantâneo.
- **Rate Limit por Rota:** Restrições baseadas em _Token Bucket_ armazenados no Redis.

### 2. Escalabilidade (High Performance)

- **I/O Assíncrono:** Upload responde `202 Accepted` e o processamento pesado ocorre via _Workers_ no RabbitMQ.
- **Locks Distribuídos:** Redisson garante idempotência e evita _race conditions_.
- **CQRS Light:** Separação entre rotas de escrita rica e leitura otimizada.

### 3. Observabilidade (A Caixa de Vidro)

- **Logs Estruturados:** Saída 100% em JSON capturada pelo Promtail e enviada ao Loki.
- **Correlation ID:** UUID por requisição, integrando _Logs_ e _Traces_ (Grafana Tempo).
- **Métricas:** Monitoramento de latência P99 e falhas de autenticação via Prometheus.

---

## 📁 Estrutura do Projeto (DDD)

```text
src/main/java/com/hermes/backend/
├── core/                               # 📦 MÓDULOS DE NEGÓCIO
│   ├── shared/                         # Núcleo compartilhado (BaseEntity, Globals, Exceções)
│   ├── user/                           # Gestão de Identidade, Perfis e Setores
│   └── file/                           # Gestão de Documentos, Versões e Cofre
│
├── security/                           # 🛡️ BLINDAGEM E AUTENTICAÇÃO
│   ├── auth/                           # Fluxos de Login, Cadastro e Recuperação de Senha
│   ├── jwt/                            # Serviços e Filtros de Token (HS256)
│   ├── ratelimit/                      # Defesa contra Brute-Force (Bucket4j)
│   ├── blacklist/                      # Gestão de Revogação de Tokens (Redis)
│   └── audit/                          # Publicador de Eventos de Segurança (RabbitMQ)
│
├── observability/                      # 🔭 RASTREABILIDADE
│   ├── logging/                        # Filtros MDC (TraceId, CorrelationId)
│   └── exception/                      # GlobalExceptionHandler (Padronização HTTP 400/401/404/500)
│
└── infrastructure/                     # ⚙️ INTEGRAÇÕES TÉCNICAS
    ├── amqp/                           # Configuração de Filas (RabbitMQ)
    ├── cache/                          # Configuração de Cache e Locks (Redis)
    ├── storage/                        # Integração S3 (MinIO)
    └── mail/                           # Provedor de Email Local (Mailpit)
```

---

## ✅ Pré-requisitos

- **Java 21**
- **Gradle 8+** (ou usar o wrapper `./gradlew`)
- **Docker Desktop** + **Docker Compose**
- **Git**

---

## ⚙️ Configuração de Ambiente

1. Clone o repositório:

   ```bash
   git clone <url-do-repo>
   cd hermes
   ```

2. Crie/ajuste o arquivo `.env` na raiz (já existe exemplo no projeto).

3. Garanta que as portas abaixo estejam livres:
   - API: `8080`
   - PostgreSQL: `5432`
   - Redis: `6379`
   - RabbitMQ: `5672` e `15672`
   - MinIO: `9000` e `9001`
   - Mailpit: `1025` e `8025`
   - Prometheus: `9090`
   - Grafana: `3000`
   - Loki: `3100`
   - Tempo: `3200` e `4317`

---

## 🐳 Subindo a infraestrutura com Docker Compose

No Windows (PowerShell), na raiz do projeto:

```powershell
docker compose up -d
```

Verificar status:

```powershell
docker compose ps
```

Parar tudo:

```powershell
docker compose down
```

Parar e remover volumes (reset completo de dados locais):

```powershell
docker compose down -v
```

---

## ▶️ Executando a API

### Opção A: Local (sem container da API)

```powershell
.\gradlew bootRun
```

### Opção B: API em container (Dockerfile)

Build da imagem:

```powershell
docker build -t hermes-api -f dockerfile .
```

Run do container:

```powershell
docker run --name hermes-api -p 8080:8080 --env-file .env hermes-api
```

---

## 🧪 Testes

Executar testes automatizados:

```powershell
.\gradlew test
```

Gerar artefato JAR:

```powershell
.\gradlew bootJar
```

---

## 🔎 Endpoints e UIs úteis (ambiente local)

- **API Hermes:** `http://localhost:8080`
- **RabbitMQ Management:** `http://localhost:15672`
- **MinIO Console:** `http://localhost:9001`
- **Mailpit UI:** `http://localhost:8025`
- **Prometheus:** `http://localhost:9090`
- **Grafana:** `http://localhost:3000`

Credenciais padrão locais estão no `.env` e no `docker-compose.yml`.

---

## 📈 Observabilidade (visão rápida)

- **Métricas:** Spring Actuator + Micrometer → Prometheus
- **Logs:** JSON estruturado → Promtail → Loki
- **Traces:** OpenTelemetry (OTLP) → Tempo
- **Visualização unificada:** Grafana

Recomendação: criar dashboards de:

- Latência por endpoint (P50, P95, P99)
- Taxa de erros 4xx/5xx
- Falhas de autenticação
- Tempo de processamento de filas (RabbitMQ)

---

## 🔐 Boas práticas de segurança (importante)

- Nunca commitar segredo real em `.env`.
- Trocar `JWT_SECRET` em qualquer ambiente fora do local.
- Não usar credenciais padrão em homologação/produção.
- Manter imagens Docker atualizadas.
- Executar API com usuário não-root (já aplicado no Dockerfile).

---

## 🧭 Roadmap (sugestão de evolução)

- [ ] Pipeline CI/CD com testes + SAST + build de imagem
- [ ] Swagger/OpenAPI com documentação de contratos
- [ ] Health checks avançados (DB, Redis, RabbitMQ, MinIO)
- [ ] Estratégia de backup e retenção de auditoria
- [ ] Testes de carga (k6/Gatling) com metas de P99

---

## 🤝 Contribuição

1. Crie uma branch de feature: `feat/nome-da-feature`
2. Faça commits pequenos e descritivos
3. Rode testes locais antes do push
4. Abra PR com contexto técnico e evidências (logs/testes)

---

## 📄 Licença

Defina a licença do projeto (ex.: MIT, Apache-2.0 ou licença proprietária interna) e registre aqui.

---

## 👨‍💻 Autor

Projeto desenvolvido por **Matheus**.
