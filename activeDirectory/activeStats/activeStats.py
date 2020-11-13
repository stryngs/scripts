# -*- coding: utf-8 -*-
"""
Concept:
    Pull down user and node information from Active Directory.
    Take that information and SQL it

Usage:
    csv2sql(domain)
    sqlMod()
"""

import officeTasks as OT
import sqlite3 as lite
import pandas
import time
import warnings
from datetime import datetime, timedelta

def csv2sql(domain):
    warnings.filterwarnings('ignore')
    dm = domain + '_orig'
    con = lite.connect('user-reports.sqlite3')
    df = pandas.read_csv('{0}.csv'.format(domain))
    df.to_sql(dm,
              con,
              if_exists = 'append',
              index = False)
    con.commit()
    con.close()

def sqlMod():
    con = lite.connect('user-reports.sqlite3')
    db = con.cursor()
    
    dList = ['domain-users']

    t = time.localtime()
    today = str(t[0])
    today += '%02d' % int(t[1])
    today += '%02d' % int(t[2])
    curDate = int(today)
    staleDate = curDate - 90
    
    for domain in dList:
    
        q = db.execute('SELECT * FROM "{0}";'.format(domain + '_orig'))
        r = q.fetchall()
        
        ## Prep the new tables - 13
        db.execute('CREATE TABLE "{0}" ("description" INTEGER,\
                                        "cn" TEXT,\
                                        "created_date" INTEGER,\
                                        "email" TEXT,\
                                        "display_name" TEXT,\
                                        "last_logon" INTEGER,\
                                        "stale_acct" INTEGER,\
                                        "locked_out" INTEGER,\
                                        "member_of" TEXT,\
                                        "no_pass_expiration" INTEGER,\
                                        "pass_expired" INTEGER,\
                                        "pass_not_req" INTEGER,\
                                        "pass_last_set" INTEGER,\
                                        "sam_acct_name" TEXT,\
                                        "other_name" TEXT,\
                                        "dn" TEXT);'.format(domain))
        
        con.commit()
        
        ## Iterate through values and convert to yyyymmdd format
        for i in r:
            description = i[0]
            cn = i[1]
            created_date = i[2]
            email = i[3]
            display_name = i[4]
            last_logon = i[5]
            locked_out = i[6]
            member_of = i[7]
            no_pass_expiration = i[8]
            pass_expired = i[9]
            pass_not_req = i[10]
            pass_last_set = i[11]
            sam_acct_name = i[12]
            other_name = i[13]
            dn = i[14]

            if created_date is not None:
                vTemp = i[2].split()[0]
                created_date = vTemp.split('/')[2]
                created_date += '%02d' % int(vTemp.split('/')[0])
                created_date += '%02d' % int(vTemp.split('/')[1])
            else:
                created_date = 0
            
            if last_logon is not None:
                vTemp = last_logon.split()[0]
                last_logon = vTemp.split('/')[2]
                last_logon += '%02d' % int(vTemp.split('/')[0])
                last_logon += '%02d' % int(vTemp.split('/')[1])
            else:
                last_logon = 0
            if int(last_logon) < staleDate:
                stale_acct = 1
            else:
                stale_acct = 0
            
            ## Update the new table - 13
            db.execute('INSERT INTO "{0}"\
                           VALUES(?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?,\
                                  ?);'.format(domain),\
                                         (description,\
                                          cn,\
                                          created_date,\
                                          email,\
                                          display_name,\
                                          last_logon,\
                                          stale_acct,\
                                          locked_out,\
                                          member_of,\
                                          no_pass_expiration,\
                                          pass_expired,\
                                          pass_not_req,\
                                          pass_last_set,\
                                          sam_acct_name,\
                                          other_name,\
                                          dn))
        con.commit()
    
        ## Create no expiry tables
        db.execute('CREATE TABLE\
                        "{0}"\
                    AS SELECT\
                        *\
                    FROM\
                        "{1}"\
                    WHERE\
                        `no_pass_expiration`\
                    =\
                        "1";'.format(domain + '_no_pass_expiration',\
                                    domain))
        con.commit()
    
        ## Create expired tables
        db.execute('CREATE TABLE\
                        "{0}"\
                    AS SELECT\
                        *\
                    FROM\
                        "{1}"\
                    WHERE\
                        `pass_expired`\
                    =\
                        "1";'.format(domain + '_pass_expired',\
                                    domain))
        con.commit()
        
        ## Create null tables
        db.execute('CREATE TABLE\
                        "{0}"\
                    AS SELECT\
                        *\
                    FROM\
                        "{1}"\
                    WHERE\
                        `pass_not_req`\
                    =\
                        "1";'.format(domain + '_pass_not_req',\
                                    domain))
        con.commit()
        
        ## Create stale logon tables
        s = datetime.today() - timedelta(days = 90)
        staleDate = str(s.year)
        staleDate += '%02d' % int(s.month)
        staleDate += '%02d' % int(s.day)
        db.execute('CREATE TABLE\
                        "{0}"\
                    AS SELECT\
                        *\
                    FROM\
                        "{1}"\
                    WHERE\
                        `last_logon` < "{2}";'.format(domain + '_stale_login',\
                                                     domain,\
                                                     staleDate))
        con.commit()
        
        ## Drop original
        db.execute('DROP TABLE "{0}";'.format(domain + '_orig'))
        con.commit()
        print('Complete for table: {0}'.format(domain))
    
    ## Create threat tables
    db.execute('CREATE TABLE "{0}" ("domain" TEXT,\
                                    "total_members" TEXT,\
                                    "no_expiry" TEXT,\
                                    "pass_not_req" TEXT,\
                                    "pass_exp" TEXT,\
                                    "stale_login" TEXT,\
                                    "2x" TEXT,\
                                    "3x" TEXT,\
                                    "4x" TEXT);'.format('threat_matrix'))
    con.commit()
    
    ## Populate threat table
    for domain in dList:
        
        ## Grab total members
        q = db.execute('SELECT COUNT(`cn`) FROM "{0}";'.format(domain))
        memberCount = int(q.fetchall()[0][0])
        
        ## Grab individual #s
        q = db.execute('SELECT COUNT(`cn`) FROM "{0}"'.format(domain + '_no_pass_expiration'))
        no_expiry = int(q.fetchall()[0][0])
        no_expiry = str('{:.2%}'.format(no_expiry / memberCount)) + ' -- ' + str(no_expiry)
        
        q = db.execute('SELECT COUNT(`cn`) FROM "{0}"'.format(domain + '_pass_not_req'))
        pass_not_req = int(q.fetchall()[0][0])
        pass_not_req = str('{:.2%}'.format(pass_not_req / memberCount)) + ' -- ' + str(pass_not_req)
        
        q = db.execute('SELECT COUNT(`cn`) FROM "{0}"'.format(domain + '_pass_expired'))
        pass_exp = int(q.fetchall()[0][0])
        pass_exp = str('{:.2%}'.format(pass_exp / memberCount)) + ' -- ' + str(pass_exp)
        
        q = db.execute('SELECT COUNT(`cn`) FROM "{0}"'.format(domain + '_stale_login'))
        stale_login = int(q.fetchall()[0][0])
        stale_login = str('{:.2%}'.format(stale_login / memberCount)) + ' -- ' + str(stale_login)
        

        
        ## Calculate 2x
        q = db.execute('SELECT COUNT\
                            (`cn`)\
                        FROM\
                            "{0}"\
                        WHERE\
                            (`no_pass_expiration` = "1" AND `pass_expired` = "1")\
                        OR\
                            (`no_pass_expiration` = "1" AND `pass_not_req` = "1")\
                        OR\
                            (`no_pass_expiration` = "1" AND `stale_acct` = "1")\
                        OR\
                            (`pass_expired` = "1" AND `pass_not_req` = "1")\
                        OR\
                            (`pass_expired` = "1" AND `stale_acct` = "1")\
                        OR\
                            (`pass_not_req` = "1" AND `stale_acct` = "1");'.format(domain))
        r = int(q.fetchall()[0][0])
        x2 = str('{:.2%}'.format(r / int(memberCount))) + ' -- ' + str(r)
        
        ## Calculate 3x
        q = db.execute('SELECT COUNT\
                            (`cn`)\
                        FROM\
                            "{0}"\
                        WHERE\
                            (`no_pass_expiration` = "1" AND `pass_expired` = "1" AND `pass_not_req` = "1")\
                        OR\
                            (`no_pass_expiration` = "1" AND `pass_not_req` = "1" AND `stale_acct` = "1")\
                        OR\
                            (`no_pass_expiration` = "1" AND `pass_expired` = "1" AND `stale_acct` = "1")\
                        OR\
                            (`pass_expired` = "1" AND `pass_not_req` = "1" AND `stale_acct` = "1");'.format(domain))
        r = int(q.fetchall()[0][0])
        x3 = str('{:.2%}'.format(r / int(memberCount))) + ' -- ' + str(r)
        
        ## Calculate 4x
        q = db.execute('SELECT COUNT\
                            (`cn`)\
                        FROM\
                            "{0}"\
                        WHERE\
                            `no_pass_expiration` = "1"\
                        AND\
                            `pass_expired` = "1"\
                        AND\
                            `pass_not_req` = "1"\
                        AND\
                            `stale_acct` = "1";'.format(domain))
        r = int(q.fetchall()[0][0])
        x4 = str('{:.2%}'.format(r / int(memberCount))) + ' -- ' + str(r)
        
        ## Populate the matrix
        db.execute('INSERT INTO "{0}"\
                       VALUES(?,\
                              ?,\
                              ?,\
                              ?,\
                              ?,\
                              ?,\
                              ?,\
                              ?,\
                              ?);'.format('threat_matrix'),\
                                     (domain,\
                                      memberCount,\
                                      no_expiry,\
                                      pass_not_req,\
                                      pass_exp,\
                                      stale_login,\
                                      x2,\
                                      x3,\
                                      x4))
        con.commit()
        print('Complete for matrix: {0}'.format(domain))
        
    
    ## Close out
    con.close()


if __name__ =='__main__':
    OT.gnr.sweep('user-reports.sqlite3')
    dmList = ['domain-users']    
    for i in dmList:
        csv2sql(i)
    sqlMod()
    
    ## Bring in full stats
    con = OT.csv.csv2sql('domain-nodes.csv', 'domain-nodes', 'user-reports.sqlite3')
    con.close()
