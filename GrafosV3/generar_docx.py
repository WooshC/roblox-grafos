from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

def set_cell_shading(cell, color):
    shading = OxmlElement('w:shd')
    shading.set(qn('w:fill'), color)
    cell._tc.get_or_add_tcPr().append(shading)

def add_heading_custom(doc, text, level=1):
    p = doc.add_heading(text, level=level)
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    for run in p.runs:
        run.font.color.rgb = RGBColor(0, 0, 0)
        run.font.name = 'Times New Roman'
    return p

def add_paragraph_custom(doc, text, bold=False, italic=False, first_line_indent=Cm(1.25)):
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = first_line_indent
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    p.paragraph_format.space_after = Pt(6)
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(12)
    run.bold = bold
    run.italic = italic
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    return p

def add_table_from_data(doc, headers, rows, col_widths=None):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = 'Table Grid'
    table.autofit = False
    table.allow_autofit = False
    
    hdr_cells = table.rows[0].cells
    for i, header in enumerate(headers):
        hdr_cells[i].text = header
        set_cell_shading(hdr_cells[i], 'D9E2F3')
        for paragraph in hdr_cells[i].paragraphs:
            for run in paragraph.runs:
                run.font.bold = True
                run.font.name = 'Times New Roman'
                run.font.size = Pt(11)
            paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if col_widths and i < len(col_widths):
            hdr_cells[i].width = col_widths[i]
    
    for row_data in rows:
        row_cells = table.add_row().cells
        for i, val in enumerate(row_data):
            row_cells[i].text = str(val)
            for paragraph in row_cells[i].paragraphs:
                for run in paragraph.runs:
                    run.font.name = 'Times New Roman'
                    run.font.size = Pt(11)
                paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT if i > 0 else WD_ALIGN_PARAGRAPH.CENTER
            if col_widths and i < len(col_widths):
                row_cells[i].width = col_widths[i]
    
    doc.add_paragraph()
    return table

doc = Document()
section = doc.sections[0]
section.page_height = Cm(27.94)
section.page_width = Cm(21.59)
section.top_margin = Cm(2.54)
section.bottom_margin = Cm(2.54)
section.left_margin = Cm(3.17)
section.right_margin = Cm(2.54)

# Título principal
add_heading_custom(doc, 'Capítulo 2', level=1)
add_heading_custom(doc, 'Metodología y Desarrollo', level=1)
add_paragraph_custom(doc, 'Para el desarrollo del juego serio orientado a la enseñanza de algoritmos de teoría de grafos, se ha definido una estructura metodológica dividida en dos etapas complementarias que aseguran tanto el rigor pedagógico como la eficiencia en la construcción del software.')

# Release Planning
add_heading_custom(doc, '2.6.1.1.1.\tPlanificación de la release', level=2)
add_paragraph_custom(doc, 'La Tabla 2.12 Release Planning muestra cómo las Historias de Usuario y Mecánicas de Juego se agrupan lógicamente en Sprints para construir el juego paso a paso.')

add_table_from_data(doc, 
    ['Sprint 1: Cimientos y Entorno Base', 'Sprint 2: Lógica Matemática y Conectividad Física', 'Sprint 3: Misiones, Análisis y Progresión', 'Sprint 4: Pulido Audiovisual y Experiencia'],
    [
        ['CL 001: Representación gráfica base', 'TG 01: Crear conexiones físicas', 'CL 004: Lógica de resolución algorítmica', 'CL 005: Sistema de feedback audiovisual dinámico'],
        ['CL 002: Navegación y exploración en el mapa', 'TG 03: Eliminar conexiones erróneas', 'CL 008: Almacenamiento local de progreso del jugador', 'TG 08: Etiquetas flotantes informativas'],
        ['TG 02: Movimiento y desplazamiento 3D libre', 'TG 05: Validación de dirección para el grafo', 'TG 06: Módulo de mapa aéreo e inspector visual', 'CL 010: Cierre cinemático del nivel'],
        ['CL 009: Ciclo de vida estricto (Menú y Estado)', 'TG 04: Gestión de pesos y presupuesto ("Dinero")', 'CL 011: Retroalimentación por validación (BFS/DFS)', 'TG 09: Efectos animados (Pulsos) de Cables'],
        ['—', 'CL 007: Interfaz base In-Game y HUD', '—', '—']
    ]
)

