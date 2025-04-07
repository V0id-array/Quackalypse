#!/bin/bash

#=============================================
# VARIABLES GLOBALES
#=============================================

# Emojis de comida que se guardarán en el archivo oculto
FOOD_EMOJIS="🫛🫛🫛🫛🫛"

# Variables para rutas y comandos
DESKTOP_PATH="/tmp"
HIDDEN_FILE="/tmp/.comida_patos.txt"

# Directorio temporal para archivos auxiliares
TEMP_DIR="/tmp/duck_ctf_$$"
LOG_FILE="$TEMP_DIR/duck_ctf.log"
PID_FILE="$TEMP_DIR/viewer_pid.txt"
IMAGES_DIR="$TEMP_DIR/images"

# URLs de GIFs (usando URLs directas y confiables)
GIF_URL="https://c.tenor.com/-t1oo-r1fp0AAAAd/tenor.gif"
VICTORY_GIF_URL="https://github.com/V0id-array/Quackalypse/blob/main/victory.gif?raw=true"

# Rutas locales de los GIFs descargados
DUCK_GIF="$IMAGES_DIR/angry_duck.gif"
VICTORY_GIF="$IMAGES_DIR/victory.gif"

# Variables para control de procesos
MONITOR_ACTIVE=false

#=============================================
# FUNCIONES
#=============================================

# Función para configurar el entorno inicial
setup() {
    mkdir -p "$TEMP_DIR"
    mkdir -p "$IMAGES_DIR"
    echo "Iniciando CTF de Patos Hambrientos $(date)" > "$LOG_FILE"
    VIEWER_CMD="gwenview"
    echo "Visualizador seleccionado: $VIEWER_CMD" >> "$LOG_FILE"
    echo "Directorio temporal: $TEMP_DIR" >> "$LOG_FILE"
    #echo "Archivo oculto: $HIDDEN_FILE" >> "$LOG_FILE"
}

# Función para crear el archivo oculto con emojis
crear_archivo_oculto() {
    echo "Creando archivo oculto con emojis de comida..." >> "$LOG_FILE"
    #echo "$FOOD_EMOJIS" > "$HIDDEN_FILE"
    #echo "Archivo oculto creado en: $HIDDEN_FILE" >> "$LOG_FILE"
    
    # Mostrar pista explícita
}

# Función para descargar GIFs
descargar_gifs() {
    echo "Descargando GIFs..." >> "$LOG_FILE"
    
    # Descargar GIF de pato enfadado
    echo "Descargando GIF de pato enfadado desde $GIF_URL" >> "$LOG_FILE"
    wget -q "$GIF_URL" -O "$DUCK_GIF"
    if [ $? -ne 0 ]; then
        echo "Error al descargar el GIF de pato enfadado" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Descargar GIF de victoria
    echo "Descargando GIF de victoria desde $VICTORY_GIF_URL" >> "$LOG_FILE"
    wget -q "$VICTORY_GIF_URL" -O "$VICTORY_GIF"
    if [ $? -ne 0 ]; then
        echo "Error al descargar el GIF de victoria" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Verificar que los archivos existen y tienen tamaño
    if [ ! -s "$DUCK_GIF" ] || [ ! -s "$VICTORY_GIF" ]; then
        echo "Error: Uno o más GIFs están vacíos o no existen." | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "GIFs descargados correctamente" >> "$LOG_FILE"
    return 0
}

# Función para abrir una ventana con el GIF
abrir_ventana() {
    echo "Abriendo ventana de pato enfadado..." >> "$LOG_FILE"
    
    # Verificar que el archivo existe
    if [ ! -f "$DUCK_GIF" ]; then
        echo "El archivo $DUCK_GIF no existe. Intentando descargar de nuevo..." >> "$LOG_FILE"
        wget -q "$GIF_URL" -O "$DUCK_GIF"
        if [ $? -ne 0 ] || [ ! -s "$DUCK_GIF" ]; then
            echo "Error al descargar el GIF. No se pudo abrir ventana." | tee -a "$LOG_FILE"
            return 1
        fi
    fi
    
    # Cerrar ventanas antiguas primero
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Cerrando ventana anterior con PID: $pid" >> "$LOG_FILE"
            kill "$pid" 2>/dev/null
            sleep 1
        fi
    fi
    
    # Limpiar archivo de PID
    > "$PID_FILE"
    
    # Abrir el GIF con el programa adecuado
    DISPLAY=:0 $VIEWER_CMD "$DUCK_GIF" >> "$LOG_FILE" 2>&1 &
    VIEWER_PID=$!
    echo $VIEWER_PID > "$PID_FILE"
    
    echo "Ventana abierta con PID: $VIEWER_PID usando $VIEWER_CMD" >> "$LOG_FILE"
    sleep 1  # Esperar a que la ventana se abra completamente
}

# Función para monitorear la ventana (simplificada para evitar bucles)
monitorear_ventana() {
    echo "Iniciando monitoreo de ventana..." >> "$LOG_FILE"
    
    if [ "$MONITOR_ACTIVE" = true ]; then
        echo "El monitoreo ya está activo, omitiendo." >> "$LOG_FILE"
        return
    fi
    
    MONITOR_ACTIVE=true
    
    (
        # Número máximo de reaperturas para evitar bucles infinitos
        max_reopen=3
        reopen_count=0
        
        while [ $reopen_count -lt $max_reopen ]; do
            sleep 1  # Verificar con menos frecuencia
            
            # Cargar PID desde el archivo
            if [ -f "$PID_FILE" ]; then
                VIEWER_PID=$(cat "$PID_FILE")
            else
                VIEWER_PID=""
            fi
            
            # Verificar si el proceso existe
            if [ -z "$VIEWER_PID" ] || ! ps -p "$VIEWER_PID" > /dev/null 2>&1; then
                echo "Ventana cerrada. Intentando reabrir (intento $((reopen_count+1))/$max_reopen)..." >> "$LOG_FILE"
                abrir_ventana
                ((reopen_count++))
            else
                echo "Ventana aún abierta (PID: $VIEWER_PID)" >> "$LOG_FILE"
            fi
        done
        
        echo "Monitor alcanzó el máximo de reaperturas. Finalizando monitoreo." >> "$LOG_FILE"
    ) &
    
    # Guardar el PID del monitor
    MONITOR_PID=$!
    echo $MONITOR_PID > "$TEMP_DIR/monitor_pid.txt"
    echo "Proceso de monitoreo iniciado con PID: $MONITOR_PID" >> "$LOG_FILE"
}

