extends RefCounted

const NAVES := [
	{
		"id": "voyager1", "nombre": "Voyager 1", "imagen": "res://assets/minijuegos/naves/voyager1.png",
		"lanzamiento": "5 de septiembre de 1977, Cabo Cañaveral (cohete Titan IIIE)",
		"mision": "Sobrevolar Júpiter (1979) y Saturno (1980) y luego seguir hacia el espacio interestelar.",
		"logro": "Primer objeto hecho por humanos en llegar al espacio interestelar (2012). Es el objeto humano más lejano de la Tierra.",
		"historia": "Lleva el Disco de Oro con sonidos, música e imágenes de la Tierra para quien lo encuentre. En 1990 tomó la famosa foto \"Pálido Punto Azul\". El 18 de noviembre de 2026 llega a 1 día-luz de distancia (unos 25 900 millones de km): un mensaje de radio tarda 24 horas en llegar."
	},
	{
		"id": "apolo11", "nombre": "Apolo 11 (módulo lunar Eagle)", "imagen": "res://assets/minijuegos/naves/apolo11.png",
		"lanzamiento": "16 de julio de 1969, Centro Espacial Kennedy (cohete Saturno V)",
		"mision": "Llevar por primera vez seres humanos a la superficie de la Luna y traerlos de vuelta.",
		"logro": "El 20 de julio de 1969 el módulo Eagle se posó en el Mar de la Tranquilidad: Neil Armstrong y Buzz Aldrin caminaron sobre la Luna.",
		"historia": "Michael Collins esperó en órbita en el módulo de mando Columbia. Los astronautas trajeron unos 21.5 kg de rocas lunares y regresaron el 24 de julio. La foto muestra a Aldrin junto al Eagle."
	},
	{
		"id": "discovery", "nombre": "Transbordador espacial Discovery", "imagen": "res://assets/minijuegos/naves/discovery.png",
		"lanzamiento": "Primer vuelo: 30 de agosto de 1984 (STS-41-D); último: 2011 (STS-133)",
		"mision": "Nave reutilizable para llevar astronautas, satélites y módulos a la órbita terrestre.",
		"logro": "Es el transbordador que más voló: 39 misiones. Lanzó el telescopio espacial Hubble en 1990.",
		"historia": "Hizo los vuelos de \"regreso\" tras los accidentes del Challenger (1988) y del Columbia (2005) y ayudó a construir la Estación Espacial. Hoy se exhibe en el museo Smithsonian, cerca de Washington."
	},
	{
		"id": "new_horizons", "nombre": "New Horizons", "imagen": "res://assets/minijuegos/naves/new_horizons.png",
		"lanzamiento": "19 de enero de 2006, Cabo Cañaveral (cohete Atlas V)",
		"mision": "Explorar Plutón, sus lunas y el Cinturón de Kuiper.",
		"logro": "Primera nave en visitar Plutón (14 de julio de 2015). Descubrió su gran \"corazón\" de hielo.",
		"historia": "Fue una de las naves más rápidas al despegar de la Tierra. En 2019 sobrevoló Arrokoth, el objeto más lejano explorado de cerca. Lleva parte de las cenizas de Clyde Tombaugh, quien descubrió Plutón en 1930."
	},
	{
		"id": "orion", "nombre": "Orion (nueva generación)", "imagen": "res://assets/minijuegos/naves/orion.png",
		"lanzamiento": "Artemis I: 16 de noviembre de 2022 (sin tripulación). Artemis II: 1 de abril de 2026 (con tripulación)",
		"mision": "Llevar astronautas más allá de la órbita terrestre: a la Luna y, en el futuro, hacia Marte.",
		"logro": "En Artemis II llevó a 4 astronautas alrededor de la Luna y batió el récord de distancia de humanos: 406 771 km de la Tierra.",
		"historia": "Tiene una cápsula para 4 personas y un módulo de servicio construido por la Agencia Espacial Europea, con 4 alas solares. Artemis II amerizó en el Pacífico el 10 de abril de 2026: fue el primer viaje de humanos a la Luna en más de 50 años."
	},
]

