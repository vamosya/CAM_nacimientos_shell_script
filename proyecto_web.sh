#!/bin/bash

#Obtención y filtrado
url="https://datos.comunidad.madrid/catalogo/dataset/81c88111-8e8b-4c01-a609-f8b075d4647b/resource/1c9d0b82-1b43-4624-b0f4-4d1cd763b873/download/cm.json"

curl -G --insecure $url > temporal_nacimientos.json

sed 's/\(Menores de.\)\([0-9][0-9]\)\(.años\)/00-\2/' temporal_nacimientos.json > temporal_nacimientos_filtrado.json
sed -i 's/\(De.\)\([0-9][0-9]\)\(.años y más\)/\2-99/' temporal_nacimientos_filtrado.json
sed -i 's/\(De.\)\([0-9][0-9]\)\(.a.\)\([0-9][0-9]\)\(.años\)/\2-\4/' temporal_nacimientos_filtrado.json
cat temporal_nacimientos_filtrado.json | grep -v municipio_codigo > temporal_nacimientos_limpio.json
jq .data temporal_nacimientos_limpio.json > temporal_nacimientos_limpio_data.json

#Agrupo nacimientos por rango de edad
jq -r 'group_by(.rango_edad_de_la_madre)[] | [.[0].rango_edad_de_la_madre, (map(.numero_nacimientos) | add)] | @csv' temporal_nacimientos_limpio_data.json > nacimientosxrangoedad.csv
sed -i 's/"//g' nacimientosxrangoedad.csv

#Agrupo nacimientos por rango de edad y sexo
jq -r 'group_by(.rango_edad_de_la_madre)[] | group_by(.sexo)[] | [.[0].rango_edad_de_la_madre, .[0].sexo, (map(.numero_nacimientos) | add)] | @csv' temporal_nacimientos_limpio_data.json > nacimientosxrangoedadysexo.csv

#Agrupo nacimientos por municipio
jq -r 'group_by(.municipio_nombre)[] | [.[0].municipio_nombre, (map(.numero_nacimientos) | add)] | @csv' temporal_nacimientos_limpio_data.json > nacimientosxmunicipio.csv
sed -i 's/"//g' nacimientosxmunicipio.csv

#Agrupo nacimientos por sexo
jq -r 'group_by(.sexo)[] | [.[0].sexo, (map(.numero_nacimientos) | add)] | @csv' temporal_nacimientos_limpio_data.json > nacimientosxsexo.csv


sort -t, -k2 -n nacimientosxmunicipio.csv -r | head -n25 > nacimientosxmunicipio25.csv
sort -t, -k2 -n nacimientosxmunicipio.csv -r | head -n10 > nacimientosxmunicipio10.csv

#Calculo estadísticos
total_nacimientos=$(jq 'map(.numero_nacimientos) | add' temporal_nacimientos_limpio_data.json)
total_municipios=$(wc -l < nacimientosxmunicipio.csv)
mediaxmunicipio=$(echo "scale=2; $total_nacimientos/$total_municipios" | bc)
mun_max=$(cut -d ',' -f1 nacimientosxmunicipio10.csv | head -1)
mun_max_n=$(cut -d ',' -f2 nacimientosxmunicipio10.csv | head -1)
hombres=$(cut -d ',' -f2 nacimientosxsexo.csv| head -1)
mujeres=$(cut -d ',' -f2 nacimientosxsexo.csv| tail -1)

#Genero gráfica con gnuplot

gnuplot -persist << EOF
	set output 'grafica_rangos.png' 
	set title 'Gráfica de Rangos'
	set style fill solid border rgb 'black'
	set boxwidth 1.0 abs
	set datafile separator ","
	set xtics font ",10.0"
	set terminal png size 600,350 background rgb 'grey' 
	plot 'nacimientosxrangoedad.csv' using 2:xtic(1) with boxes notitle lc "orange" 
EOF

gnuplot -persist << EOF
        set output 'grafica_municipios.png' 
        set title 'Gráfica de municipios'
        set style fill solid border rgb 'black'
        set boxwidth 1.0 abs
        set datafile separator ","
	set xtics rotate
	set xtics font ",8.0"
	set ytics font ",8.0"
	set size 1, 0.5
        set terminal png size 600,350 background rgb 'grey'
        plot 'nacimientosxmunicipio25.csv' using 2:xtic(1) with boxes notitle lc "orange"
EOF


#Genera el html

echo "<html>"
echo "<body style=\"background-color:#F4EEED;\">"
echo "<H1 align="center"> Análisis de los nacimientos en la Comunidad de Madrid en 2018</H1>"

echo "<table style="boder:hidden">"
echo "<tr><td>

<table <table style="boder:hidden">
<tr><td>

Esta web analiza los datos del fichero descargado de <a href="$url">aquí</a> <br>
Tras analizarlo, se observa que hubo $total_nacimientos nacimientos en la Comunidad de Madrid. <br>
En cuanto al sexo, nacieron $hombres hombres y $mujeres mujeres. <br>
La media por municipio fue $mediaxmunicipio. <br>
El municipio con más nacimientos fue $mun_max con $mun_max_n.<br><br>

Podemos ver un resumen de los datos en las dos tablas de la derecha: 
una con el número de nacimientos por edad, y otra con el listado de los 10
municipios con más nacimientos. <br><br>

Además debajo se pueden ver dos gráficos de barra: Una de nacimientos por edad, y otra
con los 25 municipios con más nacimientos.<br><br>

El script que genera este html ha sido creado por Carlos Peralta Parro.
</td><td>

<table border>

</td><td>Rango de edades</td><td>Nacimientos</td></tr>"
input="nacimientosxrangoedad.csv"
i=1
while IFS= read -r linea
do
	rango=$(echo $linea | cut -d "," -f1)
	suma=$(echo $linea | cut -d "," -f2)
	echo "<tr><td>$rango</td><td>$suma</td></tr>"
done < "$input"
echo "</table>"

echo "</td><td>

<table border>
<tr><td>Municipio</td><td>Nacimientos</td></tr>"

input="nacimientosxmunicipio10.csv"
i=1
while IFS= read -r linea
do
	rango=$(echo $linea | cut -d "," -f1)
        suma=$(echo $linea | cut -d "," -f2)
        echo "<tr><td>$rango</td><td>$suma</td></tr>"

done < "$input"
echo "</table>"

echo "</table>"

echo "</td></tr>"

echo "</table>"
echo "<table border>"
echo "<tr><td><img src="grafica_rangos.png" alt="Grafica de rangos"></td><td><img src="grafica_municipios.png" alt="Grafica de municipios"></td></tr>"
#echo "<img src="grafica_rangos.png" alt="Grafica de rangos">"
#echo "<img src="grafica_municipios.png" alt="Grafica de municipios">"
echo "</table>"
echo "</body>"
echo "</html>"
