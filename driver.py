import sys
from clips import Environment, Symbol

env = Environment()
print("✅ Entorno CLIPS inicializado.")

try:
    env.load("control_modulo.clp")
    print("✅ Fichero de control (reglas y templates) cargado.")
except Exception as e:
    print(f"❌ Error al cargar 'control_centro_datos.clp': {e}")
    exit(1)

try:
    env.load("datacenter_facts.clp")
    print("✅ Fichero de infraestructura (hechos iniciales) cargado.")
except Exception as e:
    print(f"❌ Error al cargar 'infraestructura_dc.clp': {e}")
    exit(1)

env.reset()
print("🔄 Entorno reseteado (Hechos iniciales cargados).")
print("-" * 70)

template_sensor_zona = env.find_template('sensor-zona')
template_sensor_rack = env.find_template('sensor-rack')
template_evento = env.find_template('evento')

linea_temporal_simulacion = [
    {
        "descripcion": "Estado normal. Sensores en rangos ideales.",
        "sensores_zona": [
            ("Z1-General", "temperatura", 22.0),
            ("Z2-Racks-A", "temperatura", 23.0),
            ("Z2-Racks-B", "temperatura", 25.0),
            ("Z1-General", "humedad", 50.0),
            ("Z2-Racks-A", "humedad", 50.0),
            ("Z3-Racks-B", "humedad", 47.0),
            ("Z1-General", "humo", "inactivo"),
            ("Z2-Racks-A", "humo", "inactivo"),
            ("Z3-Racks-B", "humo", "inactivo"),
        ],
        "sensores_rack": [
            ("RACK-A1", "temperatura", 30.0),
            ("RACK-A1", "voltaje", 220.0),
            ("RACK-B1", "voltaje", 225.0),
        ],
        "eventos": []
    },
    {
        "descripcion": "CONTROL DE ACCESO ZONA GENERAL (Válido) e ILUMINACIÓN (On)",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-acceso", "tecnico01", "Z1-General") 
        ]
    },
    {
        "descripcion": "CONTROL DE ACCESO ZONA RESTRINGIDA (Denegado) Y ALERTA",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-acceso", "visitante01", "Z2-Racks-A") 
        ]
    },
    {
        "descripcion": "CONTROL DE ACCESO ZONA GENERAL (Válido)",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-acceso", "visitante01", "Z1-General") 
        ]
    },
    {
        "descripcion": "CONTROL DE ACCESO ZONA RESTRINGIDA (Válido)",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-acceso", "admin01", "Z2-Racks-A") 
        ]
    },
    {
        "descripcion": "CONTROL DE ACCESO ZONA GENERAL A USUARIO CON NIVEL DE ACCESO RESTRINGIDO (Válido)",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-acceso", "dir01", "Z1-General") 
        ]
    },
    {
        "descripcion": "CONTROL DE NIVEL DE TEMPERATURA EN ZONAS",
        "sensores_zona": [
            ("Z1-General", "temperatura", 10.5), 
            ("Z2-Racks-A", "temperatura", 18),
            ("Z3-Racks-B", "temperatura", 28)
        ],
        "sensores_rack": [],
        "eventos": []
    },
    {
        "descripcion": "CONTROL DE TEMPERATURA EN RACKS Y ALERTAS",
        "sensores_zona": [],
        "sensores_rack": [
            ("RACK-A1", "temperatura", 45.1), 
            ("RACK-A2", "temperatura", 35),
            ("RACK-B1", "temperatura", 10)
        ],
        "eventos": []
    },
    {
        "descripcion": "CONTROL DE ACCESO (Salida)",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-salida", "visitante01", "Z1-General") 
        ]
    },
    {
        "descripcion": "DETECCIÓN DE DESASTRES (¡¡Incendio en zona NORMAL y CON gente!!)",
        "sensores_zona": [
             ("Z1-General", "humo", "activo") 
        ],
        "sensores_rack": [],
        "eventos": []
    },
    {
        "descripcion": "DETECCIÓN DE DESASTRES (¡¡Incendio en zona SENSIBLE y SIN gente!!)",
        "sensores_zona": [
             ("Z3-Racks-B", "humo", "activo") 
        ],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-salida", "tecnico01", "Z1-General"),
            ("solicitud-salida", "dir01", "Z1-General")
        ]
    },
    {
        "descripcion": "DETECCIÓN DE DESASTRES (¡¡Incendio en zona NORMAL y SIN gente!!)",
        "sensores_zona": [
             ("Z1-General", "humo", "activo") 
        ],
        "sensores_rack": [],
        "eventos": []
    },
    {
        "descripcion": "DETECCIÓN DE DESASTRES (¡¡Incendio en zona SENSIBLE y CON gente!!)",
        "sensores_zona": [
             ("Z2-Racks-A", "humo", "activo") 
        ],
        "sensores_rack": [],
        "eventos": []
    },
    {
        "descripcion": "MONITORIZACIÓN Y CONTROL DE HUMEDAD EN ZONAS",
        "sensores_zona": [
             ("Z1-General", "humedad", 35.0),
             ("Z2-Racks-A", "humedad", 65.0),
             ("Z3-Racks-B", "humedad", 50.0)
        ],
        "sensores_rack": [],
        "eventos": []
    },
    {
        "descripcion": "MONITORIZACIÓN Y CONTROL DE VOLTAJES EN RACKS",
        "sensores_zona": [],
        "sensores_rack": [
            ("RACK-A1", "voltaje", 205),
            ("RACK-A2", "voltaje", 225),
            ("RACK-B1", "voltaje", 240)
            
        ],
        "eventos": []
    },
    {
        "descripcion": "ZONAS LIBRES Y FINALIZACIÓN DE LA SIMULACIÓN",
        "sensores_zona": [],
        "sensores_rack": [],
        "eventos": [
            ("solicitud-salida", "admin01", "Z2-Racks-A")
        ]
    }
]

