# 02 · ImagePullBackOff: la imagen no se puede descargar

> Namespace del escenario: `lab-02` · Directorio: `scenarios/02-imagepullbackoff/`

## Practicar

```bash
scripts/lab.sh break 2    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 2    # ¿ya está resuelto?
scripts/lab.sh fix 2      # aplica la solución de referencia
scripts/lab.sh clean 2    # borra el namespace
```

## Síntomas

El pod se queda en `ErrImagePull` y luego `ImagePullBackOff`. Nunca llega a arrancar: no hay logs porque el contenedor no existe.

## Diagnóstico

Con `ImagePullBackOff` no hay logs que mirar: toda la información está en los eventos de `describe pod`.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-02 get pods
NAME                   READY   STATUS         RESTARTS   AGE
web-7b4bdb4ff9-rvdvf   0/1     ErrImagePull   0          45s

$ kubectl -n lab-02 describe pod -l app=web | sed -n '/Events:/,$p'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  45s                default-scheduler  Successfully assigned lab-02/web-7b4bdb4ff9-rvdvf to troubleshooting-lab-worker
  Normal   Pulling    28s (x2 over 45s)  kubelet            spec.containers{web}: Pulling image "nginx:1.27-alpne"
  Warning  Failed     27s (x2 over 44s)  kubelet            spec.containers{web}: Failed to pull image "nginx:1.27-alpne": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:1.27-alpne": failed to resolve reference "docker.io/library/nginx:1.27-alpne": docker.io/library/nginx:1.27-alpne: not found
  Warning  Failed     27s (x2 over 44s)  kubelet            spec.containers{web}: Error: ErrImagePull
  Normal   BackOff    13s (x2 over 43s)  kubelet            spec.containers{web}: Back-off pulling image "nginx:1.27-alpne"
  Warning  Failed     13s (x2 over 43s)  kubelet            spec.containers{web}: Error: ImagePullBackOff
```

## Causa raíz

El tag `1.27-alpne` tiene una errata (falta una `i`). El registro responde `not found` y kubelet reintenta con espera creciente.

## Solución

Corregir el tag de la imagen a `nginx:1.27-alpine` (`solution.yaml`). Si el error fuera de credenciales (`unauthorized`), el arreglo sería un `imagePullSecret`.

## Prevención

- Fijar versiones exactas (o digest `@sha256:`) y no usar `latest`.
- Validar que la imagen existe en CI antes de desplegar (`docker manifest inspect`).
- Usar un registro propio o una caché para no depender de límites de Docker Hub.