add_heading_custom(doc, 'Ejecución de los Sprints en Scrum', level=2)

# Sprint 1
add_heading_custom(doc, 'Sprint 1', level=3)
add_paragraph_custom(doc, 'Objetivo del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Desarrollar la máquina de estados principal, construir visualmente el entorno urbano en tres dimensiones de "Villa Conexa", y sentar las bases normativas para la instanciación determinista del mapa previo a la ejecución de algoritmos.')

add_paragraph_custom(doc, 'Planificación del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Para lograr el objetivo del Sprint 1, se instrumentó el módulo "Controlador de Boot", las funciones estrictas de cámara y colisión (transparencia de techos en vista cenital) y se construyeron los modelos geométricos base (Servidores y Postes) que formarán los vértices del grafo. Esta fase constituyó el cimiento interactivo del juego y duró 40 horas.')

add_paragraph_custom(doc, 'Tabla 2.13 Sprint Backlog - Sprint 1', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO / MECÁNICA', 'ESTIMACIÓN (HORAS)'],
    [
        ['CL 001', 'Representar gráficamente a los nodos (postes) y las aristas visuales estáticas dentro del escenario.', '16'],
        ['CL 002', 'Proporcionar navegación segura y exploración estructurando la urbe de "Villa Conexa" en sectores distinguibles.', '8'],
        ['TG 02', 'Facilitar el movimiento ininterrumpido en el plano 3D para la cámara libre.', '8'],
        ['CL 009', 'Generar gestores de ciclo de vida (00_EventRegistry, Boot.server) que ordenen estrictamente la pasarela entre las secciones de menú y el tiempo de Gameplay activo.', '8'],
        ['Task', 'Integrar y ubicar modelos estructurales físicos a los que el jugador pueda recurrir para anclar sus pensamientos teóricos.', '16'],
        ['TOTAL', '', '56']
    ]
)

add_paragraph_custom(doc, 'Tabla 2.14 Revisión de criterios de aceptación - Sprint 1', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO', 'CRITERIOS DE ACEPTACIÓN', 'CUMPLIMIENTO'],
    [
        ['CL 001', 'Representación gráfica y estructural del modelo matemático', '1. Existencia tangible de entidades (postes) en 3D. 2. Visibilidad y detectabilidad a lo largo del plano geográfico.', 'Sí / Sí'],
        ['CL 002', 'Geografía controlada y exploración acotada', '1. Estructura limitante que evite desplazamientos anómalos o irrelevantes. 2. Las áreas del distrito se diferencian claramente según las reglas del nivel.', 'Sí / Sí'],
        ['TG 02', 'Controles del avatar y ocultamiento de geometría', '1. Permite desplazarse a vista de pájaro para tener el contexto global del nivel. 2. Las paredes se vuelven momentáneamente translúcidas para que no interrumpan la visión cenital.', 'Sí / Sí'],
        ['CL 009', 'Trazabilidad del flujo de vida de un nivel', '1. No se experimenta un sobrelapamiento de un nivel inconcluso con un reinicio de partida.', 'Sí']
    ]
)

add_paragraph_custom(doc, 'Resultado del Sprint 1:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Al término del Sprint 1, el juego goza de una base arquitectónica controlada. Al iniciar la aplicación, se fuerza una máquina de estados segura que retiene las lógicas físicas de la red hasta que el usuario especifica con claridad qué fase o nivel desea jugar. Sobre este lienzo en blanco posicionado bajo las reglas del motor, ahora pueden trazarse las relaciones numéricas de un grafo.')

