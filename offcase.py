v=input("> ").lower()
import os
finalstring=""
# goal: make offcase (e.g.) hElLo WoRlD
for i in range(len(v)):
    if i%2==0:
        finalstring+=v[i].lower()
    else:
        finalstring+=v[i].upper()
print(finalstring)
q=input("Add as splash? (y/n) ")
if q.lower()!="y":
    exit()
cmd=f"splash --add-splash \"{finalstring}\""
os.system(cmd)
