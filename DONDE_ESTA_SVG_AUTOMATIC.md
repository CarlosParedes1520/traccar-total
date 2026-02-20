# 📍 Dónde Está el SVG de "AUTOMATIC"

## 🔍 Ubicación

El SVG de "AUTOMATIC" **NO está en un archivo SVG separado**. Está **embebido en el código JavaScript compilado** del frontend.

### Ubicación Física:

```
traccar-web/assets/index-DDho2u9q.js
```

**Línea aproximada:** ~881 (dentro del archivo JavaScript compilado)

---

## 📝 Cómo Está Implementado

El SVG está definido como un **componente React** dentro del JavaScript compilado:

```javascript
const I8d = e => N.createElement("svg", {
  id: "Layer_1",
  "data-name": "Layer 1",
  xmlns: "http://www.w3.org/2000/svg",
  xmlnsXlink: "http://www.w3.org/1999/xlink",
  viewBox: "0 0 1080 1080",
  ...e
}, 
  N.createElement("defs", null, 
    N.createElement("style", null, `
      .cls-1 { fill: none; }
      .cls-2 { fill: #f0efeb; }
    `),
    N.createElement("clipPath", {id: "clippath"}, ...)
  ),
  N.createElement("path", {className: "cls-2", d: "M111.62,682.57..."}), // Letra "A"
  N.createElement("path", {className: "cls-2", d: "M395.26,467.75..."}), // Letra "U"
  // ... más paths para "T", "O", "M", "A", "T", "I", "C"
)
```

---

## 🎯 ¿Dónde Está el Código Fuente Original?

El código fuente original del frontend **NO está incluido** en este repositorio. Este proyecto solo contiene:

- ✅ **Backend Java** (`src/main/java/`)
- ✅ **Frontend compilado** (`traccar-web/`)

El frontend se compila desde un repositorio separado (probablemente `traccar-web` o similar) y luego se copia aquí.

---

## 🔧 Cómo Modificar el SVG

### Opción 1: Extraer y Modificar el SVG del JavaScript

1. **Extraer el SVG del JavaScript compilado:**
   ```bash
   # Buscar el SVG en el archivo
   grep -A 50 "I8d=e=>N.createElement" traccar-web/assets/index-DDho2u9q.js
   ```

2. **Crear un archivo SVG separado:**
   ```bash
   # Crear automatic-logo.svg con el contenido extraído
   ```

3. **Modificar el código fuente del frontend** (si tienes acceso) para usar el SVG como archivo en lugar de embebido.

### Opción 2: Reemplazar en el JavaScript Compilado (No recomendado)

⚠️ **No recomendado** porque:
- Se perderá al recompilar
- Es difícil de mantener
- Puede romper el código

### Opción 3: Buscar el Repositorio del Frontend

El código fuente original probablemente está en:
- Repositorio separado de `traccar-web`
- Archivo TypeScript/JSX con el componente del logo

---

## 📋 Contenido del SVG

El SVG contiene:
- **Texto:** "AUTOMATIC" (8 letras)
- **ViewBox:** `0 0 1080 1080`
- **Clases CSS:**
  - `.cls-1`: `fill: none`
  - `.cls-2`: `fill: #f0efeb`
- **Paths:** Cada letra está definida como un `<path>` con coordenadas SVG

---

## 💡 Recomendación

Si necesitas modificar este logo:

1. **Busca el repositorio del frontend** (probablemente `traccar-web` en GitHub)
2. **Encuentra el componente** que genera este SVG
3. **Modifica el código fuente** y recompila
4. **O reemplaza** el SVG completo con uno personalizado

---

## 🔗 Referencias

- **Archivo compilado:** `traccar-web/assets/index-DDho2u9q.js`
- **Función:** `I8d` (nombre minificado)
- **Búsqueda:** `grep "Layer_1\|M111.62,682.57" traccar-web/assets/*.js`