for i, escenario in enumerate(linea_temporal_simulacion, 1):
    print(f"\n{'='*70}")
    print(f"▶️  INICIO TICK {i}: {escenario['descripcion']}")
    print(f"{'='*70}")

    print("   ... Limpiando hechos dinámicos (sensores, acciones, alertas)...")
    facts_to_retract = []
    for fact in env.facts():
        tpl_name = fact.template.name
        if tpl_name in ["sensor-zona", "sensor-rack", "accion", "alerta"]:
            facts_to_retract.append(fact)
            
    for fact in facts_to_retract:
        fact.retract()

    print("   ... Cargando nuevos sensores y eventos...")
    
    for (zona, tipo, valor) in escenario["sensores_zona"]:
        template_sensor_zona.assert_fact(zona=zona, tipo=Symbol(tipo), valor=valor)

    for (rack, tipo, valor) in escenario["sensores_rack"]:
        template_sensor_rack.assert_fact(rack=rack, tipo=Symbol(tipo), valor=valor)
        
    for (tipo, usuario, zona) in escenario["eventos"]:
        template_evento.assert_fact(tipo=Symbol(tipo), usuario=usuario, zona=zona)

    print("\n   📥 HECHOS DE ENTRADA (Estado para procesar):")
    input_facts_found = False
    for fact in env.facts():
        tpl_name = fact.template.name
        if tpl_name == "estado-zona":
            print(f"     🏠 [Estado] Zona: {fact['nombre']}, Personas: {fact['personas-dentro']}")
            input_facts_found = True
        elif tpl_name == "sensor-zona":
            print(f"     🌡️ [Sensor-Zona] Zona: {fact['zona']}, Tipo: {fact['tipo']}, Valor: {fact['valor']}")
            input_facts_found = True
        elif tpl_name == "sensor-rack":
            print(f"     🖥️ [Sensor-Rack] Rack: {fact['rack']}, Tipo: {fact['tipo']}, Valor: {fact['valor']}")
            input_facts_found = True
        elif tpl_name == "evento":
            print(f"     👤 [Evento] Tipo: {fact['tipo']}, Usuario: {fact['usuario']}, Zona: {fact['zona']}")
            input_facts_found = True
    
    if not input_facts_found:
        print("     (No hay hechos de estado, sensores o eventos activos en este tick)")

    print("\n   🚀 Ejecutando motor de reglas...")
    env.run()

    print("\n   📋 RESULTADOS GENERADOS (Tick {}):".format(i))
    
    acciones = []
    alertas = []

    for fact in env.facts():
        if fact.template.name == "accion":
            comando_lista = [str(slot) for slot in fact['comando']]
            acciones.append(comando_lista)
        elif fact.template.name == "alerta":
            alertas.append({
                "tipo": str(fact['tipo']),
                "item": str(fact['item']),
                "mensaje": str(fact['mensaje'])
            })

    if not acciones and not alertas:
        print("     ✅  (Sin acciones ni alertas nuevas)")
    else:
        acciones.sort(key=lambda x: 1 if x[0] == 'luz' else 0)
        
        for a in alertas:
            print(f"     ❗️ ALERTA ({a['tipo'].upper()}): {a['mensaje']} (Item: {a['item']})")
        for a in acciones:
            print(f"     ⚙️  ACCION: {a}")

    print("\n   📊 ESTADO PERSISTENTE (al final del Tick {}):".format(i))
    for fact in env.facts():
        if fact.template.name == "estado-zona":
            print(f"     🏠 Zona: {fact['nombre']}, Personas: {fact['personas-dentro']}")

    print(f"⏹️  FIN TICK {i}")


print("\n" + "="*70)
print("✅ PROCESO DE SIMULACIÓN CONTINUA COMPLETADO.")
print("="*70)