;; ======== 1. DEFINICIÓN DE TEMPLATES ========

(deftemplate zona
  (slot nombre (type STRING))
  (slot nivel-acceso (type SYMBOL) (allowed-symbols general restringido))
  (slot contenido (type SYMBOL) (allowed-symbols normal sensible))
  (slot temp-ideal-min (type FLOAT))
  (slot temp-ideal-max (type FLOAT))
  (slot humedad-ideal-min (type FLOAT)) 
  (slot humedad-ideal-max (type FLOAT))) 

(deftemplate rack
  (slot nombre (type STRING))
  (slot zona (type STRING))
  (slot temp-ideal-min (type FLOAT))
  (slot temp-ideal-max (type FLOAT)))

(deftemplate usuario
  (slot nombre (type STRING))
  (slot nivel-acceso (type SYMBOL) (allowed-symbols general restringido)))

(deftemplate estado-zona
  (slot nombre (type STRING))
  (slot personas-dentro (type INTEGER) (default 0)))

(deftemplate sensor-zona
  (slot zona (type STRING))
  (slot tipo (type SYMBOL) (allowed-symbols temperatura humo humedad))
  (slot valor))

(deftemplate sensor-rack
  (slot rack (type STRING))
  (slot tipo (type SYMBOL) (allowed-symbols temperatura voltaje))
  (slot valor))

(deftemplate evento
  (slot tipo (type SYMBOL) (allowed-symbols solicitud-acceso solicitud-salida))
  (slot usuario (type STRING))
  (slot zona (type STRING)))

(deftemplate accion
  (multislot comando)) 

(deftemplate alerta
  (slot tipo (type SYMBOL) (allowed-symbols acceso-denegado rack-caliente rack-frio critica-incendio voltaje-alto voltaje-bajo))
  (slot item (type STRING))
  (slot mensaje (type STRING)))

;; ======== 2. DEFINICIÓN DE VARIABLES GLOBALES ========

(defglobal ?*VOLTAJE_MIN* = 210.0)
(defglobal ?*VOLTAJE_MAX* = 230.0)

;; ======== 3. DEFINICIÓN DE REGLAS ========

;; --- Control de Accesos ---

(defrule permitir-acceso-restringido
  "Usuario 'restringido' accede a CUALQUIER zona (general o restringida)"
  ?f_evt <- (evento (tipo solicitud-acceso) (usuario ?u) (zona ?z))
  (usuario (nombre ?u) (nivel-acceso restringido))
  (zona (nombre ?z) (nivel-acceso ?nivel-zona&:(or (eq ?nivel-zona restringido) (eq ?nivel-zona general))))
  ?f_est <- (estado-zona (nombre ?z) (personas-dentro ?p))
  =>
  (assert (accion (comando abrir-puerta ?z)))
  (modify ?f_est (personas-dentro (+ ?p 1)))
  (retract ?f_evt))

(defrule permitir-acceso-general
  "Usuario 'general' accede a zona 'general'"
  ?f_evt <- (evento (tipo solicitud-acceso) (usuario ?u) (zona ?z))
  (usuario (nombre ?u) (nivel-acceso general))
  (zona (nombre ?z) (nivel-acceso general))
  ?f_est <- (estado-zona (nombre ?z) (personas-dentro ?p))
  =>
  (assert (accion (comando abrir-puerta ?z)))
  (modify ?f_est (personas-dentro (+ ?p 1)))
  (retract ?f_evt))

(defrule denegar-acceso-general-a-restringido
  "Usuario 'general' NO accede a zona 'restringida'"
  ?f_evt <- (evento (tipo solicitud-acceso) (usuario ?u) (zona ?z))
  (usuario (nombre ?u) (nivel-acceso general))
  (zona (nombre ?z) (nivel-acceso restringido))
  =>
  (assert (alerta (tipo acceso-denegado) 
                  (item ?u) 
                  (mensaje (str-cat "Acceso denegado a " ?u " en zona restringida " ?z))))
  (retract ?f_evt))

(defrule permitir-salida
  "Cualquier usuario sale de cualquier zona"
  ?f_evt <- (evento (tipo solicitud-salida) (usuario ?u) (zona ?z))
  ?f_est <- (estado-zona (nombre ?z) (personas-dentro ?p&:(> ?p 0)))
  =>
  (assert (accion (comando abrir-puerta ?z)))
  (modify ?f_est (personas-dentro (- ?p 1)))
  (retract ?f_evt))

