import sys, os, argparse, json
from datetime import datetime

parser = argparse.ArgumentParser(description = 'Convert Tilekit map exports to Game Boy format')
parser.add_argument('infile', metavar = '[input]', type = argparse.FileType('r'), help = 'Input file name')
argv = parser.parse_args()
infile=argv.infile


################################################################

# WLE encoding library by Pigu/AYCE
    
# 000x xxxx   - literal short
# 001x xxxx X - literal long
# 010x xxxx   - fill mem
# 011x xxxx Y - fill Y
# 100x xxxx   - longest_inc mem
# 101x xxxx Y - longest_inc Y
# 11xx xxxx Y - copy Y for X
# 1111 1111   - end

def writelit(buf, start, end):
    out = bytearray()
    while start < end:
        l = min(end - start, 8192) - 1
        if l > 31:
            out += bytearray([0x20 + (l >> 8), l & 255]) + buf[start : start + l + 1]
        else:
            out += bytearray([l]) + buf[start : start + l + 1]
        start += 8192
    return out

def encodeWLE(buf):
    out = bytearray()
    hold = 0
    lit = 0
    pos = 0
    while pos < len(buf):
        pos2 = pos
        while pos2 < min(len(buf), pos + 32) and buf[pos2] == buf[pos]:
            pos2 += 1
        longest_fill = pos2 - pos
        pos2 = pos
        curinc = buf[pos]
        while pos2 < min(len(buf), pos + 32) and buf[pos2] == curinc:
            curinc += 1
            pos2 += 1
        longest_inc = pos2 - pos
        if buf[pos] == hold:
            longest_fill += 1
            longest_inc += 1
        copies = []
        for j in range(max(pos - 256, 0), pos):
            if buf[j] == buf[pos]:
                copies.append((j, 1))
        longest_copy = (-1, -1)
        while len(copies) > 0:
            longest_copy = copies.pop(0)
            cmdlen = longest_copy[1]
            if (
                pos + cmdlen < len(buf)
                and buf[longest_copy[0] + cmdlen] == buf[pos + cmdlen]
            ):
                copies.append((longest_copy[0], cmdlen + 1))
        if longest_copy[1] > 63:
            longest_copy = (longest_copy[0], 63)
        cmd = max((longest_copy[1], 1), (longest_inc, 2), (longest_fill, 3))
        if cmd[0] > 2:
            if lit > 0:
                out += writelit(buf, pos - lit, pos)
            lit = 0
            cmdlen = cmd[0]
            if cmd[1] == 1:
                out += bytearray([0xC0 + cmdlen - 1, pos - longest_copy[0] - 1])
            elif cmd[1] == 2:
                if buf[pos] == hold:
                    cmdlen -= 1
                    out += bytearray([0x80 + cmdlen - 1])
                else:
                    out += bytearray([0xA0 + cmdlen - 1, buf[pos]])
                hold = buf[pos] + cmdlen
            else:
                if buf[pos] == hold:
                    cmdlen -= 1
                    out += bytearray([0x40 + cmdlen - 1])
                else:
                    out += bytearray([0x60 + cmdlen - 1, buf[pos]])
                hold = buf[pos]
            pos += cmdlen
        else:  # literal
            lit += 1
            pos += 1
    if lit > 0:
        out += writelit(buf, pos - lit, pos)
    out += b"\xff"  # end
    return out

################################################################

