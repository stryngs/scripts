class Stats(object):
    """Class for generating statistics"""
    def __init__(self, db):
        self.db = db


    def by_addr(self):
        """Look at the data by IP address"""
        self.db.execute("""
                        CREATE TABLE `by_addr`AS
                        SELECT COUNT(*) AS 'qty',
                        IP.addr AS 'addrs',
                        GROUP_CONCAT(DISTINCT(IP.protocol)) AS 'protocol',
                        GROUP_CONCAT(DISTINCT(IP.portid)) AS 'port',
                        GROUP_CONCAT(DISTINCT(IP.`state`)) AS 'state',
                        GROUP_CONCAT(DISTINCT(IP.reason)) AS 'reason',
                        GROUP_CONCAT(DISTINCT(IP.name)) AS 'name',
                        GROUP_CONCAT(DISTINCT(IP.banner)) AS 'banner',
                        GROUP_CONCAT(DISTINCT(SL.name)) AS 'service',
                        GROUP_CONCAT(DISTINCT(SL.freq)) AS 'freq',
                        GROUP_CONCAT(DISTINCT(SL.cmt)) AS 'comment'
                        FROM ip_list IP INNER JOIN svc_list SL 
                        ON IP.portid = SL.port 
                        WHERE IP.protocol = SL.proto 
                        GROUP BY addr 
                        ORDER BY 1 DESC;
                        """)


    def by_port(self):
        """Look at the data by port #"""
        self.db.execute("""
                        CREATE TABLE `by_port`AS
                        SELECT COUNT(*) AS 'qty',
                        GROUP_CONCAT(DISTINCT(IP.addr)) AS 'addrs',
                        GROUP_CONCAT(DISTINCT(IP.protocol)) AS 'protocol',
                        IP.portid AS 'port',
                        GROUP_CONCAT(DISTINCT(IP.`state`)) AS 'state',
                        GROUP_CONCAT(DISTINCT(IP.reason)) AS 'reason',
                        GROUP_CONCAT(DISTINCT(IP.name)) AS 'name',
                        GROUP_CONCAT(DISTINCT(IP.banner)) AS 'banner',
                        GROUP_CONCAT(DISTINCT(SL.name)) AS 'service',
                        GROUP_CONCAT(DISTINCT(SL.freq)) AS 'freq',
                        GROUP_CONCAT(DISTINCT(SL.cmt)) AS 'comment'
                        FROM ip_list IP INNER JOIN svc_list SL 
                        ON IP.portid = SL.port 
                        WHERE IP.protocol = SL.proto 
                        GROUP BY port 
                        ORDER BY 1 DESC;
                            """)


    def by_svc(self):
        """Look at the data by service name as derived from your services file"""
        self.db.execute("""
                        CREATE TABLE `by_svc`AS
                        SELECT COUNT(*) AS 'qty',
                        GROUP_CONCAT(DISTINCT(IP.addr)) AS 'addrs',
                        GROUP_CONCAT(DISTINCT(IP.protocol)) AS 'protocol',
                        GROUP_CONCAT(DISTINCT(IP.portid)) AS 'port',
                        GROUP_CONCAT(DISTINCT(IP.`state`)) AS 'state',
                        GROUP_CONCAT(DISTINCT(IP.reason)) AS 'reason',
                        GROUP_CONCAT(DISTINCT(IP.name)) AS 'name',
                        GROUP_CONCAT(DISTINCT(IP.banner)) AS 'banner',
                        SL.name AS 'service',
                        GROUP_CONCAT(DISTINCT(SL.freq)) AS 'freq',
                        GROUP_CONCAT(DISTINCT(SL.cmt)) AS 'comment'
                        FROM ip_list AS IP INNER JOIN svc_list SL
                        ON IP.portid = SL.port
                        WHERE IP.protocol = SL.proto 
                        GROUP BY service 
                        ORDER BY 1 DESC;
                            """)
