# k8s-troubleshooting-lab

Laboratorio para **practicar el diagnóstico de fallos en Kubernetes**: 15 escenarios rotos a propósito
(CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending, sondas, Services, ConfigMap/Secret,
NetworkPolicy, PVC, RBAC e Ingress). Cada uno trae el síntoma, el diagnóstico con salida **real**
de `kubectl`, la causa raíz, la solución y cómo prevenirlo.

> **Nota honesta:** todo corre en **kind** (Kubernetes dentro de Docker, en local). No hay cloud ni
> coste. Es un laboratorio de aprendizaje, no un sistema en producción. La salida de cada README es
> la capturada al ejecutar el escenario en mi cluster.

## Cómo funciona

Cada escenario vive en `scenarios/NN-nombre/` con su propio namespace (`lab-NN`):

| Fichero | Para qué |
|---------|----------|
| `broken.yaml` | Lo que se aplica para romper algo |
| `solution.yaml` | La solución de referencia |
| `check.sh` | Comprueba el síntoma (`broken`) o la recuperación (`fixed`) |
| `README.md` | Síntomas, diagnóstico, causa raíz, solución y prevención |

`scripts/verify-all.sh` recorre los 15 escenarios: aplica el fallo, **comprueba que el síntoma se
observa de verdad**, aplica la solución y **comprueba que se recupera**. Es lo mismo que ejecuta el CI.

## Requisitos

`docker`, [`kind`](https://kind.sigs.k8s.io/) y `kubectl`.

## Uso

```bash
scripts/lab.sh up          # crea el cluster kind e instala ingress-nginx
scripts/lab.sh list        # lista los escenarios

scripts/lab.sh break 1     # rompe el escenario 1
kubectl -n lab-01 get pods # diagnostica sin mirar solution.yaml
scripts/lab.sh check 1     # ¿ya está resuelto?
scripts/lab.sh fix 1       # aplica la solución de referencia
scripts/lab.sh clean 1     # borra el namespace

scripts/verify-all.sh      # verifica los 15 de punta a punta
scripts/lab.sh down        # elimina el cluster
```

## Escenarios

| # | Escenario | Qué se aprende |
|---|-----------|----------------|
| 01 | [CrashLoopBackOff](scenarios/01-crashloopbackoff/) | Logs y código de salida de un contenedor que muere |
| 02 | [ImagePullBackOff](scenarios/02-imagepullbackoff/) | Imagen o tag inexistente |
| 03 | [OOMKilled](scenarios/03-oomkilled/) | Límites de memoria |
| 04 | [Pending por recursos](scenarios/04-pending-recursos/) | Requests que no caben en ningún nodo |
| 05 | [Pending por nodeSelector](scenarios/05-pending-nodeselector/) | Scheduling con etiquetas |
| 06 | [Readiness probe](scenarios/06-readiness-probe/) | Running pero 0/1 y sin tráfico |
| 07 | [Liveness probe](scenarios/07-liveness-probe/) | Reinicios en bucle |
| 08 | [Service sin endpoints](scenarios/08-service-selector/) | Selector que no coincide |
| 09 | [targetPort equivocado](scenarios/09-service-targetport/) | Service que no llega al puerto real |
| 10 | [ConfigMap inexistente](scenarios/10-configmap-inexistente/) | `CreateContainerConfigError` |
| 11 | [Secret con clave errónea](scenarios/11-secret-clave-erronea/) | Referencias a claves de Secret |
| 12 | [NetworkPolicy y DNS](scenarios/12-networkpolicy-dns/) | Tráfico bloqueado, incluido el DNS |
| 13 | [PVC Pending](scenarios/13-pvc-pending/) | StorageClass inexistente |
| 14 | [RBAC forbidden](scenarios/14-rbac-forbidden/) | Permisos de una ServiceAccount |
| 15 | [Ingress sin backend](scenarios/15-ingress-backend/) | Ingress que apunta a un Service que no existe |

El método general (delimitar, seguir la petición de fuera hacia dentro, leer eventos y logs) está en
[`docs/metodologia.md`](docs/metodologia.md).

## CI

`.github/workflows/ci.yml` ejecuta yamllint, kubeconform y shellcheck, y después levanta un cluster
kind en GitHub Actions y corre `scripts/verify-all.sh` con los 15 escenarios.

## Licencia

MIT, ver [`LICENSE`](LICENSE).