if __name__ == "__main__":
    # validate map data
    # parse JSON tags
    inname = os.path.splitext(infile.name)[0]
    mapdata = json.loads(infile.read())
    if(mapdata['width'] != 16):
        print("Error: Map width must be 16!")
        infile.close()
        exit(1)
    
    # check for Tiled Map Editor export
    try:
        tv=mapdata['tiledversion']
        print("Converting " + inname + " (Tiled Map Editor format)...")
        map = mapdata['layers'][0]['data']
        obj = mapdata['layers'][1]['objects']
    # if the above fails, we have a Tilekit export
    except KeyError:
        print("ERROR: TileKit format maps are no longer supported")
        exit(1)
    
    # open files
    mapfile1 = open(inname + "-01.bin", "wb")
    hdrfile = open(inname + ".inc", "w")
            
    objlist = []
    objcount = 0
        
    # initialize level properties
    for x in range(0, len(obj)):
        if obj[x]['name'] == "LevelProperties":
            r = 0
            for q in range(0,len(obj[x]['properties'])):
                if obj[x]['properties'][q]['name'] == "Tileset":
                    tileset = obj[x]['properties'][q]['value']
                    r += 1
                elif obj[x]['properties'][q]['name'] == "Music":
                    music = obj[x]['properties'][q]['value']
                    r += 1
                elif obj[x]['properties'][q]['name'] == "Palette":
                    palette = obj[x]['properties'][q]['value']
                    r += 1
                elif obj[x]['properties'][q]['name'] == "Objset":
                    objset = obj[x]['properties'][q]['value']
                    r += 1
                elif obj[x]['properties'][q]['name'] == "EnemyCount":
                    enemycount = obj[x]['properties'][q]['value']
                    r += 1
            print(r)
            if r != 5:
                print("ERROR: Some level properties weren't set! (Ensure LevelProperties object has the Tileset, Music, Palette, and Objset tags set)")
                exit(1)
        elif obj[x]['name'] == "PlayerStart":
            try:
                px = (int(obj[x]['x']) + 16) // 16
                py = (int(obj[x]['y']) + 16) // 16
                ps = int(obj[x]['x']) // 256
                pa = int(obj[x]['y']) // 256
            except KeyError:
                print("Error: PlayerStart object doesn't exist!")
                exit(1)
        else:
            try:
                a1 = obj[x]['name']
                a2 = ((int(obj[x]['x'])+8) // 256)
                a3 = (int(obj[x]['x'])+8) % 256
                a4 = (int(obj[x]['y'])+8) % 256
                objlist.append([a1, a2, a3, a4])
            except KeyError:
                print("Error: Object " + obj[x]['name'] + " is missing tags! (Enusre id, x, and y tags are present)")
                exit(1)
                
    # write map header
    now=datetime.now()
    hdrfile.write("; This file was generated by convertmap.py on " + now.strftime("%m/%d/%Y %H:%M:%S") + "\n; DO NOT EDIT!!!\n\n")
    hdrfile.write("section \"Map_" + inname + "\",romx\n\nMap_" + inname + "::\n")
    hdrfile.write(".width      db       " + str((mapdata['width'] // 16) - 1) + "\n")
    hdrfile.write(".startxy    db       " + str((px << 4) | (py + 16)) + "\n")
    hdrfile.write(".music      db       bank(" + music + ")-1\n")
    hdrfile.write(".tileset    dwbank   " + tileset + "\n")
    hdrfile.write(".palette    dwbank   " + palette + "\n")
    hdrfile.write(".objset     db       " + objset + "\n")
    hdrfile.write(".enemycount db       " + enemycount + "\n")
    hdrfile.write(".sub1       dw       .data1\n")
    hdrfile.write(".objptr     dwbank   .objdata\n")
    
    hdrfile.write(".data1      incbin   \"Levels/" + inname + "-01.bin.wle\"\n")
    
    hdrfile.write(".objdata    include  \"Levels/ObjectLayouts/" + inname + "_Objects.inc\"\n")
    hdrfile.close()
    
    # write object data
    
    # determine which directory delimiter to use    
    if os.name == ("nt"): # Windows
        objfile = open(".\\ObjectLayouts\\" + inname + "_Objects.inc","w")
    else: # All other OSes
        objfile = open("./ObjectLayouts/" + inname + "_Objects.inc","w")
    
    objfile.write("; This file was generated by convertmap.py on " + now.strftime("%m/%d/%Y %H:%M:%S") + "\n; DO NOT EDIT!!!\n\n" + inname + "_Objects:\n    ")
    for x in range(0,len(objlist)):
        objfile.write("db      OBJID_" + str(objlist[x][0]) + ", " + str(objlist[x][1]) + ", " + str(objlist[x][2]) + ", " + str(objlist[x][3]) + "\n    ")
    objfile.write("db      -1 ; end of list\n")
    objfile.close()
    
    mw = mapdata['width']
    md = map
    
    # write actual map data
    #if sa > 0:
    for y in range(0, mw):
        for c in range(0, 16):
            try:
                mapfile1.write(bytes([(md[c * (mw) + y] - 1)]))
            except ValueError:
                mapfile1.write(bytes([0]))
    
    mapfile1.close()
    infile.close()
        
    # compress file
    infile = open(inname + "-01.bin", "rb")
    outfile = open(inname + "-01.bin.wle", "wb")
    outfile.write(encodeWLE(infile.read()))
    infile.close()
    outfile.close()
            