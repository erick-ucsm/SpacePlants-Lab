extends Node

var VARIABLES
var SUSTRATO
var FOTOPERIODO
var FOTOPERIODO_SIMPLE
var COMO_GANAR
var PLANTAS
var PASOS
var COMPONENTES
var REGLAS

const SEGUNDOS_REALES_POR_DIA := 180.0
const VELOCIDADES := [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
const MASA_MAXIMA_KG := 22.0
const VIDA_MINIMA_COSECHA := 80.0

const ESCALAR_CICLOS := true
const DIAS_REFERENCIA := 10.0

const HORAS_LUZ := 16.0
const HORAS_OSCURIDAD := 8.0

const ORDEN_VARIABLES := ["luz", "agua", "humedad", "temperatura", "oxigeno"]

const _ES_VARIABLES := {
	"luz": {"nombre": "Energía LEDs", "unidad": "%", "recarga": "Recargar batería", "dias_recarga": 4.0},
	"agua": {"nombre": "Depósito de agua", "unidad": "%", "recarga": "Llenar depósito", "dias_recarga": 3.0},
	"humedad": {"nombre": "Humedad del sustrato", "unidad": "%", "recarga": "Regar", "dias_recarga": 0.0},
	"temperatura": {"nombre": "Temperatura", "unidad": "°C", "recarga": "Calentar", "dias_recarga": 3.0},
	"oxigeno": {"nombre": "Oxígeno", "unidad": "% O₂", "recarga": "Renovar aire", "dias_recarga": 2.0},
}

const OXIGENO_IDEAL := [19.5, 23.5]

const _ES_SUSTRATO := "Las bolitas marrones del sustrato son arcilla calcinada (arcillita), el mismo sustrato que usa la NASA en Veggie y en el Advanced Plant Habitat: es porosa, guarda agua y aire para la raíz y lleva fertilizante de liberación lenta."

const _ES_FOTOPERIODO := "Fotoperiodo óptimo: 16 horas de luz (rojo/azul) y 8 horas de oscuridad. Usa el minijuego para mantener la energía de los LEDs."

const _ES_FOTOPERIODO_SIMPLE := "En palabras simples: las plantas necesitan 16 horas de luz al día para hacer fotosíntesis y 8 horas de oscuridad para descansar. La NASA enciende los LED rojos y azules AL MISMO TIEMPO (la mezcla se ve rosada). La luz gasta batería: si se acaba durante las horas de luz, la planta se estresa y pierde vida."

const _ES_COMO_GANAR := "Mantén las variables en el rango ideal de tu planta. Cada variable se recarga con su minijuego: Luz = 3 en raya, Agua = rompecabezas deslizante de naves, Humedad = memoria de personajes de la NASA, Temperatura = rompecabezas de temperaturas extremas, Oxígeno = golpea al alienígena. Riega con cuidado: el exceso de agua también daña. El día de cosecha pulsa COSECHAR con más de 80 % de vida."

const _ES_PLANTAS := {
	"lechuga_romana": {
		"nombre": "Lechuga romana roja",
		"variedad": "'Outredgeous'",
		"dificultad": 1, "etiqueta": "Fácil",
		"dias": 28,
		"humedad": [60.0, 70.0],
		"temperatura": [18.0, 24.0],
		"par": [200.0, 300.0],
		"consumo_agua": 7.0,
		"sensibilidad": {"general": 0.7, "humedad": 0.8, "temperatura": 0.8, "luz": 0.9},
		"resumen": "Tolera variaciones. Requiere 16 h de luz.",
		"descripcion": "La primera verdura que los astronautas de EE. UU. comieron cultivada en hardware de la NASA. Es resistente: soporta pequeños errores de riego y temperatura.\n\nNecesita 16 horas de luz al día y un sustrato húmedo (60-70 %).",
		"historia": "En el experimento VEG-01 del sistema Veggie, la lechuga 'Outredgeous' creció del 8 de julio al 10 de agosto de 2015 en la Estación Espacial; ese día la tripulación la probó. Luego se volvió a cultivar en VEG-03 con la técnica de cosecha repetida (cortar y dejar crecer).",
	},
	"mizuna": {
		"nombre": "Mostaza mizuna",
		"variedad": "Brassica rapa",
		"dificultad": 2, "etiqueta": "Fácil",
		"dias": 29,
		"humedad": [60.0, 70.0],
		"temperatura": [16.0, 24.0],
		"par": [200.0, 300.0],
		"consumo_agua": 8.5,
		"sensibilidad": {"general": 0.85, "humedad": 0.9, "temperatura": 0.85, "luz": 1.0},
		"resumen": "Crecimiento rápido.",
		"descripcion": "Hoja verde de sabor picante suave, pariente de la mostaza. Crece rápido, así que toma más agua que la lechuga.\n\nSustrato húmedo (60-70 %) y 16 horas de luz.",
		"historia": "Se cultivó en Veggie durante VEG-03 (2017) junto a la lechuga romana roja y la col china. En VEG-04 (2019) la NASA la usó para probar distintas mezclas de luz roja, azul y verde y ver cómo cambian su crecimiento y su sabor.",
	},
	"kale": {
		"nombre": "Col rizada (Kale)",
		"variedad": "'Red Russian'",
		"dificultad": 3, "etiqueta": "Media",
		"dias": 32,
		"humedad": [60.0, 70.0],
		"temperatura": [16.0, 24.0],
		"par": [250.0, 350.0],
		"consumo_agua": 8.5,
		"sensibilidad": {"general": 1.0, "humedad": 1.0, "temperatura": 1.0, "luz": 1.2},
		"resumen": "Requiere más nutrientes.",
		"descripcion": "Hojas grandes y rizadas con tallos morados. Es más exigente: necesita más luz y nutrientes para formar hojas grandes, por eso la falta de luz le afecta más.\n\nSustrato húmedo (60-70 %).",
		"historia": "El kale 'Red Russian' llegó a Veggie en 2018 (VEG-03G) y la astronauta Serena Auñón-Chancellor lo plantó para la cena de Acción de Gracias. Sigue cultivándose en 2026 en el estudio ISS Gardens (VEG-03 MNO).",
	},
	"rabano": {
		"nombre": "Rábano",
		"variedad": "Raphanus sativus",
		"dificultad": 4, "etiqueta": "Media-Alta",
		"dias": 30,
		"humedad": [50.0, 60.0],
		"temperatura": [16.0, 22.0],
		"par": [250.0, 350.0],
		"consumo_agua": 6.5,
		"sensibilidad": {"general": 1.1, "humedad": 1.4, "temperatura": 1.0, "luz": 1.0},
		"resumen": "Cultivo de raíz: el sustrato debe estar más seco.",
		"descripcion": "Lo que se come es la raíz (el bulbo rojo). Si el sustrato está muy mojado la raíz se pudre, por eso necesita un sustrato MÁS SECO (50-60 %) que las hojas verdes.",
		"historia": "En el experimento Plant Habitat-02 la NASA cultivó rábanos por primera vez en la Estación Espacial, dentro del Advanced Plant Habitat. Crecieron en 27 días y la astronauta Kate Rubins cosechó 20 plantas el 30 de noviembre de 2020.",
	},
	"chile": {
		"nombre": "Chile",
		"variedad": "'Española Improved' (Hatch)",
		"dificultad": 5, "etiqueta": "Difícil",
		"dias": 100,
		"humedad": [55.0, 65.0],
		"temperatura": [22.0, 26.0],
		"par": [300.0, 400.0],
		"consumo_agua": 7.0,
		"sensibilidad": {"general": 1.2, "humedad": 1.6, "temperatura": 1.6, "luz": 1.2},
		"resumen": "Muy sensible a temperatura y humedad.",
		"descripcion": "Planta con flores y frutos: tarda mucho más que las hojas verdes y es muy sensible a los cambios de temperatura y humedad. Primero da chiles verdes que luego se vuelven rojos.\n\nSustrato 55-65 %, temperatura 22-26 °C.",
		"historia": "En Plant Habitat-04 (2021) la NASA cultivó chiles 'Española Improved' de Hatch, Nuevo México. Fue el experimento de plantas más largo de la estación: 137 días. Las 4 plantas dieron 26 chiles y la tripulación los comió en tacos.",
	},
}

const ORDEN_PLANTAS := ["lechuga_romana", "mizuna", "kale", "rabano", "chile"]

const BASE_KIT := ["deposito_agua", "controlador_central", "medidor_energia"]

const _ES_PASOS := [
	{"id": "semilla", "titulo": "Semillas",
		"instruccion": "¿Qué planta quieres cultivar?\nTodas fueron cultivadas y cosechadas por la NASA en el espacio.",
		"opciones": ORDEN_PLANTAS},
	{"id": "riego", "titulo": "Riego",
		"instruccion": "¿Cómo llegará el agua del depósito a la raíz?\nElige UNO.",
		"opciones": ["mecha_absorbente", "bomba_peristaltica", "electrovalvula", "riego_inmersion"]},
	{"id": "monitoreo_agua", "titulo": "Monitoreo del agua",
		"instruccion": "¿Qué quieres medir?\nElige UN sensor.",
		"opciones": ["sensor_humedad_sustrato", "sensor_nivel"]},
	{"id": "fuente_luz", "titulo": "Fuente de luz",
		"instruccion": "¿De dónde vendrá la luz para la fotosíntesis?\nElige UNA.",
		"opciones": ["panel_led", "tubo_luz_natural"]},
	{"id": "control_luz", "titulo": "Control de luz",
		"instruccion": "¿Cómo manejarás el fotoperiodo (16 h luz / 8 h oscuridad)?\nElige UNO.",
		"opciones": ["temporizador_fotoperiodo", "atenuador_pwm", "sensor_par"]},
	{"id": "monitoreo_aire", "titulo": "Monitoreo del aire",
		"instruccion": "¿Qué medirás en la atmósfera del módulo?\nElige UN sensor.",
		"opciones": ["sensor_oxigeno", "sensor_co2", "sensor_presion"]},
	{"id": "control_aire", "titulo": "Control del aire",
		"instruccion": "¿Cómo mantendrás el aire sano para la planta?\nElige UNO.",
		"opciones": ["ventilador", "inyector_co2", "condensador_humedad", "depurador_co2", "tanque_oxigeno"]},
	{"id": "termico", "titulo": "Control térmico",
		"instruccion": "Afuera del módulo hace frío extremo.\n¿Cómo mantendrás la temperatura? Elige UNO.",
		"opciones": ["calentador_kapton", "aislamiento_mli"]},
	{"id": "energia", "titulo": "Energía",
		"instruccion": "¿De dónde saldrá la electricidad?\nElige UNA fuente.",
		"opciones": ["bateria", "panel_solar"]},
]

const _ES_COMPONENTES := {
	"deposito_agua": {
		"nombre": "Depósito de agua", "masa_kg": 10.5, "potencia_w": 0.0,
		"que_hace": "Guarda la reserva de agua de la misión (10 litros).",
		"como_funciona": "Un tanque sellado almacena el agua. Su nivel baja cuando el agua pasa al sustrato.",
		"ejemplo": "Tanque de polímero o bolsa flexible para agua",
		"efecto": "Incluido siempre. Lo llenas ganando el minijuego."
	},
	"controlador_central": {
		"nombre": "Controlador central", "masa_kg": 0.3, "potencia_w": 2.0,
		"que_hace": "Decide qué hacer con las lecturas de los sensores.",
		"como_funciona": "Lee los sensores, compara con el rango ideal y activa los actuadores.",
		"ejemplo": "Microcontrolador ESP32",
		"efecto": "Incluido siempre. Es el cerebro del módulo."
	},
	"medidor_energia": {
		"nombre": "Medidor de energía", "masa_kg": 0.05, "potencia_w": 0.1,
		"que_hace": "Mide cuánta energía gasta el módulo.",
		"como_funciona": "Mide voltaje y corriente y calcula la potencia consumida.",
		"ejemplo": "Sensor INA219",
		"efecto": "Incluido siempre. Muestra el % exacto de batería de los LEDs."
	},
	"mecha_absorbente": {
		"nombre": "Mecha absorbente", "masa_kg": 0.1, "potencia_w": 0.0,
		"que_hace": "Sube el agua del depósito al sustrato sin bombas ni electricidad.",
		"como_funciona": "Tiras de tela absorbente tocan el agua del depósito y la suben por capilaridad hasta la arcillita, como una servilleta que se moja desde una punta. Es el riego pasivo que usa Veggie.",
		"ejemplo": "Mechas de tela de nylon o algodón",
		"efecto": "Riego AUTOMÁTICO: mantiene el sustrato cerca de 64 % mientras haya agua en el depósito. El depósito baja solo, poco a poco. Si riegas extra con el minijuego suma +10 % y te puedes pasar.",
		"por_que": "Lo agregamos porque es el sistema real de Veggie en la Estación Espacial: sin él (o sin bomba) el agua no llega a la planta."
	},
	"bomba_peristaltica": {
		"nombre": "Bomba peristáltica", "masa_kg": 0.6, "potencia_w": 1.0,
		"que_hace": "Mueve el agua hacia la raíz en dosis precisas.",
		"como_funciona": "Un rotor aprieta un tubo flexible y empuja el agua por pulsos. Funciona sin gravedad.",
		"ejemplo": "Bomba peristáltica de 12 V (6 W al regar)",
		"efecto": "Riego MANUAL y PRECISO: al ganar el minijuego de memoria, el sustrato sube exactamente hasta el tope del rango ideal, sin pasarse. Tú decides cuándo regar: ideal para plantas que necesitan sustrato más seco."
	},
	"electrovalvula": {
		"nombre": "Electroválvula", "masa_kg": 0.3, "potencia_w": 0.5,
		"que_hace": "Abre o cierra el paso del agua.",
		"como_funciona": "Una bobina mueve una compuerta. En la Tierra el agua cae por gravedad; en microgravedad NO cae: sin una bomba que dé presión, el agua no se mueve.",
		"ejemplo": "Electroválvula solenoide de 12 V",
		"efecto": "Sin bomba ni mecha el agua NO llega a la planta: la humedad del sustrato baja hasta 0 %."
	},
	"riego_inmersion": {
		"nombre": "Riego por inmersión", "masa_kg": 2.5, "potencia_w": 8.0,
		"que_hace": "Inunda la bandeja de raíces y luego la drena.",
		"como_funciona": "Una pequeña bomba llena la bandeja hasta cubrir la raíz y luego la vacía. Es común en invernaderos de la Tierra.",
		"ejemplo": "Bandeja de flujo y reflujo con bomba",
		"efecto": "Riego AUTOMÁTICO pero brusco: cuando el sustrato baja de 58 % lo inunda hasta 78 %. Se pasa del rango de casi todas las plantas y pudre las raíces sensibles.",
		"por_que": "Lo agregamos como ejemplo de un sistema que funciona en la Tierra pero que no conviene para todas las plantas."
	},
	"sensor_humedad_sustrato": {
		"nombre": "Sensor de humedad del sustrato", "masa_kg": 0.02, "potencia_w": 0.1,
		"que_hace": "Mide cuánta agua hay en el sustrato de la raíz.",
		"como_funciona": "Una sonda enterrada mide la capacitancia, que cambia con la humedad.",
		"ejemplo": "Sensor capacitivo de humedad de suelo",
		"efecto": "Ves la humedad EXACTA del sustrato. Sin él la humedad aparece como ??? y riegas a ciegas."
	},
	"sensor_nivel": {
		"nombre": "Sensor de nivel", "masa_kg": 0.05, "potencia_w": 0.05,
		"que_hace": "Mide cuánta agua queda en el depósito.",
		"como_funciona": "Un flotador sube y baja con el agua y marca el nivel.",
		"ejemplo": "Sensor de nivel con flotador",
		"efecto": "Ves el % EXACTO del depósito, pero la humedad del sustrato será ??? (riegas a ciegas)."
	},
	"panel_led": {
		"nombre": "Panel LED rojo y azul", "masa_kg": 1.5, "potencia_w": 50.0,
		"que_hace": "Da la luz que la planta usa para la fotosíntesis.",
		"como_funciona": "LEDs rojos y azules encendidos AL MISMO TIEMPO (la mezcla se ve rosada). Son las longitudes de onda que más absorbe la clorofila.",
		"ejemplo": "Panel LED de cultivo rojo/azul (Veggie usa unos 70 W en total)",
		"efecto": "Luz confiable. Consume 50 W solo mientras está encendido: apágalo en las 8 h de oscuridad para ahorrar batería."
	},
	"tubo_luz_natural": {
		"nombre": "Tubo de luz natural", "masa_kg": 4.0, "potencia_w": 0.0,
		"que_hace": "Lleva luz solar al interior sin gastar electricidad.",
		"como_funciona": "Un conducto reflectante captura luz del exterior. Depende de que haya Sol afuera: en órbita y en la Luna la luz exterior no sigue un horario de 16 h.",
		"ejemplo": "Light pipe o fibra óptica solar",
		"efecto": "No gasta batería, pero hay periodos largos sin luz exterior y la planta pierde vida en esas horas. No se puede encender ni apagar."
	},
	"temporizador_fotoperiodo": {
		"nombre": "Temporizador de fotoperiodo", "masa_kg": 0.05, "potencia_w": 0.1,
		"que_hace": "Enciende y apaga la luz automáticamente.",
		"como_funciona": "Un reloj enciende los LED 16 horas y los apaga 8 horas cada día, igual que en Veggie.",
		"ejemplo": "Reloj RTC DS3231",
		"efecto": "Fotoperiodo AUTOMÁTICO 16/8: no tienes que encender ni apagar la luz y nunca la dejas prendida de noche."
	},
	"atenuador_pwm": {
		"nombre": "Atenuador PWM", "masa_kg": 0.05, "potencia_w": 0.2,
		"que_hace": "Regula la intensidad de la luz.",
		"como_funciona": "Enciende y apaga el LED miles de veces por segundo; si pasa más tiempo encendido la luz es más fuerte.",
		"ejemplo": "Módulo MOSFET con PWM",
		"efecto": "El panel LED gasta 30 % menos (35 W en vez de 50 W). Pero debes encender y apagar la luz tú mismo."
	},
	"sensor_par": {
		"nombre": "Sensor de luz PAR", "masa_kg": 0.2, "potencia_w": 0.2,
		"que_hace": "Mide la luz que la planta realmente usa.",
		"como_funciona": "Un fotodiodo con filtro mide solo la radiación útil para la fotosíntesis.",
		"ejemplo": "Sensor PAR (cuántico)",
		"efecto": "Ves la intensidad EXACTA en µmol/m²/s. Debes encender y apagar la luz tú mismo."
	},
	"sensor_oxigeno": {
		"nombre": "Sensor de oxígeno", "masa_kg": 0.1, "potencia_w": 0.5,
		"que_hace": "Mide el oxígeno del módulo.",
		"como_funciona": "Una celda electroquímica genera una corriente proporcional al oxígeno.",
		"ejemplo": "Sensor electroquímico de O₂",
		"efecto": "Ves el oxígeno EXACTO."
	},
	"sensor_co2": {
		"nombre": "Sensor de CO₂", "masa_kg": 0.05, "potencia_w": 1.0,
		"que_hace": "Mide el CO₂, que muestra cuánta fotosíntesis hay.",
		"como_funciona": "Mide cuánta luz infrarroja absorbe el CO₂ del aire.",
		"ejemplo": "Sensor SCD40",
		"efecto": "Oxígeno aproximado con ALERTA temprana. La planta se recupera 25 % más rápido porque ajustas mejor el aire."
	},
	"sensor_presion": {
		"nombre": "Sensor de presión", "masa_kg": 0.01, "potencia_w": 0.05,
		"que_hace": "Detecta fugas del módulo.",
		"como_funciona": "Una caída de presión sostenida indica que se escapa aire.",
		"ejemplo": "Sensor BMP280",
		"efecto": "Oxígeno aproximado, pero las fugas te quitan 10 % en vez de 30 %."
	},
	"ventilador": {
		"nombre": "Ventilador", "masa_kg": 0.2, "potencia_w": 3.0,
		"que_hace": "Mueve el aire del módulo.",
		"como_funciona": "En microgravedad el aire caliente no sube: sin ventilador se forman bolsas de aire sin mezclar alrededor de las hojas.",
		"ejemplo": "Ventilador axial de 12 V",
		"efecto": "El daño por exceso de temperatura u oxígeno se reduce a la mitad."
	},
	"inyector_co2": {
		"nombre": "Inyector de CO₂", "masa_kg": 2.5, "potencia_w": 1.0,
		"que_hace": "Agrega CO₂ para la fotosíntesis.",
		"como_funciona": "Una válvula libera CO₂ desde una reserva cuando el nivel baja.",
		"ejemplo": "Cilindro de CO₂ con regulador",
		"efecto": "Más fotosíntesis: el oxígeno baja 30 % más lento."
	},
	"condensador_humedad": {
		"nombre": "Condensador de humedad", "masa_kg": 1.5, "potencia_w": 25.0,
		"que_hace": "Recupera el agua que la planta transpira.",
		"como_funciona": "Una placa fría condensa el vapor del aire y devuelve el agua al depósito.",
		"ejemplo": "Condensador con celda Peltier",
		"efecto": "El depósito dura 30 % más, pero gasta 25 W todo el tiempo y vacía la batería más rápido."
	},
	"depurador_co2": {
		"nombre": "Depurador de CO₂", "masa_kg": 6.0, "potencia_w": 30.0,
		"que_hace": "Quita CO₂ del aire.",
		"como_funciona": "El aire pasa por un material que atrapa el CO₂ (la ISS usa uno llamado CDRA).",
		"ejemplo": "Cartucho absorbente de CO₂",
		"efecto": "Renovación del aire PRECISA, pero pesa 6 kg, gasta 30 W y quita el CO₂ que la planta necesita para crecer."
	},
	"tanque_oxigeno": {
		"nombre": "Tanque de reserva de oxígeno", "masa_kg": 5.0, "potencia_w": 0.0,
		"que_hace": "Respaldo de oxígeno.",
		"como_funciona": "Libera oxígeno comprimido si el nivel es peligroso.",
		"ejemplo": "Cilindro de oxígeno comprimido",
		"efecto": "UNA vez por misión, si el oxígeno llega a nivel crítico, se libera solo."
	},
	"calentador_kapton": {
		"nombre": "Calentador Kapton + termostato", "masa_kg": 0.05, "potencia_w": 10.0,
		"que_hace": "Calienta con una lámina eléctrica delgada y mide la temperatura.",
		"como_funciona": "Una resistencia sobre película de poliimida se calienta; un termostato la apaga al llegar al objetivo.",
		"ejemplo": "Calentador flexible de poliimida de 12 V",
		"efecto": "Recarga PRECISA de temperatura y ves la temperatura EXACTA. Gasta 10 W.",
		"por_que": "Lo agregamos porque el Excel no tenía nada para la temperatura; los satélites de la NASA usan estos calentadores."
	},
	"aislamiento_mli": {
		"nombre": "Aislamiento multicapa (MLI)", "masa_kg": 1.5, "potencia_w": 0.0,
		"que_hace": "Envuelve el módulo para que no pierda calor.",
		"como_funciona": "Capas de plástico aluminizado reflejan el calor. Es la manta dorada de los satélites y del telescopio James Webb.",
		"ejemplo": "Manta MLI de Mylar aluminizado",
		"efecto": "La temperatura baja 40 % más lento y no gasta energía, pero no ves la temperatura exacta y la recarga es imprecisa (+80 %).",
		"por_que": "Lo agregamos porque es la protección térmica pasiva más usada por la NASA."
	},
	"bateria": {
		"nombre": "Batería", "masa_kg": 4.0, "potencia_w": 0.0, "capacidad": "500 Wh",
		"que_hace": "Guarda la energía de los LEDs.",
		"como_funciona": "Almacena electricidad y la entrega de forma estable, también cuando no hay Sol.",
		"ejemplo": "Batería de iones de litio de 500 Wh",
		"efecto": "La batería dura 10 % más y no le afectan las sombras ni el polvo."
	},
	"panel_solar": {
		"nombre": "Panel solar", "masa_kg": 3.0, "potencia_w": 0.0, "capacidad": "genera hasta 100 W",
		"que_hace": "Genera electricidad con la luz del Sol.",
		"como_funciona": "Las celdas convierten la luz en corriente. No generan nada a la sombra.",
		"ejemplo": "Panel fotovoltaico de 100 W",
		"efecto": "Recarga un poco la batería: dura 20 % más, pero las sombras y el polvo bajan la energía de golpe."
	},
}

const _ES_REGLAS := {
	"mecha_absorbente": {"todas": ["verde", "Es el riego de Veggie: mantiene el sustrato estable cerca de 63 %, dentro del rango de esta planta."],
		"rabano": ["rojo", "Mantiene el sustrato cerca de 63 %: demasiado húmedo para el rábano (50-60 %); la raíz se pudre."]},
	"bomba_peristaltica": {"todas": ["neutro", "Funciona bien, pero tienes que regar a mano."],
		"rabano": ["verde", "Riegas dosis exactas y mantienes el sustrato más seco, como necesita el rábano."],
		"chile": ["verde", "Control preciso del riego para una planta muy sensible a la humedad."]},
	"electrovalvula": {"todas": ["rojo", "En microgravedad el agua no cae: sin bomba ni mecha el agua no llega a la planta."]},
	"riego_inmersion": {"todas": ["neutro", "Inunda el sustrato hasta 78 %: se pasa del rango y causa estrés por exceso de agua."],
		"rabano": ["rojo", "Inundar la bandeja pudre la raíz del rábano."],
		"chile": ["rojo", "Los cambios bruscos de humedad estresan mucho al chile."]},
	"sensor_humedad_sustrato": {"todas": ["verde", "Sin él no ves la humedad del sustrato (???) y riegas a ciegas."]},
	"sensor_nivel": {"todas": ["neutro", "Ves el depósito, pero la humedad del sustrato será ???."],
		"rabano": ["rojo", "El rábano tiene un rango de humedad estrecho: regar a ciegas es muy arriesgado."],
		"chile": ["rojo", "El chile es muy sensible a la humedad: regar a ciegas es muy arriesgado."]},
	"panel_led": {"todas": ["verde", "Mezcla de luz roja y azul, igual que Veggie."]},
	"tubo_luz_natural": {"todas": ["rojo", "La luz exterior no sigue el fotoperiodo de 16 h: habrá periodos largos sin luz."]},
	"temporizador_fotoperiodo": {"todas": ["verde", "Hace el fotoperiodo 16/8 automáticamente: no olvidas encender ni apagar."]},
	"atenuador_pwm": {"todas": ["neutro", "Ahorra 30 % de energía, pero debes encender y apagar la luz tú."]},
	"sensor_par": {"todas": ["neutro", "Mide la luz exacta, pero debes encender y apagar la luz tú."]},
	"sensor_oxigeno": {"todas": ["neutro", "Útil: ves el oxígeno exacto."]},
	"sensor_co2": {"todas": ["verde", "Muestra si hay fotosíntesis y ayuda a que la planta se recupere."]},
	"sensor_presion": {"todas": ["neutro", "Detecta fugas, pero no ves el oxígeno exacto."]},
	"ventilador": {"todas": ["verde", "Sin gravedad el aire no se mezcla solo; consume solo 3 W."]},
	"inyector_co2": {"todas": ["neutro", "Más fotosíntesis, pero pesa 2.5 kg."],
		"chile": ["verde", "Más fotosíntesis para un ciclo largo con flores y frutos."],
		"kale": ["verde", "El kale necesita más recursos para formar hojas grandes."]},
	"condensador_humedad": {"todas": ["rojo", "Consume 25 W todo el tiempo: vacía la batería de los LEDs."]},
	"depurador_co2": {"todas": ["rojo", "Pesa 6 kg, gasta 30 W y quita el CO₂ que la planta necesita."]},
	"tanque_oxigeno": {"todas": ["neutro", "Respaldo de emergencia, pero pesa 5 kg."]},
	"calentador_kapton": {"todas": ["neutro", "Temperatura exacta y recarga precisa; gasta 10 W."],
		"chile": ["verde", "El chile es muy sensible a la temperatura: necesitas control preciso."],
		"rabano": ["verde", "Ves la temperatura exacta para mantener el rango fresco del rábano."]},
	"aislamiento_mli": {"todas": ["verde", "Protección pasiva sin energía; la planta tolera pequeñas variaciones."],
		"chile": ["rojo", "Sin termostato no ves la temperatura exacta: muy arriesgado para el chile."],
		"rabano": ["neutro", "Funciona, pero no ves la temperatura exacta."]},
	"bateria": {"todas": ["neutro", "Energía estable, pero pesa 4 kg."],
		"chile": ["verde", "Para 100 días conviene una fuente estable y sin sombras."]},
	"panel_solar": {"todas": ["neutro", "La batería dura más, pero las sombras bajan la energía."],
		"chile": ["rojo", "En 100 días habrá muchas sombras y polvo: riesgo de apagones."]},
}


func _enter_tree() -> void:
	aplicar_idioma()


func _ready() -> void:
	Idioma.idioma_cambiado.connect(aplicar_idioma)


func aplicar_idioma() -> void:
	VARIABLES = Idioma.traducir(_ES_VARIABLES)
	SUSTRATO = Idioma.traducir(_ES_SUSTRATO)
	FOTOPERIODO = Idioma.traducir(_ES_FOTOPERIODO)
	FOTOPERIODO_SIMPLE = Idioma.traducir(_ES_FOTOPERIODO_SIMPLE)
	COMO_GANAR = Idioma.traducir(_ES_COMO_GANAR)
	PLANTAS = Idioma.traducir(_ES_PLANTAS)
	PASOS = Idioma.traducir(_ES_PASOS)
	COMPONENTES = Idioma.traducir(_ES_COMPONENTES)
	REGLAS = Idioma.traducir(_ES_REGLAS)


func icono_componente(id: String) -> String:
	return "res://assets/componentes/%s.png" % id


func icono_semilla(id: String) -> String:
	return "res://assets/semillas/%s.png" % id


func planta(id: String) -> Dictionary:
	return PLANTAS.get(id, PLANTAS["lechuga_romana"])


func masa_de(id: String) -> float:
	return COMPONENTES[id]["masa_kg"]


func potencia_de(id: String) -> float:
	return COMPONENTES[id]["potencia_w"]


func texto_masa(kg: float) -> String:
	if kg < 1.0:
		return "%d g" % roundi(kg * 1000.0)
	return "%.1f kg" % kg


func texto_potencia(w: float) -> String:
	if w <= 0.0:
		return "0 W"
	if w < 1.0:
		return "%.2f W" % w
	return "%d W" % roundi(w)


func color_dificultad(nivel: int) -> Color:
	match nivel:
		1, 2: return Color(0.45, 0.95, 0.55)
		3: return Color(1.0, 0.85, 0.35)
		4: return Color(1.0, 0.6, 0.3)
	return Color(1.0, 0.4, 0.35)


func recomendacion(componente: String, planta_id: String) -> Array:
	var r: Dictionary = REGLAS.get(componente, {})
	if r.has(planta_id):
		return r[planta_id]
	if r.has("todas"):
		return r["todas"]
	return ["neutro", ""]


func cargar_textura(ruta: String) -> Texture2D:
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return null