const GENERACIONES := [
	{
		"nombre": "Pioneros (1958-1965)",
		"descripcion": "Los primeros pasos: la NACA se convierte en NASA y los programas Mercury y Gemini llevan a los primeros estadounidenses al espacio.",
		"color": Color(0.85, 0.55, 0.2),
		"personas": [
			{"id": "goddard", "nombre": "Robert H. Goddard", "rol": "cientifico", "logro": "Lanzó el primer cohete de combustible líquido de la historia (1926).", "por_que": "Es el padre de la cohetería moderna; el Centro de Vuelo Espacial Goddard de la NASA lleva su nombre."},
			{"id": "katherine_johnson", "nombre": "Katherine Johnson", "rol": "matematica", "logro": "Calculó trayectorias del primer vuelo de Alan Shepard y verificó a mano los cálculos de la órbita de John Glenn (1962).", "por_que": "Sus cálculos fueron clave para los primeros vuelos tripulados; recibió la Medalla Presidencial de la Libertad."},
			{"id": "dorothy_vaughan", "nombre": "Dorothy Vaughan", "rol": "matematica", "logro": "Primera supervisora afroamericana de la NACA; aprendió y enseñó a programar en FORTRAN.", "por_que": "Preparó a su equipo para la era de las computadoras electrónicas en la NASA."},
			{"id": "mary_jackson", "nombre": "Mary Jackson", "rol": "ingeniera", "logro": "Primera ingeniera afroamericana de la NASA (1958); investigó con túneles de viento.", "por_que": "Abrió camino a mujeres y minorías en la ingeniería; la sede de la NASA lleva su nombre."},
			{"id": "alan_shepard", "nombre": "Alan Shepard", "rol": "astronauta", "logro": "Primer estadounidense en el espacio (Freedom 7, 5 de mayo de 1961).", "por_que": "Abrió los vuelos tripulados de EE. UU.; años después caminó en la Luna con el Apolo 14."},
			{"id": "john_glenn", "nombre": "John Glenn", "rol": "astronauta", "logro": "Primer estadounidense en orbitar la Tierra (Friendship 7, 1962).", "por_que": "Su vuelo demostró que se podía vivir en órbita; a los 77 años volvió al espacio en el Discovery."},
			{"id": "gus_grissom", "nombre": "Gus Grissom", "rol": "astronauta", "logro": "Segundo estadounidense en el espacio y comandante del Gemini 3.", "por_que": "Murió en el incendio del Apolo 1 (1967); su sacrificio hizo más seguras las naves Apolo."},
			{"id": "ed_white", "nombre": "Ed White", "rol": "astronauta", "logro": "Primera caminata espacial estadounidense (Gemini 4, 1965).", "por_que": "Demostró que un astronauta puede trabajar fuera de la nave."},
			{"id": "max_faget", "nombre": "Max Faget", "rol": "ingeniero", "logro": "Diseñó la cápsula Mercury.", "por_que": "Sus diseños influyeron en Gemini, Apolo y el transbordador espacial."},
			{"id": "chris_kraft", "nombre": "Christopher Kraft", "rol": "ingeniero", "logro": "Creó el Control de Misión y fue el primer director de vuelo de la NASA.", "por_que": "El Centro de Control de Misión de Houston lleva su nombre."},
		]
	},
	{
		"nombre": "Era Apolo (1966-1975)",
		"descripcion": "La carrera a la Luna: el cohete Saturno V y las misiones Apolo llevan a 12 personas a caminar sobre la Luna.",
		"color": Color(0.75, 0.75, 0.8),
		"personas": [
			{"id": "neil_armstrong", "nombre": "Neil Armstrong", "rol": "astronauta", "logro": "Primer ser humano en caminar sobre la Luna (Apolo 11, 20 de julio de 1969).", "por_que": "Su \"pequeño paso\" es uno de los momentos más famosos de la historia."},
			{"id": "buzz_aldrin", "nombre": "Buzz Aldrin", "rol": "astronauta", "logro": "Segundo ser humano en caminar sobre la Luna.", "por_que": "Experto en acoplamiento orbital, técnica clave para el viaje a la Luna."},
			{"id": "michael_collins", "nombre": "Michael Collins", "rol": "astronauta", "logro": "Piloto del módulo de mando Columbia del Apolo 11.", "por_que": "Orbitó la Luna solo, esperando para traer de regreso a sus compañeros."},
			{"id": "margaret_hamilton", "nombre": "Margaret Hamilton", "rol": "ingeniera", "logro": "Dirigió el equipo que escribió el software de vuelo del Apolo.", "por_que": "Su software evitó que se abortara el alunizaje del Apolo 11; ayudó a crear la \"ingeniería de software\"."},
			{"id": "gene_kranz", "nombre": "Gene Kranz", "rol": "ingeniero", "logro": "Director de vuelo durante el Apolo 11 y el Apolo 13.", "por_que": "Lideró el equipo que salvó a la tripulación del Apolo 13 en 1970."},
			{"id": "jim_lovell", "nombre": "Jim Lovell", "rol": "astronauta", "logro": "Voló en el Apolo 8 y fue comandante del Apolo 13.", "por_que": "Llevó a su tripulación de vuelta a casa tras la explosión del Apolo 13."},
			{"id": "frank_borman", "nombre": "Frank Borman", "rol": "astronauta", "logro": "Comandante del Apolo 8 (1968).", "por_que": "Su tripulación fue la primera en orbitar la Luna y ver la Tierra salir sobre el horizonte lunar."},
			{"id": "gene_cernan", "nombre": "Gene Cernan", "rol": "astronauta", "logro": "Último ser humano en caminar sobre la Luna (Apolo 17, 1972).", "por_que": "Cerró la era de los alunizajes del programa Apolo."},
			{"id": "harrison_schmitt", "nombre": "Harrison Schmitt", "rol": "cientifico", "logro": "Geólogo que caminó en la Luna con el Apolo 17.", "por_que": "Es el único científico profesional que ha pisado la Luna."},
			{"id": "james_webb", "nombre": "James E. Webb", "rol": "administrador", "logro": "Administrador de la NASA de 1961 a 1968.", "por_que": "Dirigió la NASA durante la preparación del Apolo; el telescopio James Webb lleva su nombre."},
		]
	},
	{
		"nombre": "Transbordador y sondas (1976-1995)",
		"descripcion": "Naves reutilizables, las primeras mujeres y minorías en el espacio, y sondas que exploran el Sistema Solar.",
		"color": Color(0.3, 0.6, 0.95),
		"personas": [
			{"id": "john_young", "nombre": "John Young", "rol": "astronauta", "logro": "Comandante del primer vuelo del transbordador (STS-1 Columbia, 1981).", "por_que": "Voló en Gemini, Apolo y el transbordador, y caminó en la Luna con el Apolo 16."},
			{"id": "sally_ride", "nombre": "Sally Ride", "rol": "astronauta", "logro": "Primera mujer estadounidense en el espacio (STS-7, 1983).", "por_que": "Inspiró a generaciones de niñas a estudiar ciencia."},
			{"id": "guion_bluford", "nombre": "Guion Bluford", "rol": "astronauta", "logro": "Primer afroamericano en el espacio (STS-8, 1983).", "por_que": "Abrió camino a astronautas afroamericanos."},
			{"id": "kathryn_sullivan", "nombre": "Kathryn Sullivan", "rol": "astronauta", "logro": "Primera estadounidense en caminar en el espacio (1984).", "por_que": "También ayudó a poner en órbita el telescopio Hubble (1990)."},
			{"id": "christa_mcauliffe", "nombre": "Christa McAuliffe", "rol": "educadora", "logro": "Maestra elegida para el programa \"Maestro en el Espacio\".", "por_que": "Murió en el accidente del Challenger (1986); su legado sigue inspirando a la educación científica."},
			{"id": "franklin_chang_diaz", "nombre": "Franklin Chang-Díaz", "rol": "astronauta", "logro": "Nacido en Costa Rica, voló 7 veces en el transbordador.", "por_que": "Comparte el récord de más vuelos en el transbordador e investiga motores de plasma."},
			{"id": "ellen_ochoa", "nombre": "Ellen Ochoa", "rol": "astronauta", "logro": "Primera mujer latina en el espacio (1993).", "por_que": "Después fue la primera directora latina del Centro Espacial Johnson."},
			{"id": "carl_sagan", "nombre": "Carl Sagan", "rol": "cientifico", "logro": "Científico de las misiones Viking y Voyager; ideó el Disco de Oro.", "por_que": "Pidió la foto \"Pálido Punto Azul\" y acercó la astronomía al público."},
		]
	}
]

