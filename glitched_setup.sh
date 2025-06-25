#!/bin/bash

# Ruta absoluta
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"

# Gestor de paquetes
detectar_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install -y"
    elif command -v yay &> /dev/null; then
        PKG_MANAGER="yay"
        INSTALL_CMD="yay -S --noconfirm"
    else
        echo "❌ No se encontró un gestor de paquetes."
        exit 1
    fi
}

# Sudo para instalar paquetes
autenticar_sudo() {
    dialog --title "Autenticación requerida" --infobox "Se requiere la contraseña de superusuario para continuar..." 5 60
    if sudo -v; then
        echo "🔐 Autenticación exitosa."
    else
        dialog --msgbox "❌ Error: No se pudo autenticar con sudo. Abortando." 6 50
        clear
        exit 1
    fi
}

# Asegura dialog instalado
asegurar_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "📦 Instalando 'dialog'..."
        $INSTALL_CMD dialog
    fi
}

crear_dialogrc_local() {
    local dialogrc_path="./.dialogrc"

    cat > "$dialogrc_path" <<EOF
use_shadow = OFF
use_colors = ON

screen_color          = (WHITE,BLACK,OFF)   
shadow_color          = (WHITE,WHITE,OFF)
dialog_color          = (BLACK,WHITE,ON)
title_color           = (BLACK,WHITE,ON)
border_color          = (BLACK,WHITE,ON)
button_active_color   = (WHITE,BLUE,ON)
button_inactive_color = (BLACK,WHITE,OFF)
button_key_active_color   = (YELLOW,BLUE,ON)
button_key_inactive_color = (BLACK,WHITE,OFF)
inputbox_color        = (BLACK,WHITE,OFF)
searchbox_color       = (BLACK,WHITE,OFF)
searchbox_title_color = (BLUE,WHITE,ON)
item_color            = (BLACK,WHITE,OFF)
tag_color             = (BLACK,WHITE,OFF)
EOF

    export DIALOGRC="$dialogrc_path"
}

# Emojis para mostrar bonito
instalar_fuente_emoji() {
    echo "🔤 Verificando soporte para emojis..."

    case $PKG_MANAGER in
        apt) pkg="fonts-noto-color-emoji" ;;
        dnf) pkg="google-noto-emoji-color-fonts" ;;
        pacman) pkg="noto-fonts-emoji" ;;
        zypper) pkg="noto-coloremoji-fonts" ;;
        yay) pkg="noto-fonts-emoji" ;;
        *) echo "❌ No se pudo determinar el paquete de emojis para este sistema."; return ;;
    esac

    if ! fc-list | grep -i "emoji" &>/dev/null; then
        echo "📦 Instalando soporte de emojis ($pkg)..."
        $INSTALL_CMD "$pkg"
        echo "✅ Fuente emoji instalada."
    else
        echo "✔️  Fuente emoji ya instalada."
    fi
}


# Actualizar sistema
actualizar_sistema() {
    echo "🔄 Actualizando sistema..."
    case $PKG_MANAGER in
        apt) sudo apt update && sudo apt upgrade -y ;;
        dnf) sudo dnf upgrade -y ;;
        pacman) sudo pacman -Syu --noconfirm ;;
        zypper) sudo zypper refresh && sudo zypper update -y ;;
        yay) yay -Syu --noconfirm ;;
    esac
    echo "✅ Sistema actualizado."
}

# Listas
matematicas=(
    "geogebra" "Geogebra - (geometría interactiva)" off
    "octave"   "Octave - (alternativa a MATLAB)" off
    "r-base"   "R - (lenguaje estadístico)" off
    "sage"     "Sage - sistema matemático de código abierto" off
    "maxima"   "Maxima - álgebra simbólica" off
    "wxmaxima" "WxMaxima - interfaz gráfica para Maxima" off
    "xcas"     "Xcas - cálculo simbólico y gráfico" off
)

cad_2d3d=(
    "freecad"   "FreeCAD - (modelado paramétrico 3D)" off
    "librecad"  "LibreCAD - (dibujo técnico 2D)" off
    "openscad"  "OpenSCAD - (modelado 3D por código)" off
    "blender"   "Blender - modelado 3D avanzado" off
    "gcode-viewer"    "GCode Viewer - previsualizador GCode" off
    "prusa-slicer"    "PrusaSlicer - slicer para impresión 3D" off
    "cura"            "Cura - slicer para impresión 3D" off
)

simulacion=(
    "elmerfem"     "ElmerFEM - simulación por elementos finitos" off
    "gmsh"         "Gmsh - generador de mallas 3D" off
    "salome"       "Salome - entorno de pre/post procesamiento FEM" off
    "openfoam"     "OpenFOAM - simulación CFD y análisis de fluidos" off
)

