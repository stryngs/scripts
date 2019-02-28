class Database(object):
    """Handles any database preparation, pre-processing"""

    def __init__(self, db):
        self.db = db


    def scan_prep(self):
        """Prep the scan table"""
        self.db.execute('CREATE TABLE IF NOT EXISTS\
                            `ip_list`("endtime" INT,\
                                    "addr" TEXT,\
                                    "addrtype" TEXT,\
                                    "protocol" TEXT,\
                                    "portid" INT,\
                                    "state" TEXT,\
                                    "reason" TEXT,\
                                    "reason_ttl" INT,\
                                    "name" TEXT,\
                                    "banner" TEXT,\
                                    UNIQUE("endtime",\
                                            "addr",\
                                            "addrtype",\
                                            "protocol",\
                                            "portid",\
                                            "state",\
                                            "reason",\
                                            "reason_ttl",\
                                            "name",\
                                            "banner"));')


    def svc_prep(self):
        """Prep the services table"""
        self.db.execute('CREATE TABLE IF NOT EXISTS\
                            `svc_list`("name" TEXT,\
                                    "port" INT,\
                                    "proto" TEXT,\
                                    "freq" TEXT,\
                                    "cmt" TEXT);')
