# GitOps con Argo CD · ejemplo práctico

Exposición del Tema 6 (GitOps), Grupo J: Cristal Ariza, David Payares y José Rodríguez.

Una página de estado de MedicOps corre en un Kubernetes local. **Nadie la despliega a mano**: Argo CD vigila la carpeta
`app/` de este repositorio y hace que el clúster quede igual a lo que dice Git.

```
 Desarrollador ──commit──▶ GitHub (app/*.yaml) ◀──revisa cada 15 s── Argo CD ──aplica──▶ Kubernetes (kind) ──▶ http://localhost:8080
```

## Qué hay aquí

| Ruta | Qué es |
|---|---|
| `app/deployment.yaml` | La aplicación: versión, color, mensaje y número de réplicas. **Es el único archivo que se edita en la demo** |
| `app/service.yaml` | Publica la página en `http://localhost:8080` |
| `argocd/aplicacion.yaml` | Le dice a Argo CD qué repo vigilar, qué carpeta y en qué clúster aplicarla, con sincronización automática y autocorrección |
| `demo/` | Scripts para preparar, abrir, sabotear y apagar la demo |

## Requisitos

Docker Desktop encendido, `kubectl` y [`kind`](https://kind.sigs.k8s.io/).

## Preparar (una vez, unos 3 minutos, antes de exponer)

```powershell
.\demo\1-preparar.ps1   # crea el clúster, instala Argo CD y registra la aplicación
.\demo\2-abrir.ps1      # abre la página, Argo CD y el YAML en GitHub; copia la clave de admin al portapapeles
```

## Guion de la demo

**Acto 1 · Un cambio en Git es un despliegue.** En GitHub, editar `app/deployment.yaml`: `VERSION` a `"2.0"`, `COLOR` a
`"#7c3aed"`, `MENSAJE` a `"Nueva versión desplegada desde Git"` y `replicas` a `4`. Commit. En unos 15 segundos Argo CD
marca *OutOfSync*, sincroniza y la página cambia de color sola; en Argo CD se ven los 4 pods.

**Acto 2 · Alguien toca producción a mano.** `.\demo\3-sabotear.ps1` borra el deployment directamente en el clúster.
Argo CD detecta que el clúster ya no coincide con Git y lo vuelve a crear en segundos.

**Acto 3 · Rollback con Git.** La versión 2 “salió mal”:

```powershell
git pull
git revert --no-edit HEAD
git push
```

En unos 15 segundos la página vuelve a la versión 1. El historial de Git queda como bitácora de quién cambió qué y cuándo.

¿Afán en vivo? El botón **Refresh** de Argo CD revisa Git en el momento.

## Apagar

```powershell
.\demo\4-apagar.ps1
```