;; --- Control de Climatización de Zonas ---

; --- REGLAS DE CALEFACCIÓN ---

(defrule calefaccion-intensidad-baja
  (zona (nombre ?z) (temp-ideal-min ?min))
  (sensor-zona (zona ?z) (tipo temperatura) (valor ?t&:(< ?t ?min)
                                               &:(>= (round (- ?min ?t)) 1)
                                               &:(<= (round (- ?min ?t)) 3)))
  =>
  (bind ?dif (round (- ?min ?t)))
  (assert (accion (comando calefaccion ?z "on" "intensidad-baja" (str-cat "+" ?dif "C")))))
  
(defrule calefaccion-intensidad-media
  (zona (nombre ?z) (temp-ideal-min ?min))
  (sensor-zona (zona ?z) (tipo temperatura) (valor ?t&:(< ?t ?min)
                                               &:(>= (round (- ?min ?t)) 4)
                                               &:(<= (round (- ?min ?t)) 7)))
  =>
  (bind ?dif (round (- ?min ?t)))
  (assert (accion (comando calefaccion ?z "on" "intensidad-media" (str-cat "+" ?dif "C")))))

(defrule calefaccion-intensidad-alta
  (zona (nombre ?z) (temp-ideal-min ?min))
  (sensor-zona (zona ?z) (tipo temperatura) (valor ?t&:(< ?t ?min)
                                               &:(>= (round (- ?min ?t)) 8)))
  =>
  (bind ?dif (round (- ?min ?t)))
  (assert (accion (comando calefaccion ?z "on" "intensidad-alta" (str-cat "+" ?dif "C")))))

; --- REGLAS DE AIRE ACONDICIONADO ---

(defrule aire-acondicionado-intensidad-baja
  (zona (nombre ?z) (temp-ideal-max ?max))
  (sensor-zona (zona ?z) (tipo temperatura) (valor ?t&:(> ?t ?max)
                                               &:(>= (round (- ?t ?max)) 1)
                                               &:(<= (round (- ?t ?max)) 3)))
  =>
  (bind ?dif (round (- ?t ?max)))
  (assert (accion (comando aire-acondicionado ?z "on" "intensidad-baja" (str-cat "-" ?dif "C")))))

(defrule aire-acondicionado-intensidad-media
  (zona (nombre ?z) (temp-ideal-max ?max))
  (sensor-zona (zona ?z) (tipo temperatura) (valor ?t&:(> ?t ?max)
                                               &:(>= (round (- ?t ?max)) 4)
                                               &:(<= (round (- ?t ?max)) 7)))
  =>
  (bind ?dif (round (- ?t ?max)))
  (assert (accion (comando aire-acondicionado ?z "on" "intensidad-media" (str-cat "-" ?dif "C")))))

(defrule aire-acondicionado-intensidad-alta
  (zona (nombre ?z) (temp-ideal-max ?max))
  (sensor-zona (zona ?z) (tipo temperatura) (valor ?t&:(> ?t ?max)
                                               &:(>= (round (- ?t ?max)) 8)))
  =>
  (bind ?dif (round (- ?t ?max)))
  (assert (accion (comando aire-acondicionado ?z "on" "intensidad-alta" (str-cat "-" ?dif "C")))))

;; --- Monitorización de Temperatura de Racks ---

(defrule rack-sobrecalentado
  (rack (nombre ?r) (temp-ideal-max ?max))
  (sensor-rack (rack ?r) (tipo temperatura) (valor ?t&:(> ?t ?max)))
  =>
  (assert (alerta (tipo rack-caliente) (item ?r) (mensaje (str-cat "Rack " ?r " sobrecalentado (" ?t "C)")))))

(defrule rack-demasiado-frio
  (rack (nombre ?r) (temp-ideal-min ?min))
  (sensor-rack (rack ?r) (tipo temperatura) (valor ?t&:(< ?t ?min)))
  =>
  (assert (alerta (tipo rack-frio) (item ?r) (mensaje (str-cat "Rack " ?r " demasiado frio (" ?t "C)")))))

