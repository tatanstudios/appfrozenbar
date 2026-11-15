#!/usr/bin/env bash
# Cambia la contraseña de la llave de subida de Google Play (frozenbarcontrol-upload.jks).
# Lee la contraseña actual del .properties, pide la nueva, la cambia en la llave y actualiza el
# .properties (que es de donde la lee compilar-apk.sh play). La llave sigue siendo la misma: Google
# Play no nota el cambio. Uso, desde Git Bash:  bash scripts/cambiar-clave-llave-play.sh
#
# Después, vuelve a respaldar el .jks y el .properties (el respaldo viejo tiene la contraseña vieja).
set -euo pipefail

CARPETA="$HOME/.android-keys"
JKS="$CARPETA/frozenbarcontrol-upload.jks"
PROPS="$CARPETA/frozenbarcontrol-upload.properties"
KEYTOOL="/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe"

[ -f "$JKS" ] && [ -f "$PROPS" ] || { echo "No encuentro la llave en $CARPETA"; exit 1; }
[ -x "$KEYTOOL" ] || { echo "No encuentro keytool en $KEYTOOL"; exit 1; }

ACTUAL="$(grep '^storePassword=' "$PROPS" | cut -d= -f2-)"
"$KEYTOOL" -list -keystore "$(cygpath -w "$JKS")" -storepass "$ACTUAL" >/dev/null 2>&1 \
  || { echo "La contraseña del .properties no abre la llave; no se cambia nada."; exit 1; }

read -rsp "Contraseña nueva (mínimo 6 caracteres): " NUEVA; echo
read -rsp "Repítela: " NUEVA2; echo
[ "$NUEVA" = "$NUEVA2" ] || { echo "No coinciden"; exit 1; }
[ ${#NUEVA} -ge 6 ] || { echo "Muy corta"; exit 1; }

# Respaldo por si algo falla a medias (se borra al terminar bien)
cp "$JKS" "$JKS.antes"
cp "$PROPS" "$PROPS.antes"

# PKCS12: la llave y el almacén comparten contraseña; -storepasswd cambia las dos
"$KEYTOOL" -storepasswd -keystore "$(cygpath -w "$JKS")" -storepass "$ACTUAL" -new "$NUEVA"

"$KEYTOOL" -list -keystore "$(cygpath -w "$JKS")" -storepass "$NUEVA" >/dev/null 2>&1 \
  || { echo "Algo falló; se deja la llave como estaba."; mv "$JKS.antes" "$JKS"; mv "$PROPS.antes" "$PROPS"; exit 1; }

cat > "$PROPS" <<EOF
storeFile=$(cygpath -m "$JKS")
keyAlias=upload
storePassword=$NUEVA
keyPassword=$NUEVA
EOF
rm -f "$JKS.antes" "$PROPS.antes"

echo "Listo: contraseña cambiada en la llave y en $PROPS"
echo "Vuelve a respaldar los dos archivos."