# Sprint 2
add_heading_custom(doc, 'Sprint 2', level=3)
add_paragraph_custom(doc, 'Objetivo del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Dotar a la simulación del verbo activo central: la acción de conectar nodos. Implementar la lógica que forja aristas dinámicamente validadas por medio de la "Matriz de Adyacencia", mientras devela controles paramétricos de retroalimentación en la interfaz como el manejo prudente de presupuesto "Dinero" (basado en el peso de las aristas).')

add_paragraph_custom(doc, 'Planificación del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'En este Sprint se desarrolló la esencia algorítmica de la conexión (MatrizAdyacencia.server.lua y GrafoHelpers.lua). Se dispuso un mecanismo que supervisa toda tentativa de conexión, analizando su legalidad frente a preceptos como la de "grafo dirigido o no dirigido", al tiempo que realiza las sustracciones lógicas en UI por concepto del costo operacional ("pseudopesos" formados por el trazado de cableado).')

add_paragraph_custom(doc, 'Tabla 2.15 Sprint Backlog - Sprint 2', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO / MECÁNICA', 'ESTIMACIÓN (HORAS)'],
    [
        ['TG 01', 'Permitir la selección secuencial clic-sobre-clic entre un nodo de origen y destino para crear una "Arista Física (Cable)".', '12'],
        ['TG 03', 'Crear una función de desmontaje controlado que barra tramos incorrectos suprimiéndolos del registro transaccional lógico de memoria.', '6'],
        ['TG 05', 'Asegurar la validación topológica negando flujos ilegales (reversas en caminos dirigidos) o superposición reiterativa de la misma arista.', '10'],
        ['TG 04', 'Manejo contable del peso de las aristas, afectando de forma restada la variable económica base o presupuesto.', '10'],
        ['CL 007', 'Instalación de las cabeceras UI o paneles (PanelMisionesHUD.lua) que notifiquen en vivo las modificaciones del presupuesto ante cada operación.', '14'],
        ['TOTAL', '', '52']
    ]
)

add_paragraph_custom(doc, 'Tabla 2.16 Revisión de Criterios de Aceptación - Sprint 2', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO', 'CRITERIOS DE ACEPTACIÓN', 'CUMPLIMIENTO'],
    [
        ['TG 01', 'Forjado material de aristas eléctricas dinámicas', '1. Existe una representación en forma de cable al seleccionar dos puntos. 2. Se inscribe un nuevo valor relacional (X|Y) exitosamente en la Matriz de Adyacencia centralizada.', 'Sí / Sí'],
        ['TG 03', 'Erradicación y desmontaje parcial', '1. Retiro eficaz de la entidad visual 3D. 2. Eliminación de las relaciones recíprocas en las entidades del estado simulado.', 'Sí / Sí'],
        ['TG 05', 'Legalidad de Rutas de la Matriz', '1. La aplicación imposibilita empíricamente la producción de aristas que no obedezcan relaciones booleanas o dirían estar prohibidas (flechas univia).', 'Sí'],
        ['TG 04', 'Limitante de Pesos y Redes', '1. No puede erigirse ningún cable si esta acción deja a la cuenta restando de cero, asumiendo su peso respectivo.', 'Sí'],
        ['CL 007', 'HUD Informacional Misiones', '1. Cualquier adicción o resta nodal impacta velozmente y persistentemente frente a sus ojos en la lista.', 'Sí']
    ]
)

add_paragraph_custom(doc, 'Resultado del Sprint 2:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Se logró consolidar la experiencia táctica. El usuario puede ahora tomar la iniciativa computacional tendiendo cables, errando pragmáticamente, borrando y experimentando las restricciones que los costes traen al presupuesto límite. Cada acción propaga un reordenamiento constante de toda la interconexión mediante una matriz lógica invisible al ojo pero precisa en sus números.')

# Sprint 3
add_heading_custom(doc, 'Sprint 3', level=3)
add_paragraph_custom(doc, 'Objetivo del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Otorgar un paquete de validación algorítmica profunda al jugador (Minimapa, Pestaña Analítica Inspector) a través del cual logre solicitar al sistema una evaluación por BFS/DFS para medir posibles casos de nodos huérfanos o componentes de red sin alcanzar. Completar esto estableciendo localmente la persistencia segura de su trayectoria de victorias como "Data Store".')

add_paragraph_custom(doc, 'Planificación del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Este Sprint incrustó una "lupa diagnóstica" matemática al Gameplay del usuario. Se habilitaron modos de visibilidad abstracta de las topologías (Modalidad Radar Dron (M) y Analizador de Problemas de Red (Tab)). Posteriormente se anexó a este motor la calculadora ServicioGrafosAnalisis con Algoritmos de Búsqueda capaces de dictaminar de manera certera el triunfo o desastre del estudiante.')

add_paragraph_custom(doc, 'Tabla 2.17 Sprint Backlog - Sprint 3', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO / MECÁNICA', 'ESTIMACIÓN (HORAS)'],
    [
        ['CL 004', 'Máquina Validadora (Analítica BFS): Computa por barrido si el ensamblaje de red conforma los subgrafos requeridos omitiendo caídas geográficas o nodos aislados no deseados.', '12'],
        ['TG 06', 'Modalidad visual de radar y cuadro matriz inspector, indicando desconexiones críticas mediante color rojizo y aciertos en cyan.', '16'],
        ['CL 011', 'Mecanismos semánticos de prevención y error local que anuncien con precisión sintáctica en dónde y qué nodo falló dentro de la validación matemática.', '8'],
        ['CL 008', 'Módulo ServicioProgreso y guardado local mediante Roblox DataStore para atesorar de forma eterna internamente puntaje, tiempo record y nivel victorioso.', '14'],
        ['TOTAL', '', '50']
    ]
)

add_paragraph_custom(doc, 'Tabla 2.18 Revisión de Criterios de Aceptación - Sprint 3', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO', 'CRITERIOS DE ACEPTACIÓN', 'CUMPLIMIENTO'],
    [
        ['CL 004', 'Motor BFS y Analítico Topológico', '1. El motor BFS devuelve inequívocamente la advertencia "Nodos Aislados" cuando se abortan puentes cardinales de la red objetivo.', 'Sí'],
        ['TG 06', 'Herramienta Visualizador 2D Analítico', '1. El minimapa refleja virtual y bidimensionalmente la misma geometría relacional estática que la red 3D, sin desfasarse visualmente en sus nodos.', 'Sí'],
        ['CL 011', 'Reporte directo in-game de diagnósticos', '1. El inspector o GUI de alertas traduce en términos del "sabor de mundo" (Jefe/Ciudad/Alcalde) qué secciones paralizan puntualmente los requerimientos de la misión.', 'Sí'],
        ['CL 008', 'Persistencia Vitalicia Local', '1. El entorno del Menú principal sabe reconocer e importar una puntuación (estrellas) forjada en rondas previas o cierres bruscos.', 'Sí']
    ]
)

add_paragraph_custom(doc, 'Resultado del Sprint 3:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Se formaron los verdaderos "músculos del descubrimiento". Ahora, en lugar de conectar rutas a la suerte o sin guion, se incita al estudiante a una reflexión constante. Valora una red, "solicita la revisión al sistema mediante analítica algorítmica" y experimenta el "fracaso pedagógico" identificando subgrafos defectuosos si falló. Solo logrará ser inscripto su logro permanente cuando alcance un arreglo rigurosamente conexo y apto.')

# Sprint 4
add_heading_custom(doc, 'Sprint 4', level=3)
add_paragraph_custom(doc, 'Objetivo del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Dotar a la vivencia de la calidad distintiva o cualidad "Juicy", aplicando efectos audiovisuales enrutativos inmersivos, destellos eléctricos lógicos de los cables y diseñando un epílogo triunfal GUI y sonoro que otorgue satisfacción tras cada sesión pesada y cognitiva al estudiante.')

add_paragraph_custom(doc, 'Planificación del Sprint:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'Hablamos de la fase terminal del ciclo iterativo o Pulido Global Integrado. Se redactaron e instalaron Controladores Musicales interdependientes (ControladorAudio.client) de volumen dinámico, y el subsistema de Señalética Flotante (BillboardNombres guiadas por Tween) para dotar de modernismo los textos espaciales mientras se generaba el cortometraje minimalista de Cierre ("Flash GUI blanco de cálculo y tabla de puntaje").')

add_paragraph_custom(doc, 'Tabla 2.19 Sprint Backlog - Sprint 4', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO / MECÁNICA', 'ESTIMACIÓN (HORAS)'],
    [
        ['CL 005', 'ControladorAudio Cliente: Integrar melodías adaptativas con mecanismo Crossfading silenciado entre transiciones de ambiente, evitando estática repetitiva y cruda.', '10'],
        ['TG 08', 'Construir un motor de render de etiquetas o letreros paramétricos virtuales (Tag) que proyecten los diferentes "Pesos" (Costes de las líneas) visiblemente por sobre encima de la geometría opaca.', '12'],
        ['TG 09', 'Simulador Direccional y de Velocidad (Beam/Tubos UV): Animación ininterrumpida direccional sobre las aristas, brindándole una visualidad fidedigna de sentido (a dónde fluye el poder eléctrico logístico) de un grafo dirigido.', '14'],
        ['CL 010', 'Cortinilla opaca de fin de partida que inmovilice el Input base deteniendo el reloj general del Gameplay procediendo a mostrar y tabular los "High Score" para coronación al usuario.', '8'],
        ['TOTAL', '', '44']
    ]
)

add_paragraph_custom(doc, 'Tabla 2.20 Revisión de Criterios de Aceptación - Sprint 4', bold=True, first_line_indent=Cm(0))
add_table_from_data(doc,
    ['ID', 'HISTORIA DE USUARIO', 'CRITERIOS DE ACEPTACIÓN', 'CUMPLIMIENTO'],
    [
        ['CL 005', 'Estilismo y Crossfading Musical', '1. La métrica e inmersión sensorial no se detiene dolorosamente e impide saturaciones por picos abruptos del volumen al volver del Menú Principal.', 'Sí'],
        ['TG 08', 'Interpolación Numérica Visual', '1. Examinar y pasear en el 3D presenta fiel e instintivamente al avistador el coste respectivo (Ponderación/Weight) omitiendo obstáculos traslúcidos físicos.', 'Sí'],
        ['TG 09', 'Flujo vital Eléctrico', '1. Las aristas logran lucir verdaderamente como filamentos brillantes asumiendo una velocidad UV observable desde el ánodo hacia el destino.', 'Sí'],
        ['CL 010', 'Escena o Cierre Insuperable', '1. Pantalla visual de cese o GameOver / Triunfo infalible e inequívoco coronado con la acumulación temporal de todos los rubros económicos generados.', 'Sí']
    ]
)

add_paragraph_custom(doc, 'Resultado del Sprint 4:', bold=True, first_line_indent=Cm(0))
add_paragraph_custom(doc, 'El proyecto superó el prototipado rudimentario y emergió siendo homólogo a una pieza sólida de educación entretenida del mercado comercial (Serious Game). Como resultado, la barrera inicial del estudiante, donde solían existir ansiedades y desestímulos provocados por la dureza abstracta del contenido de Estructura de Datos (EDA), ahora se contrarrestaba contundentemente con estímulos audiovisuales atractivos, dinámicos e inmersivos, culminando por completo la estructura técnica y lúdica del juego educativo planificado.')

doc.save('Documentos/Capitulo_2_Sprints.docx')
print('Documento guardado en Documentos/Capitulo_2_Sprints.docx')
