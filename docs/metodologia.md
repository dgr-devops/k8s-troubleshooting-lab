# Metodología de troubleshooting en Kubernetes

Un método fijo evita dar vueltas a ciegas. Es el que sigo en todos los escenarios del laboratorio, y es el mismo orden en el que escribiría un runbook de guardia.

## 1. Delimita el problema (30 segundos)

Antes de tocar nada, responde por escrito:

- **¿Qué falla exactamente?** Una URL concreta, un pod, un job. No «la app va mal».
- **¿Desde cuándo y qué cambió?** Un despliegue, un cambio de configuración, un nodo nuevo. Casi siempre hay un cambio reciente.
- **¿A quién afecta?** A todos, a un solo namespace, a un solo nodo.

```bash
kubectl get events -A --sort-by=.lastTimestamp | tail -n 30
kubectl rollout history deploy/<nombre> -n <ns>
```

## 2. Sigue el camino de la petición, de fuera hacia dentro

Una petición recorre una cadena. El fallo está en el primer eslabón que no cumple:

```
Cliente -> Ingress -> Service -> Endpoints -> Pod -> Contenedor -> Aplicación
```

| Eslabón | Pregunta | Comando |
|---|---|---|
| Ingress | ¿El host/path llega al backend correcto? | `kubectl describe ingress` |
| Service | ¿El selector y el `targetPort` son correctos? | `kubectl describe svc` |
| Endpoints | ¿Hay direcciones Ready detrás del Service? | `kubectl get endpoints` |
| Pod | ¿Está `Running` y `Ready`? | `kubectl get pods -o wide` |
| Contenedor | ¿Arranca? ¿Por qué se reinicia? | `kubectl describe pod`, `kubectl logs --previous` |
| Aplicación | ¿Qué dice su log? | `kubectl logs` |

## 3. Lee el estado del pod: la columna STATUS ya orienta

| STATUS | Dónde mirar | Escenario |
|---|---|---|
| `Pending` | Scheduler: `describe pod` → Events (`FailedScheduling`) | 04, 05, 13 |
| `ImagePullBackOff` / `ErrImagePull` | Nombre, tag y credenciales de la imagen | 02 |
| `CreateContainerConfigError` | ConfigMap/Secret/clave que no existe | 10, 11 |
| `CrashLoopBackOff` | `logs --previous` y código de salida | 01 |
| `OOMKilled` (en `lastState`) | Límite de memoria frente al uso real | 03 |
| `Running` pero `0/1` Ready | Readiness probe | 06 |
| `Running` con reinicios | Liveness probe | 07 |
| `Running` y `1/1`, pero no responde | Service, NetworkPolicy, Ingress, RBAC | 08, 09, 12, 14, 15 |

## 4. Los cuatro comandos, siempre en este orden

```bash
kubectl get <recurso> -n <ns> -o wide          # 1. estado
kubectl describe <recurso> <nombre> -n <ns>    # 2. eventos y condiciones (leer la sección Events al final)
kubectl logs <pod> -n <ns> [--previous]        # 3. qué dice la aplicación
kubectl get events -n <ns> --sort-by=.lastTimestamp   # 4. línea de tiempo
```

Extras útiles: `kubectl top pod` (requiere metrics-server), `kubectl auth can-i`, `kubectl exec` y `kubectl debug` para probar desde dentro.

## 5. Formula una hipótesis, confírmala y cambia UNA cosa

- Escribe la hipótesis («el Service apunta a un label que no existe») y busca la evidencia que la confirme o la descarte **antes** de cambiar nada.
- Cambia una sola variable cada vez. Si cambias tres cosas y funciona, no sabes cuál lo arregló.
- Prefiere cambios declarativos (`kubectl apply -f`) a ediciones a mano, para que el arreglo quede en Git.

## 6. Verifica y cierra el ciclo

1. Comprueba el síntoma original desde el mismo punto de vista que lo vio el usuario (la URL, no solo el pod).
2. Confirma que no hay efectos colaterales: `kubectl get pods -A | grep -v Running`.
3. Deja constancia: causa raíz, arreglo y **prevención** (alerta, test, validación en CI, límite de recursos). Un buen postmortem tiene este formato; ver el repositorio [runbooks-and-postmortems](https://github.com/dgr-devops/runbooks-and-postmortems).

## Errores típicos al diagnosticar

- Mirar solo `get pods` y no `describe` (los eventos explican el 80 % de los casos).
- Olvidar `--previous` en un `CrashLoopBackOff`: el log actual suele estar vacío.
- Confundir `port`, `targetPort` y `containerPort`.
- Culpar a la red cuando el Service no tiene endpoints.
- Reiniciar el pod «a ver si se arregla»: se pierde la evidencia.