const LUGARES_TEMPERATURA := [
	{
		"id": "sol", "nombre": "El Sol", "imagen": "res://assets/minijuegos/temperatura/sol.png",
		"temperatura": "Superficie: unos 5 500 °C · Corona: más de 1 000 000 °C",
		"mision": "Parker Solar Probe (lanzada en 2018)",
		"dato": "Es la nave que más se ha acercado al Sol: en diciembre de 2024 pasó a unos 6 millones de km. Su escudo térmico soporta cerca de 1 370 °C mientras los instrumentos detrás siguen a temperatura ambiente.",
		"planta": "Toda la energía de las plantas viene, al final, de la luz de una estrella como el Sol."
	},
	{
		"id": "venus", "nombre": "Venus", "imagen": "res://assets/minijuegos/temperatura/venus.png",
		"temperatura": "Superficie: unos 464 °C, de día y de noche",
		"mision": "Magellan (1990-1994) mapeó Venus con radar",
		"dato": "Es el planeta más caliente aunque Mercurio está más cerca del Sol: su atmósfera de CO₂ atrapa el calor (efecto invernadero extremo). La presión es unas 90 veces la de la Tierra.",
		"planta": "Ninguna planta sobreviviría: por eso tu módulo necesita control térmico."
	},
	{
		"id": "luna", "nombre": "La Luna", "imagen": "res://assets/minijuegos/temperatura/luna.png",
		"temperatura": "Día: unos +120 °C · Noche: unos −130 °C · Cráteres polares: cerca de −240 °C",
		"mision": "Lunar Reconnaissance Orbiter (2009-hoy)",
		"dato": "El instrumento Diviner del LRO encontró en los cráteres de los polos, que nunca reciben luz, algunos de los lugares más fríos medidos en el Sistema Solar. Allí podría haber hielo de agua.",
		"planta": "Un invernadero lunar necesita aislamiento y calefacción para soportar el cambio de casi 250 °C entre el día y la noche."
	},
	{
		"id": "marte", "nombre": "Marte", "imagen": "res://assets/minijuegos/temperatura/marte.png",
		"temperatura": "Promedio: unos −60 °C · De unos 20 °C en el ecuador de día a −125 °C en los polos",
		"mision": "Rover Curiosity (2012-hoy), con su estación meteorológica REMS",
		"dato": "Su atmósfera es muy delgada (alrededor del 1 % de la terrestre) y no retiene el calor: la temperatura puede bajar decenas de grados en una sola noche.",
		"planta": "Los futuros huertos en Marte estarán en módulos cerrados y calefaccionados, como el de este juego."
	},
	{
		"id": "europa", "nombre": "Europa (luna de Júpiter)", "imagen": "res://assets/minijuegos/temperatura/europa.png",
		"temperatura": "Superficie: unos −160 °C en el ecuador y hasta −220 °C en los polos",
		"mision": "Europa Clipper (lanzada en octubre de 2024, llegará a Júpiter en 2030)",
		"dato": "Bajo su corteza de hielo, llena de grietas rojizas, habría un océano de agua líquida con más agua que todos los océanos de la Tierra.",
		"planta": "Es uno de los mejores lugares para buscar vida: donde hay agua líquida, energía y química, la vida podría existir."
	},
]

