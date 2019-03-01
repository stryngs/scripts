class Scan(object):
    """Handles the scan data"""

    def __init__(self, con, db, lHandler, root):
        ## Notate the data for the individual hosts
        hostList = root.findall('host')
        count = 0
        for i in hostList:
            #print(count)
            count += 1
            endtime = i.attrib.get('endtime')
            eList = i.iter()
            eDict = {}
            for i in eList:
                eDict.update({i.tag: i})
            address = eDict.get('address').attrib.get('addr')
            addrtype = eDict.get('address').attrib.get('addrtype')
            protocol = eDict.get('port').attrib.get('protocol')
            portid = eDict.get('port').attrib.get('portid')
            state = eDict.get('state').attrib.get('state')
            reason = eDict.get('state').attrib.get('reason')
            reason_ttl = eDict.get('state').attrib.get('reason_ttl')
            if eDict.has_key('service'):
                name = eDict.get('service').attrib.get('name')
                banner = eDict.get('service').attrib.get('banner')
            else:
                name = ''
                banner = ''

            ## Add the host to DB
            db.execute('INSERT OR IGNORE INTO\
                            `ip_list`\
                        VALUES(?,\
                            ?,\
                            ?,\
                            ?,\
                            ?,\
                            ?,\
                            ?,\
                            ?,\
                            ?,\
                            ?);',\
                            (endtime,\
                            address,\
                            addrtype,\
                            protocol,\
                            portid,\
                            state,\
                            reason,\
                            reason_ttl,\
                            name,\
                            banner))       

        ## Add services now
        for svc in lHandler.sList:
            db.execute('INSERT INTO\
                            `svc_list`\
                        VALUES(?,\
                                ?,\
                                ?,\
                                ?,\
                                ?);',\
                                (svc[0],\
                                svc[1],\
                                svc[2],\
                                svc[3],\
                                svc[4]))
