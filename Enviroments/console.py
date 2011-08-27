#The default python console "python" doesn't play very nice in my setupT
#It refuses to flush it's output buffers for me even if I force the issue. 
#It does it for bash since I can actually read the output, why not for me? 
#Anyway, this very thin wrapper around  InteractiveConsole flushes 
#things nicely and I don't have to parse out the nasty prompt
#so it's a win-win I guess.

import code
import sys
from code import InteractiveConsole

sh = InteractiveConsole()
print "$>",
sys.stdout.flush()
sys.stderr.flush()
while True:
    line = sys.stdin.readline()
    if not sh.push(line):
        print "$>",
    sys.stdout.flush()
    sys.stderr.flush()

