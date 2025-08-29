# Jedi Helm Chart

> A Helm chart to manage multiple microservices with unified defaults and flexible overrides

## Overview

This chart provides a single deployment mechanism for multiple services while maintaining flexibility through service-specific configurations. It automatically generates Kubernetes resources (Deployments, Services, Ingress, HPA, CronJobs, ConfigMaps) based on service definitions.

## Architecture

### Global Defaults
- All services inherit from `global.*` settings
- Service-specific values override global defaults
- No mutation between service iterations (uses `deepCopy`)

### Service Structure
Each service under `services:` generates:
- **Deployment**: Container with merged env vars (service + shared group)
- **Service**: Network endpoint with configurable ports
- **Ingress**: Optional HTTP routing (when `ingress.enabled: true`)
- **HPA**: Optional autoscaling (when `autoscaling.enabled: true`)
- **CronJob**: Optional scheduled tasks (when `cronjobs.enabled: true`)
- **ConfigMap**: Optional file mounting (when `configmap.enabled: true`)

## Configuration

### Service Keys
- **Pattern**: `^[a-z]{1,12}$` (lowercase letters only, max 12 chars)
- **Examples**: `ui`, `apigateway`, `auth`, `blogs`

### Image Resolution
The `imageRef` helper resolves images with this precedence:
1. `service.image.repository` (full "repo/name")
2. `global.image.repository`
3. `(service.image.repo | global.image.repo | global.repoName) + "/" + (service.image.name | global.image.name | serviceName)`
4. Tag: `service.image.tag` → `global.image.tag` → `Chart.AppVersion`

### Environment Variables
- **Per-service**: `service.env[]` array
- **Shared by group**: `environmentVariables.<group>[]` array
- **Naming**: Must match `^[A-Z_][A-Z0-9_]*$`

### Port Configuration
- **Container ports**: `service.ports[]` array
- **Service ports**: `service.service.ports.*` (port, targetPort, protocol)
- **Validation**: Ports 1-65535, protocols: TCP/UDP/SCTP

### Ingress
When `ingress.enabled: true`:
- **Required**: `host`, `path`
- **Optional**: `annotations`
- **Backend**: Automatically uses service port

### Autoscaling
When `autoscaling.enabled: true`:
- **Required**: `minReplicas`, `maxReplicas`
- **Targets**: CPU and memory utilization (1-100%)

### CronJobs
When `cronjobs.enabled: true`:
- **Required**: `jobs[]` array with `name`, `schedule`, `command`
- **Schedule**: Standard cron format
- **Naming**: DNS-1123 labels, max 30 chars

### ConfigMaps
When `configmap.enabled: true`:
- **Required**: `filename`, `mountPath`, `data`
- **Mounting**: Single file via subPath

## Validation Rules

The chart includes comprehensive JSON Schema validation:

### Service Naming
- Lowercase letters only: `^[a-z]{1,12}$`
- Maximum length: 12 characters

### Ports & Protocols
- Container ports: 1-65535
- Service ports: 1-65535
- Protocols: TCP, UDP, SCTP

### Resource Limits
- CPU: `^[0-9]+m?$` (millicores or cores)
- Memory: `^[0-9]+(Ei|Pi|Ti|Gi|Mi|Ki)?$` (bytes with units)

### Cron Schedules
- Standard cron format validation
- Predefined schedules: `@annually`, `@yearly`, `@monthly`, `@weekly`, `@daily`, `@hourly`, `@reboot`

### Hostnames & Paths
- Hostnames: DNS-1123 compliant
- Paths: Must start with `/`

## Usage Examples

### Basic Service
```yaml
services:
  myservice:
    group: backend
    image:
      name: myapp
      tag: v1.0.0
    service:
      ports:
        port: 8080
        targetPort: 80
```

### Service with Ingress
```yaml
services:
  webapp:
    group: frontend
    ingress:
      enabled: true
      host: "app.example.com"
      path: "/"
```

### Service with CronJob
```yaml
services:
  worker:
    group: backend
    cronjobs:
      enabled: true
      jobs:
        - name: cleanup
          schedule: "0 2 * * *"
          command: ["python", "cleanup.py"]
```

## Development

### Adding New Resource Types
1. Create template file in `templates/`
2. Add validation rules to `values.schema.json`
3. Update this README

### Testing
```bash
# Validate schema
helm lint .

# Render templates
helm template app . --kube-version 1.31.0

# Dry-run install
helm install app . --dry-run --debug
```

## Dependencies

- Kubernetes: `>=1.31.0`
- Helm: `>=3.11.0` (for `deepCopy` function)

## Contributing

1. Follow the naming conventions above
2. Add validation rules for new fields
3. Include helpful comments in templates
4. Test with `helm lint` and `helm template`

## License

[Add your license here]
