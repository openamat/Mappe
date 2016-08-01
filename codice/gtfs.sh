#!/bin/bash

cartellaLavoro="/var/nadir/andrea/script/progetti/amat/automazione"

mkdir "$cartellaLavoro/output" > /dev/null 2>&1

URLGTFS="http://www.comune.palermo.it/gtfs/amat_feed_gtfs.zip"

nomeFile="amat_feed_gtfs"

# scarico il file GTFS
curl -sL "$URLGTFS" > "$cartellaLavoro/$nomeFile.zip"

# decomprimo il file GTFS
unzip -o "$cartellaLavoro/$nomeFile" -d "$cartellaLavoro/$nomeFile"

# copio il file stop nella cartella output e gli cambio estensione
cp "$cartellaLavoro/$nomeFile/stops.txt" "$cartellaLavoro/output/stops.csv"

# scrivo il file delle fermate in gdal/ogr virtual format
cat <<EOT >> "$cartellaLavoro/output/fermate.vrt"
<OGRVRTDataSource>
    <OGRVRTLayer name="stops">
        <SrcDataSource relativeToVRT="1">stops.csv</SrcDataSource>
        <GeometryType>wkbPoint</GeometryType>
        <LayerSRS>WGS84</LayerSRS>
        <GeometryField encoding="PointFromColumns" x="stop_lon" y="stop_lat"/>
    </OGRVRTLayer>
</OGRVRTDataSource>
EOT

# copio il file shapes nella cartella output e gli cambio estensione
cp "$cartellaLavoro/$nomeFile/shapes.txt" "$cartellaLavoro/output/shapes.csv"

# creo il geojson delle rotte
rm "$cartellaLavoro/output/shapes.geojson"
ogr2ogr -f geojson "$cartellaLavoro/output/shapes.geojson" "$cartellaLavoro/output/shapes.csv" -dialect SQLite -sql "SELECT *, MakeLine(MakePoint(CAST(shape_pt_lon AS float),CAST(shape_pt_lat AS float))) FROM shapes GROUP BY shape_id"

# creo il geojson delle fermate
rm "$cartellaLavoro/output/stops.geojson"
ogr2ogr -f geojson "$cartellaLavoro/output/stops.geojson" "$cartellaLavoro/output/fermate.vrt"

