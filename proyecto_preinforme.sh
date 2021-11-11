#!/bin/bash
url='https://datos.comunidad.madrid/catalogo/dataset/81c88111-8e8b-4c01-a609-f8b075d4647b/resource/5f0d78da-86f1-42c6-9eb2-05254f294934/download/cm.csv'

#Descargo csv
curl -G --insecure $url -o nacimientos.csv

#Cambio codificación
iconv -f iso-8859-1 -t utf-8 nacimientos.csv nacimientosOK.csv

#Normalizo el campo rango edad para que siga la misma estructura
cat nacimientosOK.csv | sed 's/años//' | sed 's/  y más/-99 /' | sed 's/De//' | sed 's/Menores de / 00-/g' | sed 's/ a /-/g' > nacimientosFINAL.csv

