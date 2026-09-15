;; ============================================================   
;;                Definición de HECHOS INICIALES 
;; ============================================================

(deffacts descripcion-centro-datos
  
  ;; --- Definición de Zonas ---
  
  (zona (nombre "Z1-General") 
        (nivel-acceso general) 
        (contenido normal) 
        (temp-ideal-min 18.0) 
        (temp-ideal-max 27.0)
        (humedad-ideal-min 40.0) 
        (humedad-ideal-max 60.0)) 
        
  (zona (nombre "Z2-Racks-A") 
        (nivel-acceso restringido) 
        (contenido sensible) 
        (temp-ideal-min 20.0) 
        (temp-ideal-max 25.0)
        (humedad-ideal-min 45.0) 
        (humedad-ideal-max 55.0)) 

  (zona (nombre "Z3-Racks-B") 
        (nivel-acceso restringido) 
        (contenido sensible) 
        (temp-ideal-min 20.0) 
        (temp-ideal-max 25.0)
        (humedad-ideal-min 45.0) 
        (humedad-ideal-max 55.0))  

  ;; --- Definición de Racks ---
  
  (rack (nombre "RACK-A1") 
        (zona "Z2-Racks-A") 
        (temp-ideal-min 15.0) 
        (temp-ideal-max 40.0))
        
  (rack (nombre "RACK-A2") 
        (zona "Z2-Racks-A") 
        (temp-ideal-min 15.0) 
        (temp-ideal-max 40.0))
        
  (rack (nombre "RACK-B1") 
        (zona "Z3-Racks-B") 
        (temp-ideal-min 15.0) 
        (temp-ideal-max 40.0))

  ;; --- Definición de Usuarios ---

  (usuario (nombre "dir01")
            (nivel-acceso restringido))
  
  (usuario (nombre "admin01") 
           (nivel-acceso restringido))
           
  (usuario (nombre "tecnico01") 
           (nivel-acceso general))
           
  (usuario (nombre "visitante01") 
           (nivel-acceso general))
           
  ;; --- Estado Inicial de Zonas ---
  
  (estado-zona (nombre "Z1-General") (personas-dentro 0))
  (estado-zona (nombre "Z2-Racks-A") (personas-dentro 0))
  (estado-zona (nombre "Z3-Racks-B") (personas-dentro 0))
)