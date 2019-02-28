import re

class List(object):
    """Handle any port list you want to throw at it"""
    
    def __init__(self, cn = 'default'):
        self.tList = []
        self.sList = []
        if cn == 'default':
            self.lType = 'nmap'
        else:
            self.lType = None


    def list_pick(self):
        if self.lType == 'nmap':

            with open('lists/nmap-services', 'r') as iFile:
                lst = iFile.read().splitlines()
            
            for l in lst:
                if not re.search('^#', l):
                    self.tList.append(l)

            count = 1
            for s in self.tList:
                count += 1
                sName = s.split('\t')[0]
                sPort = s.split('\t')[1].split('/')[0]
                sProto = s.split('\t')[1].split('/')[1]
                sFreq = s.split('\t')[2]
                try:
                    sCmt = s.split('\t')[3]
                except:
                    sCmt = ''
                self.sList.append((sName, sPort, sProto, sFreq, sCmt))