# Función para mostrar la pantalla de victoria
mostrar_victoria() {
    echo "¡Felicidades! Has alimentado al pato hambriento." | tee -a "$LOG_FILE"
    
    # Detener el proceso de monitoreo
    if [ -f "$TEMP_DIR/monitor_pid.txt" ]; then
        monitor_pid=$(cat "$TEMP_DIR/monitor_pid.txt")
        if ps -p "$monitor_pid" > /dev/null 2>&1; then
            kill "$monitor_pid" 2>/dev/null
            echo "Proceso de monitoreo terminado." >> "$LOG_FILE"
        fi
    fi
    
    # Cerrar la ventana del pato enfadado
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Cerrando ventana de pato enfadado" >> "$LOG_FILE"
            kill "$pid" 2>/dev/null
            sleep 2
        fi
    fi
    
    echo "Felicidades aquí tienes la flag: " | tee -a "$LOG_FILE"
    
    # Intentar mostrar el GIF de victoria
    if [ -f "$VICTORY_GIF" ] && [ -s "$VICTORY_GIF" ]; then
        echo "Abriendo GIF de victoria..." >> "$LOG_FILE"
        DISPLAY=:0 $VIEWER_CMD "$VICTORY_GIF" >> "$LOG_FILE" 2>&1 &
        echo "GIF de victoria abierto." >> "$LOG_FILE"
    else
        echo "No se pudo mostrar el GIF de victoria, pero has completado el reto." | tee -a "$LOG_FILE"
    fi
    
    sleep 3  # Esperar para mostrar la victoria
}

# Función para solicitar la comida (corregida para evitar bucles)
solicitar_comida() {
    echo "Solicitando comida para el pato..." >> "$LOG_FILE"
    
    echo "¡Los patos están hambrientos, han olido comida en tu ordenador, encuéntrala y dasela"
    echo "Pega aquí la lista de comida que encontraste (o escribe 'salir' para terminar):"
    
    while true; do
        # Mostrar contenido del archivo oculto en el log para depuración
       #if [ -f "$HIDDEN_FILE" ]; then
         #   echo "Contenido actual del archivo oculto: $(cat "$HIDDEN_FILE")" >> "$LOG_FILE"
        #fi
        
        # Leer la entrada del usuario explícitamente
        read -r respuesta
        
        # Opción para salir
        if [ "$respuesta" = "salir" ]; then
            echo "Has decidido salir. El pato sigue hambriento." >> "$LOG_FILE"
            return 1
        fi
        
        # Si respuesta está vacía, pedirla de nuevo
        if [ -z "$respuesta" ]; then
            echo "No has escrito nada. Intenta de nuevo."
            continue
        fi
        
        # Verificar respuesta
        if [ "$respuesta" = "$FOOD_EMOJIS" ]; then
            echo "¡Correcto! Al pato le encanta esa comida." >> "$LOG_FILE"
            mostrar_victoria
            return 0
        else
            echo "Esa no es la comida correcta. El pato sigue hambriento." >> "$LOG_FILE"
            echo "El pato no parece querer eso... Intenta de nuevo."
            echo "¡El pato ha encontrado comida en tu ordenador y la quiere!"
            echo "Pega aquí la lista de comida que encontraste (o escribe 'salir' para terminar):"
        fi
    done
}

# Función para limpiar recursos al terminar
limpiar() {
    echo "Limpiando recursos..." >> "$LOG_FILE"
    
    # Detener el monitoreo
    if [ -f "$TEMP_DIR/monitor_pid.txt" ]; then
        monitor_pid=$(cat "$TEMP_DIR/monitor_pid.txt")
        if ps -p "$monitor_pid" > /dev/null 2>&1; then
            kill "$monitor_pid" 2>/dev/null
            echo "Proceso de monitoreo terminado." >> "$LOG_FILE"
        fi
    fi
    
    # Cerrar visualizador
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Cerrando visualizador con PID: $pid" >> "$LOG_FILE"
            kill "$pid" 2>/dev/null
        fi
    fi
    
    # Intentar cerrar programas específicos que podrían estar abiertos
    for prog in firefox mpv gimp; do
        if pgrep $prog > /dev/null; then
            pkill $prog 2>/dev/null
            echo "Intentando cerrar $prog" >> "$LOG_FILE"
        fi
    done
    
    echo "CTF finalizado: $(date)" >> "$LOG_FILE"
}

#=============================================
# MANEJO DE SEÑALES
#=============================================
trap 'echo "Programa interrumpido"; limpiar; exit 1' SIGINT SIGTERM

#=============================================
# PROGRAMA PRINCIPAL
#=============================================
main() {
    setup
    crear_archivo_oculto
    if descargar_gifs; then
        abrir_ventana
        monitorear_ventana
        solicitar_comida
    else
        echo "Error al preparar los recursos. El CTF no puede continuar." | tee -a "$LOG_FILE"
    fi
    limpiar
}

# Ejecutar el programa principal
main