electronica=(
    "fritzing"  "Fritzing - diseño de circuitos amigable" off
    "qucs-s"    "QUCS-S - (simulador de circuitos)" off
    "kicad"     "KiCad - (diseño de placas PCB)" off
    "simulide"  "SimulIDE - (simulador básico)" off
    "xoscope"   "Xoscope - osciloscopio virtual" off
    "sigrok"    "Sigrok - herramientas de captura digital" off
    "pulseview" "PulseView - visualizador de señales" off
)

programacion=(
    "python3"    "Python 3 - lenguaje de programación" off
    "nodejs"     "Node.js - entorno JavaScript" off
    "micro"      "Micro - editor de texto en terminal" off
    "neovim"     "Neovim - editor modal extensible" off
    "pluma"      "Pluma - editor gráfico ligero" off
    "sublime-text"  "Sublime Text - editor de texto versátil y rápido" off
)

librerias=(
    # Python
    "python3-numpy"       "Python - numpy (álgebra y vectores)" off
    "python3-scipy"       "Python - scipy (cálculo científico)" off
    "python3-matplotlib"  "Python - matplotlib (gráficas)" off
    "python3-serial"      "Python - serial (comunicación serial)" off
    "python3-sympy"       "Python - sympy (álgebra simbólica)" off
    "python3-numba"       "Python - numba (aceleración JIT con LLVM)" off

    # Octave
    "octave-control"      "Octave - control automático" off
    "octave-io"           "Octave - entrada/salida de archivos" off
    "octave-signal"       "Octave - señales" off
    "octave-statistics"   "Octave - estadística" off
    "octave-optim"        "Octave - optimización" off
    "octave-symbolic"     "Octave - simbólico" off
    "octave-jupyter"      "Octave - Jupyter" off
    "octave-arduino"      "Octave - Arduino" off
    "octave-raspi"        "Octave - Raspberry Pi" off
    "octave-instrument-control" "Octave - instrumentos" off
    "tablicious"          "Octave - Tablas" off

    # OpenSCAD
    "openscad-bosl2"      "OpenSCAD - BOSL2" off
    "openscad-mcad"       "OpenSCAD - MCAD" off

	# Otros
    "openmpi-bin"  "Pckg - openmpi (paralelismo)" off
    "fftw3"        "Pckg - transformadas Fourier" off
    "libblas-dev"  "Pckg - álgebra lineal" off
)

herramientas=(
    "gcc"          "Compiler - gcc (C)" off
    "g++"          "Compiler - g++ (C++)" off
    "gfortran"     "Compiler - Fortran" off
    "clang"        "Compiler - clang (C/C++)" off	
    "git"          "Tool - control de versiones" off
    "cmake"        "Tool - cmake" off
    "qmake"        "Tool - qmake" off
    "gnuplot"      "Tool - gnuplot (visualización)" off
    "arduino-cli"  "Tool - arduino-cli (interfaz CLI Arduino)" off
    "avrdude"      "Tool - avrdude (firmware para AVR)" off
    "rpi-imager"   "Tool - rpi-imager (escritor para Raspberry Pi)" off
    "python3-pip"  "Python - pip (gestor de paquetes)" off
    "python3-venv" "Python - venv (entorno virtual)" off
    "npm"          "Node Package Manager" off
)

cliapps=(
    "zsh"           "Zsh - shell customizable" off
    "htop"          "htop - monitor de procesos interactivo" off
    "tmux"          "tmux - multiplexor de terminal" off
    "curl"          "curl - herramienta de transferencia de datos por URL" off
    "wget"          "wget - descargador de archivos por terminal" off
    "tree"          "tree - visualiza estructura de directorios en árbol" off
    "bat"           "bat - alternativa a cat con sintaxis coloreada" off
)

otros=(
    "texlive-full"    "LaTeX - sistema de tipografía científica" off
    "libreoffice"     "LibreOffice - suite ofimática" off
    "pinta"           "Pinta - editor de imágenes" off
    "vlc"             "VLC - reproductor multimedia" off
    "fonts-firacode"  "Fuente para programación" off
    "wine"          "Wine - ejecuta programas de Windows en Linux" off
    "winetricks"    "Winetricks - utilidades y dependencias para Wine" off
    "transmission"  "Transmission - cliente BitTorrent ligero" off
)

# Categorias
sub_menu_categoria() {
    local titulo="$1"
    shift
    local opciones=("$@")
    dialog --clear --title "$titulo" \
        --checklist "Seleccione los paquetes a instalar:" 20 70 12 \
        "${opciones[@]}" \
        3>&1 1>&2 2>&3
}