;; --- Detección de Desastres ---

; Caso 1: Incendio CON gente, contenido SENSIBLE. Alerta crítica
(defrule incendio-con-gente-contenido-sensible
  (sensor-zona (zona ?z) (tipo humo) (valor "activo"))
  (estado-zona (nombre ?z) (personas-dentro ?p&:(> ?p 0)))
  (zona (nombre ?z) (contenido sensible))
  =>
  (assert (alerta (tipo critica-incendio) (item ?z) (mensaje (str-cat "¡¡INCENDIO EN " ?z " CON " ?p " PERSONAS DENTRO!!"))))
  (assert (accion (comando megafonia (str-cat "¡¡INCENDIO DETECTADO EN " ?z "! EVACUACION INMEDIATA DE LA ZONA " ?z "!!")))))

; Caso 2: Incendio SIN gente, contenido NORMAL. Se puede usar agua.
(defrule incendio-sin-gente-contenido-normal
  (sensor-zona (zona ?z) (tipo humo) (valor "activo"))
  (estado-zona (nombre ?z) (personas-dentro 0))
  (zona (nombre ?z) (contenido normal))
  =>
  (assert (accion (comando activar-extincion ?z "agua")))
  (assert (accion (comando megafonia (str-cat "Incendio en " ?z ". Activando extincion por agua.")))))

; Caso 3: Incendio SIN gente, contenido SENSIBLE. Se debe usar gas.
(defrule incendio-sin-gente-contenido-sensible
  (sensor-zona (zona ?z) (tipo humo) (valor "activo"))
  (estado-zona (nombre ?z) (personas-dentro 0))
  (zona (nombre ?z) (contenido sensible))
  =>
  (assert (accion (comando activar-extincion ?z "gas")))
  (assert (accion (comando megafonia (str-cat "Incendio en " ?z ". Activando extincion por gas.")))))

; Caso 4: Incendio CON gente, contenido NORMAL. Se puede usar agua.
(defrule incendio-con-gente-contenido-normal
  (sensor-zona (zona ?z) (tipo humo) (valor "activo"))
  (estado-zona (nombre ?z) (personas-dentro ?p&:(> ?p 0)))
  (zona (nombre ?z) (contenido normal))
  =>
  (assert (accion (comando activar-extincion ?z "agua")))
  (assert (accion (comando megafonia (str-cat "Incendio en " ?z ". Activando extincion por agua.")))))

;; --- Control de Iluminación ---
(defrule encender-luz-con-presencia
  (estado-zona (nombre ?z) (personas-dentro ?p&:(> ?p 0)))
  =>
  (assert (accion (comando luz ?z "on"))))

(defrule apagar-luz-sin-presencia
  (estado-zona (nombre ?z) (personas-dentro 0))
  =>
  (assert (accion (comando luz ?z "off"))))
  
;; --- Control de Humedad ---
(defrule zona-muy-humeda
  (zona (nombre ?z) (humedad-ideal-max ?max))
  (sensor-zona (zona ?z) (tipo humedad) (valor ?h&:(> ?h ?max)))
  =>
  (assert (accion (comando ventilador ?z "on")))
  (assert (accion (comando ajustar-clima ?z "deshumidificar"))))

(defrule zona-muy-seca
  (zona (nombre ?z) (humedad-ideal-min ?min))
  (sensor-zona (zona ?z) (tipo humedad) (valor ?h&:(< ?h ?min)))
  =>
  (assert (accion (comando ajustar-clima ?z "humidificar"))))
  
;; --- Control de Voltaje en Racks ---
(defrule rack-voltaje-alto
  (sensor-rack (rack ?r) (tipo voltaje) (valor ?v&:(> ?v ?*VOLTAJE_MAX*)))
  =>
  (assert (alerta (tipo voltaje-alto) (item ?r) (mensaje (str-cat "Rack " ?r " con sobretension (" ?v "V)")))))

(defrule rack-voltaje-bajo
  (sensor-rack (rack ?r) (tipo voltaje) (valor ?v&:(< ?v ?*VOLTAJE_MIN*)))
  =>
  (assert (alerta (tipo voltaje-bajo) (item ?r) (mensaje (str-cat "Rack " ?r " con baja tension (" ?v "V)")))))