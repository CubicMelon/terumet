import os, sys
from PIL import Image, ImageColor, ImageChops

C = ImageColor.getrgb

BASECOLORS = [C('#202020'), C('#404040'), C('#606060'), C('#808080'), C('#A0A0A0')]

def FindBaseColorIndex(color):
    for i in range(len(BASECOLORS)):
        bc = BASECOLORS[i]
        if bc[0] == color[0] and bc[1] == color[1] and bc[2] == color[2]:
            return i
    return None

RECOLORS = {
    'tcop': [C('#763228'), C('#bd3c2e'), C('#d44734'), C('#e85643'), C('#ff8575')],
    'tste': [C('#5a0410'), C('#98323d'), C('#b66d71'), C('#e67581'), C('#ffcbcf')],
    'ttin': [C('#675248'), C('#8a7164'), C('#9f8577'), C('#b49a8f'), C('#c3aea3')],
    'tcha': [C('#33441e'), C('#466427'), C('#5b8b38'), C('#5fac3f'), C('#75d865')],
    'tgol': [C('#a71d06'), C('#ed5e0b'), C('#ff9d15'), C('#ffba15'), C('#ffebad')],
    'cgls': [C('#0e1215'), C('#114f51'), C('#647680'), C('#90adbb'), C('#f8f4f5')]
}

BLANK = C('#0000')

SOURCES = {
    'terumet_doorfull_base.png': None, 
    'terumet_doormesh_base.png': None,
    'terumet_doorslat_base.png': None,
    'terumet_doorvert_base.png': None,
    'terumet_dinv_base.png': None
}

DEST = 'recolors/'

INVLIST = ['full', 'mesh', 'slat', 'vert']

for sourceFile in SOURCES:
    src = Image.open(sourceFile)
    src = src.convert("RGBA")
    SOURCES[sourceFile] = { 'pixels':src.load(), 'size':src.size }
    src.close()

for suffix, recolors in RECOLORS.iteritems():
    for sourceFile, src in SOURCES.iteritems():
        srcW = src['size'][0]
        srcH = src['size'][1]
        outimage = Image.new("RGBA", (srcW, srcH), BLANK)
        outPixels = outimage.load()
        for y in xrange(srcH):
            for x in xrange(srcW):
                srcPixel = src['pixels'][x, y]
                if srcPixel[3] == 255: # ignore any transparent pixels
                    baseColorIndex = FindBaseColorIndex(srcPixel)
                    outPixel = srcPixel
                    if baseColorIndex != None:
                        outPixel = recolors[baseColorIndex]
                    outPixels[x, y] = outPixel
        outpath = DEST + sourceFile.replace("base", suffix)
        outimage.save(outpath)
    
    invpath = DEST + 'terumet_dinv_base.png'.replace("base", suffix)
    invimage = Image.open(invpath)
    x = 0
    for inv in INVLIST:
        invitem = invimage.crop((x,0,x+16,16))
        invitem.save(invpath.replace("dinv", "dinv"+inv))
        x += 16
    invimage.close()
    os.remove(invpath)
