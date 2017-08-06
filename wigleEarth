#!/usr/bin/python3
# -*- coding: UTF-8 -*-

## Purpose:
    ## Take a Wigle DB and import it to Google Earth
    ## Much easier than using Website based CSV to KML importers

## ToDo:
    ## Make args based
    ## Add options for no mac and no essid

import os, sys
import sqlite3 as lite

try:
    discard = sys.argv[3]
except:
    print('Example:')
    print("wigleEarth <Wigle db> 'LIKE' '%WPA%'")
    print('-OR-')
    print('wigleEarth combine <kml 1> <kml 2>')
    print('-OR-')
    print("wigleEarth plot <google API key> <Wigle db> 'LIKE' '%WPA%'")
    sys.exit(1)

if 'sqlite' in sys.argv[1]:
    dbName = sys.argv[1]
    dbOperator = sys.argv[2]
    dbQuery = sys.argv[3]
    kml = dbName.split('.')[0] + '.kml'
    
    ## Rip appropriate APs from DB
    con = lite.connect(dbName)
    with con:
        db = con.cursor()
        db.execute("SELECT `bssid`, `ssid`, `bestlat`, `bestlon` FROM `network` WHERE `capabilities` {0} ?;".format(dbOperator), (dbQuery,))
        grab = db.fetchall()

    ## Header the kml
    with open(kml, 'w') as oFile:
        oFile.write('\
<?xml version="1.0" encoding="UTF-8"?>\n\
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">\n\
<Document>\n\
    <name>Untitled Placemark.kml</name>\n\
    <open>1</open>\n\
    <StyleMap id="m_ylw-pushpin">\n\
        <Pair>\n\
            <key>normal</key>\n\
            <styleUrl>#s_ylw-pushpin</styleUrl>\n\
        </Pair>\n\
        <Pair>\n\
            <key>highlight</key>\n\
            <styleUrl>#s_ylw-pushpin_hl</styleUrl>\n\
        </Pair>\n\
    </StyleMap>\n\
    <Style id="s_ylw-pushpin_hl">\n\
        <IconStyle>\n\
            <scale>1.3</scale>\n\
            <Icon>\n\
                <href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>\n\
            </Icon>\n\
            <hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>\n\
        </IconStyle>\n\
        <ListStyle>\n\
            <ItemIcon>\n\
                <href>http://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png</href>\n\
            </ItemIcon>\n\
        </ListStyle>\n\
    </Style>\n\
    <Style id="s_ylw-pushpin">\n\
        <IconStyle>\n\
            <scale>1.1</scale>\n\
            <Icon>\n\
                <href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>\n\
            </Icon>\n\
            <hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>\n\
        </IconStyle>\n\
        <ListStyle>\n\
            <ItemIcon>\n\
                <href>http://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png</href>\n\
            </ItemIcon>\n\
        </ListStyle>\n\
    </Style>\n')

    ## Middle the kml
    with open(kml, 'a') as oFile:
        for i in grab:
            
            ## Deal with unicode nonsense
            if '&' in i[1]:
                essid = i[1].replace('&', '&amp;')
            else:
                essid = i[1]
                
            
            oFile.write('\
    <Placemark>\n\
        <name>{0}</name>\n\
        <description>{1}</description>\n\
        <LookAt>\n\
            <longitude>{2}</longitude>\n\
            <latitude>{3}</latitude>\n\
            <altitude>0</altitude>\n\
            <heading>0</heading>\n\
            <tilt>0</tilt>\n\
            <range>50000</range>\n\
            <gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>\n\
        </LookAt>\n\
        <styleUrl>#m_ylw-pushpin</styleUrl>\n\
        <Point>\n\
            <gx:drawOrder>1</gx:drawOrder>\n\
            <coordinates>{2},{3},0</coordinates>\n\
        </Point>\n\
    </Placemark>\n'\
            .format(essid, str(i[0]), str(i[3]), str(i[2])))

    ## End the kml
    with open(kml, 'a') as oFile:
        oFile.write('</Document>\n</kml>')

elif 'combine' in sys.argv[1]:
    k1 = sys.argv[2]
    k2 = sys.argv[3]
    
    ## Rip data
    with open(k1, 'r') as iFile:
        k1Dump = iFile.read().splitlines()
    with open(k2, 'r') as iFile:
        k2Dump = iFile.read().splitlines()
    
    ## Gen tophalf
    header = k1Dump[0:len(k1Dump)-2]
    
    ## Gen bottomhalf
    footer = k2Dump[43:len(k2Dump)]
    
    ## Create new file
    lastLine = len(os.linesep)
    kml = k1.split('.')[0] + '_' + k2.split('.')[0] + '.kml'
    with open(kml, 'w') as oFile:
        for i in header:
            oFile.write(i + '\n')
        for i in footer:
            oFile.write(i + '\n')
        oFile.truncate(oFile.tell() - lastLine)

elif 'plot' in sys.argv[1]:
    apiKey = sys.argv[2]
    dbName = sys.argv[3]
    dbOperator = sys.argv[4]
    dbQuery = sys.argv[5]
    hFile = dbName.split('.')[0] + '.html'
    
    ## Rip db
    con = lite.connect(dbName)
    with con:
        db = con.cursor()
        db.execute("SELECT `bssid`, `ssid`, `bestlat`, `bestlon` FROM `network` WHERE `capabilities` {0} ?;".format(dbOperator), (dbQuery,))
        grab = db.fetchall()

    ## Gen header
    with open(hFile, 'w') as oFile:
        oFile.write('\
<!DOCTYPE html>\n\
<html>\n\
  <head>\n\
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no">\n\
    <meta charset="utf-8">\n\
    <title>Wardrive</title>\n\
    <style>\n\
      /* Always set the map height explicitly to define the size of the div\n\
       * element that contains the map. */\n\
      #map {\n\
        height: 100%;\n\
      }\n\
      /* Optional: Makes the sample page fill the window. */\n\
      html, body {\n\
        height: 100%;\n\
        margin: 0;\n\
        padding: 0;\n\
      }\n\
    </style>\n\
  </head>\n\
  <body>\n\
    <div id="map"></div>\n\
    <script>\n\
      function initMap() {\n\
        var map = new google.maps.Map(document.getElementById("map"), {\n\
          zoom: 11,\n')
        
        oFile.write('\
          center: {lat: %.10f, lng: %.10f},\n' % (grab[0][2], grab[0][3]))
        
        oFile.write('\
        });\n')

    ## Gen points
    for i in grab:
        with open(hFile, 'a') as oFile:
            oFile.write('        var marker = new google.maps.Marker({\n')
            oFile.write('          position: {lat: %.10f, lng: %.10f},\n' % (i[2], i[3]))
            oFile.write('          map: map,\n')
            oFile.write("          title: '{0}',\n".format(i[0]))
            oFile.write('          label: "{0}"\n'.format(i[1]))
            oFile.write("        });\n")

    ## Gen footer
    with open(hFile, 'a') as oFile:
        oFile.write('\n\
      }\n\
    </script>\n\
    <script async defer\n\
    src="https://maps.googleapis.com/maps/api/js?key=%s&callback=initMap">\n\
    </script>\n\
  </body>\n\
</html>\n' % apiKey)
        
    