#This code is mostly rushed and hackjob'd together but it works for what its needed for

from os import listdir
from os.path import isfile, join
print("DIRECTORY OF CODEBASE (e.g. C:/BlackMesa13/ )")
repodir = raw_input("DIR: ")
print("SUBDIRECTORY OF VOX-PHRASES WITHIN CODEBASE (e.g. sound/vox/ )")
#mypath = "C:/GitStuff/BM13/BlackMesa13/sound/vox"
subdir = raw_input("SUBDIR: ")
print("FILENAME TO SAVE LIST IN (e.g. voxlist )")
fn = raw_input("FILENAME: ")
words = [f for f in listdir(repodir + subdir) if isfile(join(repodir + subdir, f))]
lines = 0
f = open(repodir + fn + '.txt','w')
for filename in words:
    word = filename[:-4]
    print("DEFINED '" + word + "'")
    f.write("\"" + word + "\" = '" + subdir + filename + "',\n") 
    lines += 1
f.close() 
print("GENERATED " + str(lines) + " LINES")
print("SAVED TO " + repodir + fn + ".txt")

