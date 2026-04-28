# base-chart

Универсальный Helm chart для типовых приложений в Kubernetes. Чарт умеет деплоить:

- `Deployment`
- `StatefulSet`
- `Job`
- несколько приложений через `apps[]`

## Быстрый старт

Проверка чарта:

```bash
helm lint .
helm template my-app .
```

Установка:

```bash
helm upgrade --install my-app . -n my-namespace --create-namespace -f values.yaml
```

## Основные режимы

### 1. Обычный Deployment

Пример `values-prod.yaml`:

```yaml
image:
  repository: nginx
  tag: "1.27.0"
  pullPolicy: IfNotPresent

replicaCount: 2

serviceAccount: app-sa
automountServiceAccountToken: false

service:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 8080

env:
  - name: APP_ENV
    value: production

secrets:
  DB_PASSWORD: supersecret

resources:
  cpu: 200m
  memory: 256Mi

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

Деплой:

```bash
helm upgrade --install my-app . -n my-namespace --create-namespace -f values-prod.yaml
```

### 2. Deployment с ConfigMap и PVC

```yaml
image:
  repository: nginx
  tag: "1.27.0"

service:
  ports:
    - name: http
      port: 80
      targetPort: 8080

configmap:
  - name: app-config
    podMountPath: /etc/app/config.yaml
    subPath: config.yaml
    readOnly: true
    data:
      config.yaml: |
        logLevel: info
        featureFlag: true

persistence:
  claims:
    - name: data
      accessModes:
        - ReadWriteOnce
      size: 5Gi
      storageClass: standard
      podMountPath: /var/lib/app
```

### 3. Ingress

```yaml
image:
  repository: nginx
  tag: "1.27.0"

service:
  ports:
    - name: http
      port: 80
      targetPort: 8080

ingress:
  ingressClassName: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
          port: 80
  tls:
    - hosts:
        - app.example.com
      secretName: app-example-com-tls
```

### 4. StatefulSet

```yaml
global:
  deploymentType: StatefulSet

image:
  repository: postgres
  tag: "16"
  pullPolicy: IfNotPresent

serviceAccount: postgres-sa

service:
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432

env:
  - name: POSTGRES_DB
    value: app

secrets:
  POSTGRES_PASSWORD: supersecret

persistence:
  claims:
    - name: data
      accessModes:
        - ReadWriteOnce
      size: 10Gi
      storageClass: standard
      podMountPath: /var/lib/postgresql/data
```

Деплой:

```bash
helm upgrade --install postgres . -n data --create-namespace -f values-statefulset.yaml
```

### 5. Job

```yaml
job:
  image:
    repository: curlimages/curl
    tag: "8.7.1"
    pullPolicy: IfNotPresent
  command:
    - /bin/sh
    - -c
    - echo "run migration"
  backoffLimit: 1
  activeDeadlineSeconds: 300
  restartPolicy: Never
  env:
    - name: APP_ENV
      value: production
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

Запуск:

```bash
helm upgrade --install migrate-job . -n my-namespace --create-namespace -f values-job.yaml
```

### 6. Multi-app

Если нужно поднять несколько приложений одним релизом:

```yaml
apps:
  - name: api
    replicaCount: 2
    image:
      repository: nginx
      tag: "1.27.0"
    serviceAccount: api-sa
    service:
      type: ClusterIP
      ports:
        - name: http
          port: 80
          targetPort: 8080
    env:
      - name: APP_NAME
        value: api

  - name: worker
    image:
      repository: busybox
      tag: "1.36"
    command:
      - /bin/sh
      - -c
    args:
      - sleep 3600
```

Запуск:

```bash
helm upgrade --install platform . -n my-namespace --create-namespace -f values-multi.yaml
```

## Поля values.yaml

### Общие

- `global.fullnameOverride` и `global.nameOverride` управляют именованием ресурсов.
- `global.deploymentType` переключает режим между `Deployment` и `StatefulSet`.
- `global.image` можно использовать как общий образ по умолчанию.
- `customLabels` и `customAnnotations` добавляют пользовательские metadata.

### Pod и контейнер

- `image`, `command`, `args`
- `serviceAccount`, `automountServiceAccountToken`
- `nodeSelector`, `affinity`, `tolerations`
- `securityContext.pod`, `securityContext.container`
- `env`, `secrets`
- `resources`
- `livenessProbe`, `readinessProbe`

### Сеть и хранение

- `service`
- `ingress`
- `networkPolicy`
- `configmap`
- `persistence.claims`
- `extraVolumes`
- `extraVolumeMounts`

## Практика использования

- Для обычных stateless-приложений используй режим `Deployment`.
- Для баз данных и приложений с постоянным диском включай `global.deploymentType: StatefulSet`.
- Для миграций и разовых задач используй секцию `job`.
- Если PVC уже существует в namespace, чарт пропустит его повторное создание. Это помогает при повторных установках, но Helm не начнёт управлять уже существующим PVC как своим ресурсом.
- Для production лучше хранить чувствительные значения в отдельном values-файле или передавать через `--set`.

## Полезные команды

Рендер в stdout:

```bash
helm template my-app . -f values-prod.yaml
```

Установка в новый namespace:

```bash
helm upgrade --install my-app . \
  -n my-namespace \
  --create-namespace \
  -f values-prod.yaml
```

Удаление релиза:

```bash
helm uninstall my-app -n my-namespace
```
