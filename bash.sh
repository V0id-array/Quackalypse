
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

# URLs de GIFs
GIF_URL="https://c.tenor.com/-t1oo-r1fp0AAAAd/tenor.gif"
VICTORY_GIF_URL="https://github.com/V0id-array/Quackalypse/blob/main/victory.gif?raw=true"


# Rutas locales de los GIFs descargados
DUCK_GIF="$IMAGES_DIR/angry_duck.gif"
VICTORY_GIF="$IMAGES_DIR/victory.gif"

# Variable para almacenar el visualizador a usar
VIEWER_CMD=""

# Variable para almacenar el PID del visualizador
VIEWER_PID=""

#=============================================
# FUNCIONES
#=============================================

# Función para configurar el entorno inicial
setup() {
    mkdir -p "$TEMP_DIR"
    mkdir -p "$IMAGES_DIR"
    echo "Iniciando CTF de Patos Hambrientos (versión visualizador) $(date)" > "$LOG_FILE"
    
    # Verificar si wget está instalado
    if ! command -v wget > /dev/null; then
        echo "No se encontró el comando 'wget'. Instalándolo..." | tee -a "$LOG_FILE"
        sudo apt-get update && sudo apt-get install -y wget
    fi
    
    # Verificar visualizadores disponibles
    if command -v eog > /dev/null; then
        VIEWER_CMD="eog"
        echo "Se usará 'eog' (Eye of GNOME) para mostrar imágenes." >> "$LOG_FILE"
    elif command -v xdg-open > /dev/null; then
        VIEWER_CMD="xdg-open"
        echo "Se usará 'xdg-open' para mostrar imágenes." >> "$LOG_FILE"
    else
        echo "No se encontró ningún visualizador compatible. Intentando instalar eog..." | tee -a "$LOG_FILE"
        sudo apt-get update && sudo apt-get install -y eog
        if command -v eog > /dev/null; then
            VIEWER_CMD="eog"
        else
            echo "No se pudo instalar un visualizador compatible." | tee -a "$LOG_FILE"
            exit 1
        fi
    fi
    
    echo "Visualizador seleccionado: $VIEWER_CMD" >> "$LOG_FILE"
    echo "Directorio temporal: $TEMP_DIR" >> "$LOG_FILE"
    echo "Archivo oculto: $HIDDEN_FILE" >> "$LOG_FILE"
}

# Función para crear el archivo oculto con emojis
crear_archivo_oculto() {
    echo "Creando archivo oculto con emojis de comida..." >> "$LOG_FILE"
    echo "$FOOD_EMOJIS" > "$HIDDEN_FILE"
    echo "Archivo oculto creado en: $HIDDEN_FILE" >> "$LOG_FILE"
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
    
    echo "GIFs descargados correctamente" >> "$LOG_FILE"
    return 0
}

# Función para abrir la ventana del visualizador
abrir_ventana() {
    echo "Abriendo ventana de pato enfadado..." >> "$LOG_FILE"
    
    # Verificar si ya hay un proceso en ejecución
    if [ -n "$VIEWER_PID" ] && ps -p "$VIEWER_PID" > /dev/null 2>&1; then
        echo "Ya hay una ventana abierta con PID $VIEWER_PID" >> "$LOG_FILE"
        return
    fi
    
    # Verificar que el archivo existe
    if [ ! -f "$DUCK_GIF" ]; then
        echo "El archivo $DUCK_GIF no existe. Intentando descargar de nuevo..." >> "$LOG_FILE"
        wget -q "$GIF_URL" -O "$DUCK_GIF"
        if [ $? -ne 0 ]; then
            echo "Error al descargar el GIF" | tee -a "$LOG_FILE"
            return
        fi
    fi
    
    # Abrir el GIF con el visualizador
    DISPLAY=:0 $VIEWER_CMD "$DUCK_GIF" >> "$LOG_FILE" 2>&1 &
    VIEWER_PID=$!
    echo $VIEWER_PID > "$PID_FILE"
    
    echo "Ventana abierta con PID: $VIEWER_PID usando $VIEWER_CMD" >> "$LOG_FILE"
    sleep 2  # Esperar a que la ventana se abra completamente
}

