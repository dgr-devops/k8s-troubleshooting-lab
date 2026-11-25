# 11 · Secret con clave equivocada

> Namespace del escenario: `lab-11` · Directorio: `scenarios/11-secret-clave-erronea/`

## Practicar

```bash
scripts/lab.sh break 11    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 11    # ¿ya está resuelto?
scripts/lab.sh fix 11      # aplica la solución de referencia
scripts/lab.sh clean 11    # borra el namespace
```

## Síntomas

Igual que el escenario anterior: `CreateContainerConfigError`, pero el Secret SÍ existe.

## Diagnóstico

El evento es sutil: dice que no encuentra una *clave* dentro de un Secret que existe. No muestres el valor del Secret en terminales compartidas: lista solo las claves.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-11 get pods
NAME                   READY   STATUS                       RESTARTS   AGE
app-567fddf7c7-6r98g   0/1     CreateContainerConfigError   0          30s

$ kubectl -n lab-11 describe pod -l app=app | sed -n '/Events:/,$p'
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  30s               default-scheduler  Successfully assigned lab-11/app-567fddf7c7-6r98g to troubleshooting-lab-worker
  Normal   Pulled     6s (x4 over 30s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Warning  Failed     6s (x4 over 30s)  kubelet            spec.containers{app}: Error: couldn't find key password in Secret lab-11/db-credentials

$ kubectl -n lab-11 get secret db-credentials -o jsonpath='{.data}' | sed 's/:"[^"]*"/:"<oculto>"/'
{"db-password":"<oculto>"}
```

## Causa raíz

El Deployment pide la clave `password` del Secret `db-credentials`, pero el Secret define `db-password`.

## Solución

Corregir `secretKeyRef.key` a `db-password` (`solution.yaml`). El valor del Secret del laboratorio es de ejemplo.

## Prevención

- Una única fuente de verdad para nombres de claves (por ejemplo External Secrets o plantillas).
- `kubectl get secret X -o jsonpath='{.data}' | jq 'keys'` para comprobar solo las claves.
- Nunca subir Secrets reales a Git (usar SOPS / Sealed Secrets).
