class Stats(object):
    """Class for generating statistics"""
    def __init__(self, db):
        self.db = db


    def by_addr(self):
        """Look at the data by IP address"""
        self.db.execute("""
                        CREATE TABLE `by_addr`AS
                        SELECT COUNT(*) AS 'qty',
                        IP.addr AS 'addr',
                        GROUP_CONCAT(DISTINCT(IP.protocol)) AS 'protocols',
                        GROUP_CONCAT(DISTINCT(IP.portid)) AS 'ports',
                        GROUP_CONCAT(DISTINCT(IP.`state`)) AS 'states',
                        GROUP_CONCAT(DISTINCT(IP.reason)) AS 'reasons',
                        GROUP_CONCAT(DISTINCT(IP.name)) AS 'names',
                        GROUP_CONCAT(DISTINCT(IP.banner)) AS 'banners',
                        GROUP_CONCAT(DISTINCT(SL.name)) AS 'services',
                        GROUP_CONCAT(DISTINCT(SL.freq)) AS 'freqs',
                        GROUP_CONCAT(DISTINCT(SL.cmt)) AS 'comments'
                        FROM ip_list IP INNER JOIN svc_list SL 
                        ON IP.portid = SL.port 
                        WHERE IP.protocol = SL.proto 
                        GROUP BY addr 
                        ORDER BY 1 DESC;
                        """)


    def addrStats(self):
        """GUI for by addrs"""
        self.db.execute("""
                        SELECT qty, addr from by_addr;
                        """)
        return self.db.fetchall()


    def by_port(self):
        """Look at the data by port #"""
        self.db.execute("""
                        CREATE TABLE `by_port`AS
                        SELECT COUNT(*) AS 'qty',
                        GROUP_CONCAT(DISTINCT(IP.addr)) AS 'addrs',
                        GROUP_CONCAT(DISTINCT(IP.protocol)) AS 'protocols',
                        IP.portid AS 'port',
                        GROUP_CONCAT(DISTINCT(IP.`state`)) AS 'states',
                        GROUP_CONCAT(DISTINCT(IP.reason)) AS 'reasons',
                        GROUP_CONCAT(DISTINCT(IP.name)) AS 'names',
                        GROUP_CONCAT(DISTINCT(IP.banner)) AS 'banners',
                        GROUP_CONCAT(DISTINCT(SL.name)) AS 'services',
                        GROUP_CONCAT(DISTINCT(SL.freq)) AS 'freqs',
                        GROUP_CONCAT(DISTINCT(SL.cmt)) AS 'comments'
                        FROM ip_list IP INNER JOIN svc_list SL 
                        ON IP.portid = SL.port 
                        WHERE IP.protocol = SL.proto 
                        GROUP BY port 
                        ORDER BY 1 DESC;
                        """)


    def portStats(self):
        """GUI for by addrs"""
        self.db.execute("""
                        SELECT qty, port from by_port;
                        """)
        return self.db.fetchall()


    def by_svc(self):
        """Look at the data by service name as derived from your services file"""
        self.db.execute("""
                        CREATE TABLE `by_svc`AS
                        SELECT COUNT(*) AS 'qty',
                        GROUP_CONCAT(DISTINCT(IP.addr)) AS 'addrs',
                        GROUP_CONCAT(DISTINCT(IP.protocol)) AS 'protocols',
                        GROUP_CONCAT(DISTINCT(IP.portid)) AS 'ports',
                        GROUP_CONCAT(DISTINCT(IP.`state`)) AS 'states',
                        GROUP_CONCAT(DISTINCT(IP.reason)) AS 'reasons',
                        GROUP_CONCAT(DISTINCT(IP.name)) AS 'names',
                        GROUP_CONCAT(DISTINCT(IP.banner)) AS 'banners',
                        SL.name AS 'service',
                        GROUP_CONCAT(DISTINCT(SL.freq)) AS 'freqs',
                        GROUP_CONCAT(DISTINCT(SL.cmt)) AS 'comments'
                        FROM ip_list AS IP INNER JOIN svc_list SL
                        ON IP.portid = SL.port
                        WHERE IP.protocol = SL.proto 
                        GROUP BY service 
                        ORDER BY 1 DESC;
                        """)


    def svcStats(self):
        """GUI for by addrs"""
        self.db.execute("""
                        SELECT qty, service from by_svc;
                        """)
        return self.db.fetchall()


