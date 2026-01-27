# Estructura de Eventos - ReplicatedStorage

Esta guía detalla la estructura exacta de carpetas y eventos que debes crear manualmente en Roblox Studio dentro de `ReplicatedStorage`.

## 📂 Vista de Árbol

```text
ReplicatedStorage
└── Events
    ├── Remotes (Carpeta)
    │   ├── ReiniciarNivel       (RemoteEvent)
    │   ├── EjecutarAlgoritmo    (RemoteEvent)
    │   ├── ActualizarInventario (RemoteEvent)
    │   ├── ActualizarMision     (RemoteEvent)
    │   ├── AparecerObjeto       (RemoteEvent)
    │   └── VerificarInventario  (RemoteFunction) ⚠️ Única Función
    │
    └── Bindables (Carpeta)
        ├── ConexionCambiada     (BindableEvent)
        ├── DesbloquearObjeto    (BindableEvent)
        └── RestaurarObjetos     (BindableEvent)
```

## 📝 Detalle de Creación

Sigue estos pasos en el panel **Explorer** de Roblox Studio:

1.  **Grupo Principal**:
    *   Crea una **Folder** dentro de `ReplicatedStorage` llamada: `Events`

2.  **Subcarpetas**:
    *   Dentro de `Events`, crea una **Folder** llamada: `Remotes`
    *   Dentro de `Events`, crea una **Folder** llamada: `Bindables`

3.  **Eventos Remotos (Cliente <-> Servidor)**:
    *   *Ubicación:* `ReplicatedStorage/Events/Remotes`
    *   Crea un **RemoteEvent** llamado `ReiniciarNivel`
    *   Crea un **RemoteEvent** llamado `EjecutarAlgoritmo`
    *   Crea un **RemoteEvent** llamado `ActualizarInventario`
    *   Crea un **RemoteEvent** llamado `ActualizarMision`
    *   Crea un **RemoteEvent** llamado `AparecerObjeto`
    *   ⚠️ Crea una **RemoteFunction** llamada `VerificarInventario`

4.  **Eventos Locales (Servidor <-> Servidor)**:
    *   *Ubicación:* `ReplicatedStorage/Events/Bindables`
    *   Crea un **BindableEvent** llamado `ConexionCambiada`
    *   Crea un **BindableEvent** llamado `DesbloquearObjeto`
    *   Crea un **BindableEvent** llamado `RestaurarObjetos`
