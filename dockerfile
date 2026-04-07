# ==========================================
# STAGE 1: Build (Ambiente de Compilação)
# ==========================================
# Usamos a imagem completa do JDK 21 apenas para compilar o código
FROM eclipse-temurin:21-jdk-alpine AS builder

# Update and patch security vulnerabilities
RUN apk update && apk upgrade && apk add --no-cache ca-certificates

# Define o diretório de trabalho dentro do container
WORKDIR /app

# 1. Copia primeiro os arquivos de configuração do Gradle
# Isso é um truque de cache do Docker: se o build.gradle não mudar, 
# ele não baixa as dependências tudo de novo a cada build.
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Dá permissão de execução ao wrapper do Gradle
RUN chmod +x ./gradlew

# 2. Baixa as dependências do projeto (gera cache)
RUN ./gradlew dependencies --no-daemon

# 3. Agora copia o código-fonte da aplicação
COPY src src

# 4. Gera o .jar executável. 
# O -x test pula os testes na criação da imagem (eles devem rodar na esteira de CI/CD, não no build do Docker)
RUN ./gradlew bootJar -x test --no-daemon

# ==========================================
# STAGE 2: Runtime (Ambiente de Execução)
# ==========================================
# Usamos apenas o JRE (Java Runtime Environment), que é muito mais leve e seguro
FROM eclipse-temurin:21-jre-alpine

# Update and patch security vulnerabilities
RUN apk update && apk upgrade && apk add --no-cache ca-certificates

# Define o diretório de trabalho
WORKDIR /app

# [Segurança] Cria um usuário não-root. 
# Rodar containers como root é uma falha crítica. Se houver vulnerabilidade no app, 
# o atacante fica restrito aos privilégios deste usuário.
RUN addgroup -S hermesgroup && adduser -S hermesuser -G hermesgroup
USER hermesuser

# Copia APENAS o arquivo .jar gerado no Stage 1 (builder) para o Stage 2
# O Spring Boot gera o arquivo em build/libs/
COPY --from=builder /app/build/libs/*SNAPSHOT.jar app.jar

# Expõe a porta que o Spring Boot vai rodar
EXPOSE 8080

# Configurações otimizadas para a JVM em containers:
# - UseContainerSupport: Ajuda o Java a respeitar os limites de memória do Docker
# - MaxRAMPercentage: Evita que a JVM use 100% da RAM e o container seja morto por OOM (Out Of Memory)
# - timezone: Configurado para o horário de Brasília, garantindo que logs e agendamentos façam sentido
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Duser.timezone=America/Sao_Paulo"

# Comando final que inicializa a aplicação
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]