const INFO_ALIENIGENAS := "[b]¿Qué dice la NASA sobre los extraterrestres?[/b]\n\n[color=#9be7a1][b]Todavía no hay pruebas de vida extraterrestre.[/b][/color] La NASA la busca con ciencia, no con platillos voladores.\n\n[b]Ovnis (UAP), 2023:[/b] un equipo independiente de la NASA estudió los \"fenómenos anómalos no identificados\" y el 14 de septiembre de 2023 concluyó que no había pruebas de que tuvieran origen extraterrestre. La mayoría eran globos, aviones, satélites o errores de los sensores.\n\n[b]La mejor pista hasta ahora:[/b] el 10 de septiembre de 2025 la NASA anunció que una muestra de roca de Marte llamada \"Sapphire Canyon\", tomada por el rover Perseverance, contiene una \"posible biosignatura\": manchas tipo leopardo que podrían venir de microbios antiguos. Los científicos aclaran que NO es una prueba de vida y que hay que seguir estudiándola.\n\n[b]¿Dónde buscan?[/b] En Marte, en océanos escondidos bajo el hielo de lunas como Europa y Encélado, y en la atmósfera de planetas de otras estrellas con el telescopio James Webb.\n\n[i]Los alienígenas de este minijuego son pura ficción... ¡no golpees a los astronautas![/i]"