# Función para monitorear la ventana
monitorear_ventana() {
    echo "Iniciando monitoreo de ventana..." >> "$LOG_FILE"
    
    (
        while true; do
            # Cargar PID desde el archivo (por si ha cambiado)
            if [ -f "$PID_FILE" ]; then
                VIEWER_PID=$(cat "$PID_FILE")
            fi
            
            # Verificar si el proceso existe
            if [ -z "$VIEWER_PID" ] || ! ps -p "$VIEWER_PID" > /dev/null 2>&1; then
                echo "Ventana cerrada o no iniciada. Reabriendo..." >> "$LOG_FILE"
                abrir_ventana
            else
                echo "Ventana aún abierta (PID: $VIEWER_PID)" >> "$LOG_FILE"
            fi
            
            sleep 0.5
        done
    ) &
    
    # Guardar el PID del monitor
    MONITOR_PID=$!
    echo $MONITOR_PID > "$TEMP_DIR/monitor_pid.txt"
    echo "Proceso de monitoreo iniciado con PID: $MONITOR_PID" >> "$LOG_FILE"
}

# Función para mostrar la pantalla de victoria
mostrar_victoria() {
    echo "¡Felicidades! Has alimentado al pato hambriento." | tee -a "$LOG_FILE"
    echo "Abriendo GIF de victoria..." >> "$LOG_FILE"
    
    # Detener el proceso de monitoreo antes de abrir el GIF de victoria
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
            sleep 1
        fi
    fi
    
    # Verificar que el archivo existe
    if [ ! -f "$VICTORY_GIF" ]; then
        echo "El archivo $VICTORY_GIF no existe. Intentando descargar de nuevo..." >> "$LOG_FILE"
        wget -q "$VICTORY_GIF_URL" -O "$VICTORY_GIF"
        if [ $? -ne 0 ]; then
            echo "Error al descargar el GIF de victoria. Mostrando mensaje alternativo." | tee -a "$LOG_FILE"
            echo "¡La flag es !"
            return
        fi
    fi
    
    # Abrir GIF de victoria en el visualizador
    DISPLAY=:0 $VIEWER_CMD "$VICTORY_GIF" >> "$LOG_FILE" 2>&1 &
    VICTORY_PID=$!
    echo "GIF de victoria abierto con PID: $VICTORY_PID" >> "$LOG_FILE"
    
    echo "La flag DuckyCTF{QuackQuack} está escondida en el GIF"
    sleep 1500 # Dar tiempo para que se aprecie el GIF de victoria
}

# Función para cerrar las ventanas del visualizador
cerrar_ventanas() {
    echo "Cerrando ventanas..." >> "$LOG_FILE"
    
    # Detener el proceso de monitoreo
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
        else
            echo "Visualizador (PID $pid) ya no existe." >> "$LOG_FILE"
        fi
    fi
    
    # Matar cualquier instancia del visualizador que pueda quedar
    if [ "$VIEWER_CMD" = "eog" ]; then
        pkill eog 2>/dev/null
    fi
}

# Función para solicitar la comida
solicitar_comida() {
    echo "Solicitando comida para el pato..." >> "$LOG_FILE"
    
    while true; do
        echo "¡El pato ha encontrado comida en tu ordenador y la quiere!"
        echo "Pega aquí la lista de comida que encontraste (o escribe 'salir' para terminar):"
        read -r respuesta
        
        # Opción para salir
        if [ "$respuesta" = "salir" ]; then
            echo "Has decidido salir. El pato sigue hambriento." >> "$LOG_FILE"
            return 1
        fi
        
        # Verificar respuesta
        if [ "$respuesta" = "$FOOD_EMOJIS" ]; then
            echo "¡Correcto! Al pato le encanta esa comida." >> "$LOG_FILE"
            mostrar_victoria
            return 0
        else
            echo "Esa no es la comida correcta. El pato sigue hambriento." >> "$LOG_FILE"
            echo "El pato no parece querer eso... Intenta de nuevo."
            echo "Pista: La comida está en un archivo oculto en /tmp llamado .comida_patos.txt"
        fi
    done
}

# Función para limpiar recursos al terminar
limpiar() {
    echo "Limpiando recursos..." >> "$LOG_FILE"
    cerrar_ventanas
    
    # Opcional: eliminar los archivos GIF descargados
    # rm -f "$DUCK_GIF" "$VICTORY_GIF"
    
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
    descargar_gifs
    abrir_ventana
    monitorear_ventana
    solicitar_comida
    limpiar
}

# Ejecutar el programa principal
main
