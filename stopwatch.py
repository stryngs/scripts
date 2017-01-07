import time

class Stopwatch(object):
    """A stopwatch class for tracking time deltas.

    When this class is instantiated, the default is to create a list for
    tracking of time via a "button press".  To allow for multiple things to be
    concurrently tracked within the same object, a dictionary object is used.  
    The thought behind the dictionary is to allow for a single instance of the
    Stopwatch class, using a keyword, to track button presses based upon
    that specific keyword.  This alleviates the need for multiple instances to 
    be generated for the Stopwatch class.  This feature allows for the
    stopwatch to be created once, and then modified as needed, on-the-fly.
    
    It is important to note that clickMonitor and timeKeeper operate using
    different counting indexes.  While the first button press for a given 
    object will always be a 1, the corresponding time at which the button press
    was mapped is n-1.  In other words, if clickMonitor shows 10 clicks, then
    the highest index in timeKeeper would be 9.
    
    Pieces of the Stopwatch are created during instantiation as follows:
        - A timeKeeper object (This keeps track of time)
            - list (default)
                -OR-
            - dictionary
        - a clickMonitor object (Keeps track of individual button presses)
        
    Methods of the Stopwatch class:
        - button
            Serves as an all-in-one "button" for the user to press. It does not
            recognize the concept of start and stop, it serves merely to notate
            the point in time, at which a user "pressed" it.  When the button
            is pressed, 1 is added to the current clickMonitor object.
            Pressing of the button is accomplished as such:
                - button()
                    -OR-
                - button(<desired keyword to track with>)

        - delta
            Serves as a rudimentary subtraction tool using a start and end
            concept.  To obtain a delta, simply do:
                - delta(startTime, endTime) (List style)
                    -OR-
                - delta(<desired keyword> ,startTime, endTime) (Dictionary)

        - reset
            Allows the user to hit the "reset" button. Will work for list or
            dictionary format.  Useful in that re-instantiation is not needed.
            Uses a try/pass concept so that resetting can be done without
            prior existence.
            Concept:
                - reset()
                    -OR-
                - reset(<desired keyword to track with>)

    Examples of usage:
        - list (Useful for tracking only a single "thing")
            import random, stopwatch
            listWatch = Stopwatch()
            print('Initial button')
            listWatch.button()
            time.sleep(random.randint(1,10))
            print('Second button')
            listWatch.button()
            print('The delta is: {0}'.format(listWatch.delta(0, 1)))
                
        - dictionary (Useful for tracking multiple "things")
            import random, stopwatch
            dictWatch = stopwatch.Stopwatch(option = 'multi')
            print('Initial button')
            dictWatch.button('foo')
            time.sleep(random.randint(1, 10))
            print('Second button')
            dictWatch.button('foo')
            print('The delta for foo is: {0}'.format(dictWatch.delta('foo', 0, 1)))
            dictWatch.button('bar')
            dictWatch.button('bar')
            dictWatch.button('bar')
            print(dictWatch.timeKeeper)
    """
    
    def  __init__(self, **kwargs):
        """Generate the body of the watch"""
        if not 'option' in kwargs:
            self.timeKeeper = []
            self.clickMonitor = 0
        else:
            if kwargs['option'] == 'multi':
                self.timeKeeper = {}
                self.clickMonitor = {}
                #self.dictInstance = {}
            else:
                self.timeKeeper = []
                self.clickMonitor = 0


    def button(self, *args):
        """Button press method"""
        buttonPress = time.time()
        
        if type(self.timeKeeper) is list:
            self.timeKeeper.append(buttonPress)
            self.clickMonitor += 1
        else:
            
            ## Deal with first instance of dict being clicked
            if not args[0] in self.clickMonitor.keys():
                self.timeKeeper.update({args[0]: {0: buttonPress}})
                self.clickMonitor.update({args[0]: 1})
            
            ## Add a click for dict already in use
            else:
                self.clickMonitor.update({args[0]: self.clickMonitor[args[0]] + 1})
                self.timeKeeper[args[0]].update({self.clickMonitor[args[0]] - 1: buttonPress})
        

    def delta(self, *args):
        """Simple method for performing time-based subtraction"""
        if type(self.timeKeeper) is list:
            startSlot = args[0]
            endSlot = args[1]
            return self.timeKeeper[endSlot] - self.timeKeeper[startSlot]
        else:
            title = args[0]
            startSlot = args[1]
            endSlot = args[2]
            return self.timeKeeper[title][endSlot] - self.timeKeeper[title][startSlot]


    def reset(self, *args):
        """Method to allow for reset of the watch, without reinstantiation"""
        if type(self.timeKeeper) is list:
            try:
                self.timeKeeper = []
                self.clickMonitor = 0
            except:
                pass
        else:
            try:
                del self.timeKeeper[args[0]]
                del self.clickMonitor[args[0]]
            except:
                pass
