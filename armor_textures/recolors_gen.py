import os, sys
from PIL import Image
from PIL import ImageColor

C = ImageColor.getrgb

BASECOLORS = [C('#404040'), C('#606060'), C('#808080'), C('#A0A0A0'), C('#C0C0C0')]

def FindBaseColorIndex(color):
    for i in range(len(BASECOLORS)):
        bc = BASECOLORS[i]
        if bc[0] == color[0] and bc[1] == color[1] and bc[2] == color[2]:
            return i
    return None

RECOLORS = {
    'tcop': [C('#763228'), C('#bd3c2e'), C('#bd3e2f'), C('#e85643'), C('#ff8575')],
    'tste': [C('#5a0410'), C('#98323d'), C('#b66d71'), C('#e67581'), C('#ffcbcf')],
    'ttin': [C('#675248'), C('#8a7164'), C('#9f8577'), C('#b49a8f'), C('#c3aea3')],
    'tcha': [C('#33441e'), C('#466427'), C('#5b8b38'), C('#5fac3f'), C('#75d865')],
    'tgol': [C('#a71d06'), C('#ed5e0b'), C('#ff9d15'), C('#ffba15'), C('#ffebad')],
    'cgls': [C('#0e1215'), C('#114f51'), C('#647680'), C('#90adbb'), C('#f8f4f5')]
}

BLANK = C('#0000')

SOURCES = {
    'terumet_armboots_base.png': None, 
    'terumet_armchest_base.png': None,
    'terumet_armlegs_base.png': None, 
    'terumet_armhelm_base.png': None,
    'terumet_inv_base.png': None,
    'terumet_prvboots_base.png': None,
    'terumet_prvchest_base.png': None,
    'terumet_prvlegs_base.png': None,
    'terumet_prvhelm_base.png': None
}

DEST = 'recolors/'

INVLIST = ['helm', 'chest', 'legs', 'boots']

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
    
    invpath = DEST + 'terumet_inv_base.png'.replace("base", suffix)
    invimage = Image.open(invpath)
    x = 0
    for inv in INVLIST:
        invitem = invimage.crop((x,0,x+16,16))
        invitem.save(invpath.replace("inv", "inv"+inv))
        x += 16
    invimage.close()
    os.remove(invpath)