# Ver instalados
ver_programas_instalados() {

    # Listas
	categorias=(
        matematicas
        cad_2d3d
        electronica
        programacion
        librerias
        herramientas
        cliapps
        otros
    )

    declare -A seen
    total=()
    
	# Evaluar nombres paquetes
    for cat in "${categorias[@]}"; do
    	# Expande arreglo
        eval "lista=(\"\${${cat}[@]}\")"
        for ((i=0; i<${#lista[@]}; i+=3)); do
            pkg="${lista[i]}"
            if [[ -z "${seen[$pkg]}" ]]; then
                total+=("$pkg")
                seen["$pkg"]=1
            fi
        done
    done

    # Ordenar
    IFS=$'\n' sorted=($(sort <<<"${total[*]}"))
    unset IFS

    # Verifica instalacion
    is_installed() {
        local pkg="$1"
        case "$PKG_MANAGER" in
            apt)
                dpkg -s "$pkg" &> /dev/null
                ;;
            pacman)
                pacman -Q "$pkg" &> /dev/null
                ;;
            dnf|yum)
                rpm -q "$pkg" &> /dev/null
                ;;
            zypper)
                rpm -q "$pkg" &> /dev/null
                ;;
            yay)
                yay -Q "$pkg" &> /dev/null
                ;;
            *)
                return 1
                ;;
        esac
    }

	# Mostrar
    texto=""
    for pkg in "${sorted[@]}"; do
        if is_installed "$pkg"; then
            texto+="$pkg ✅ INSTALADO\n"
        else
            texto+="$pkg ❌ NO INSTALADO\n"
        fi
    done

	# Gyardar
    echo -e "$texto" > "$SCRIPT_DIR/installed_list.md"
    dialog --title "Paquetes instalados" \
        --textbox "$SCRIPT_DIR/installed_list.md" 22 70
}

# Menu
mostrar_menu_principal() {
    while true; do
        opcion=$(dialog --clear --title "Categorías" --colors \
            --menu "Seleccione una opción:" 20 60 9 \
            1 "📐Matemáticas" \
            2 "⚙️ 2D/3D CAD" \
            3 "🧲Simulación" \
            4 "🔌Electrónica" \
            5 "💻Programación" \
            6 "📦Librerías y módulos" \
            7 "🛠️ Herramientas y compiladores" \
            8 "🖥️ CLI Apps" \
            9 "📋Otros" \
            0 "🔍Ver programas instalados" \
            I "⬇️ Instalar y salir" \
            S "🚪Salir" \
            3>&1 1>&2 2>&3)
        
        ret=$?
        if [ $ret -ne 0 ]; then
            # Cancelar o ESC
            clear
            exit 0
        fi

        case $opcion in
            1) sel_matematicas=$(sub_menu_categoria "Matemáticas" "${matematicas[@]}") ;;
            2) sel_cad=$(sub_menu_categoria "2D/3D CAD" "${cad_2d3d[@]}") ;;
            3) sel_simu=$(sub_menu_categoria "Simulación" "${simulacion[@]}") ;;
            4) sel_electr=$(sub_menu_categoria "Electrónica" "${electronica[@]}") ;;
            5) sel_prog=$(sub_menu_categoria "Programación" "${programacion[@]}") ;;
            6) sel_libs=$(sub_menu_categoria "Librerías y módulos" "${librerias[@]}") ;;
            7) sel_herr=$(sub_menu_categoria "Herramientas y compiladores" "${herramientas[@]}") ;;
            8) sel_cliapps=$(sub_menu_categoria "Aplicaciones de terminal" "${cliapps[@]}") ;;
            9) sel_otros=$(sub_menu_categoria "Otros" "${otros[@]}") ;;
            0) ver_programas_instalados ;;
            I) break ;;  # Instalar y salir
            S) clear; exit 0 ;;  # Salir
            *) break ;;
        esac
    done
}

# Resumen
mostrar_resumen_y_confirmar() {
    resumen=""
    total="$sel_matematicas $sel_cad $sel_simu $sel_electr $sel_prog $sel_libs $sel_herr $sel_cliapps $sel_otros"
    for pkg in $total; do
        resumen+="$pkg\n"
    done
    dialog --title "Resumen de instalación" \
        --yesno "Se instalarán los siguientes paquetes:\n\n$resumen\n\n¿Desea continuar?" 20 60
    return $?
}

# Instalacion
instalar_programas() {
    echo "" > "$LOG_FILE"
    total="$sel_matematicas $sel_cad $sel_simu $sel_electr $sel_prog $sel_libs $sel_herr $sel_cliapps $sel_otros"
    total_count=$(echo "$total" | wc -w)
    i=0

    {
    for pkg in $total; do
        i=$((i + 1))
        echo "XXX"
        echo $((i * 100 / total_count))
        echo "Instalando $pkg..."
        echo "XXX"
        $INSTALL_CMD "$pkg" >> "$LOG_FILE" 2>&1
        sleep 0.3
    done
    } | dialog --title "Instalación en progreso..." --gauge "Espere por favor..." 10 60 0

    dialog --title "Instalación finalizada" \
        --msgbox "✅ Instalación completada.\n\nLog: $LOG_FILE" 8 60
}

# Llamada funciones
detectar_package_manager
autenticar_sudo
asegurar_dialog
instalar_fuente_emoji
crear_dialogrc_local
actualizar_sistema
mostrar_menu_principal

if mostrar_resumen_y_confirmar; then
    instalar_programas
else
    dialog --msgbox "❌ Instalación cancelada por el usuario." 6 40
fi

clear
